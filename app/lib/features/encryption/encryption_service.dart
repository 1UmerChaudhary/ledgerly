import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

import '../../bootstrap/app_paths.dart';

/// The logic layer for passphrase encryption: generating/wrapping the master
/// key, unlocking via either path, and changing either secret independently.
/// UI screens call this, never Tasks 1-4's lower-level pieces directly.
class EncryptionService {
  EncryptionService({required this.paths});
  final AppPaths paths;

  final _random = Random.secure();

  Uint8List _randomBytes(int length) =>
      Uint8List.fromList(List.generate(length, (_) => _random.nextInt(256)));

  KeyEnvelopeStore _storeFor(String firmId) =>
      KeyEnvelopeStore(paths.firmKeyEnvelope(firmId));

  Future<bool> isEncrypted(String firmId) async =>
      await _storeFor(firmId).read() != null;

  Future<void> enableEncryption(
    String firmId, {
    required String passphrase,
    required void Function(String recoveryCode) onRecoveryCodeGenerated,
  }) => enableEncryptionEnvelopeOnly(
    firmId,
    masterKey: _randomBytes(32),
    passphrase: passphrase,
    onRecoveryCodeGenerated: onRecoveryCodeGenerated,
  );

  /// Writes the envelope for an already-chosen [masterKey]. Split out for
  /// [migrateToEncrypted], which cannot let this method pick the key: by the
  /// time the envelope is written the key is already baked into the exported
  /// database file.
  Future<void> enableEncryptionEnvelopeOnly(
    String firmId, {
    required Uint8List masterKey,
    required String passphrase,
    required void Function(String recoveryCode) onRecoveryCodeGenerated,
  }) async {
    final recoveryCode = encodeRecoveryCode(_randomBytes(32));
    final passphraseSalt = _randomBytes(16);
    final recoveryCodeSalt = _randomBytes(16);
    final envelope = KeyEnvelope(
      byPassphrase: await wrapKey(
        masterKey,
        wrappingKeyBytes: await deriveWrappingKey(
          passphrase,
          salt: passphraseSalt,
        ),
      ),
      passphraseSalt: passphraseSalt,
      byRecoveryCode: await wrapKey(
        masterKey,
        // The printed code itself is the secret for its own KDF -- what the
        // user types back in is all we ever get to re-derive from.
        wrappingKeyBytes: await deriveWrappingKey(
          recoveryCode,
          salt: recoveryCodeSalt,
        ),
      ),
      recoveryCodeSalt: recoveryCodeSalt,
    );
    await _storeFor(firmId).write(envelope);
    onRecoveryCodeGenerated(recoveryCode);
  }

  /// Turns an existing PLAINTEXT firm database into an encrypted one, in
  /// place, with real customer and transaction rows already in it.
  ///
  /// The caller MUST have closed the live connection first: SQLite cannot
  /// have the file open elsewhere while `sqlcipher_export` rewrites it --
  /// the same precondition `BackupService.restoreFrom` documents, for the
  /// same reason.
  ///
  /// The ordering below is the substance of this method, not decoration. The
  /// encrypted copy is written to a scratch file and proved good against the
  /// still-untouched original -- cipher integrity, SQL integrity, schema,
  /// drift's schema version, and a row count per table -- before anything
  /// replaces the original, and the original is then kept as a
  /// `.pre-encryption` sidecar rather than deleted.
  Future<void> migrateToEncrypted(
    String firmId, {
    required String passphrase,
    required void Function(String recoveryCode) onRecoveryCodeGenerated,
  }) async {
    final liveFile = paths.firmDatabase(firmId);
    if (!liveFile.existsSync()) {
      throw StateError('Firm $firmId has no database file to migrate');
    }
    // A firm that already has an envelope already has a ciphertext live file,
    // and the copy below would then overwrite the `.pre-encryption` sidecar --
    // the last plaintext copy -- with that ciphertext. Refuse instead.
    if (await isEncrypted(firmId)) {
      throw StateError('Firm $firmId is already encrypted');
    }

    final tmpEncrypted = File('${liveFile.path}.encrypting.tmp');
    if (tmpEncrypted.existsSync()) tmpEncrypted.deleteSync();

    final masterKey = _randomBytes(32);
    final keyHex = masterKey
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    try {
      _exportEncryptedCopy(from: liveFile, to: tmpEncrypted, keyHex: keyHex);
      _verifyEncryptedCopy(
        plaintext: liveFile,
        encrypted: tmpEncrypted,
        keyHex: keyHex,
      );
    } on Object {
      // Nothing but the scratch file has been touched, so removing it leaves
      // the firm exactly as it was and makes a retry safe.
      if (tmpEncrypted.existsSync()) tmpEncrypted.deleteSync();
      rethrow;
    }

    // Verified. Keep the plaintext original beside the file it is about to
    // replace, write the envelope, then swap. Envelope-before-swap is
    // deliberate: a crash in that gap leaves an envelope over a still-
    // plaintext database, which the sidecar and the untouched live file make
    // repairable. The other order would leave ciphertext with its key wrapped
    // nowhere, which is not.
    await liveFile.copy('${liveFile.path}.pre-encryption');

    String? recoveryCode;
    await enableEncryptionEnvelopeOnly(
      firmId,
      masterKey: masterKey,
      passphrase: passphrase,
      onRecoveryCodeGenerated: (code) => recoveryCode = code,
    );
    try {
      await tmpEncrypted.rename(liveFile.path);
    } on FileSystemException {
      // The envelope is written but the database is still plaintext, so every
      // later open would key a plaintext file and fail on its first read. Put
      // the firm back as it was rather than leave it in that state.
      final envelopeFile = paths.firmKeyEnvelope(firmId);
      if (envelopeFile.existsSync()) envelopeFile.deleteSync();
      rethrow;
    }
    // Only now, with the encrypted file actually in place, is the recovery
    // code worth showing: every path above this line ends with an unencrypted
    // firm and a code that unlocks nothing.
    onRecoveryCodeGenerated(recoveryCode!);
  }

  /// SQLCipher's own documented plaintext-to-encrypted path: attach an empty
  /// encrypted database and export the whole schema and contents into it.
  void _exportEncryptedCopy({
    required File from,
    required File to,
    required String keyHex,
  }) {
    final source = raw.sqlite3.open(from.path);
    try {
      // sqlcipher_export copies the schema, the indexes and every row -- but
      // NOT user_version, which is where drift keeps its schema version. Left
      // at 0 the migrated database looks brand new to drift, which then runs
      // onCreate over an already-full one. SQLCipher's own documentation says
      // to copy it across by hand; this is that.
      final version =
          source.select('PRAGMA main.user_version').first.values.first! as int;
      source.execute(
        "ATTACH DATABASE '${to.path.replaceAll("'", "''")}' "
        'AS enc KEY "x\'$keyHex\'";',
      );
      source.execute("SELECT sqlcipher_export('enc');");
      source.execute('PRAGMA enc.user_version = $version;');
      source.execute('DETACH DATABASE enc;');
    } finally {
      source.close();
    }
  }

  /// Proves the encrypted copy is a faithful, readable copy of the original.
  /// Every check runs against the scratch file while the live plaintext
  /// database is still untouched, so a failure here costs nothing.
  void _verifyEncryptedCopy({
    required File plaintext,
    required File encrypted,
    required String keyHex,
  }) {
    final enc = raw.sqlite3.open(encrypted.path, mode: raw.OpenMode.readOnly);
    try {
      final plain = raw.sqlite3.open(
        plaintext.path,
        mode: raw.OpenMode.readOnly,
      );
      try {
        enc.execute('PRAGMA key = "x\'$keyHex\'";');
        // PRAGMA key accepts any key without complaint; only a real read shows
        // whether it was the right one. Everything below is such a read.
        final cipherErrors = enc.select('PRAGMA cipher_integrity_check');
        if (cipherErrors.isNotEmpty) {
          throw StateError(
            'Encrypted copy failed its cipher integrity check: '
            '${cipherErrors.rows}',
          );
        }
        final quickCheck = enc.select('PRAGMA quick_check').first.values.first;
        if (quickCheck != 'ok') {
          throw StateError('Encrypted copy failed quick_check: $quickCheck');
        }

        final plainVersion = plain
            .select('PRAGMA user_version')
            .first
            .values
            .first;
        final encVersion = enc.select('PRAGMA user_version').first.values.first;
        if (plainVersion != encVersion) {
          throw StateError(
            'Schema version lost in encryption: $plainVersion vs $encVersion',
          );
        }

        final plainSchema = _schemaObjects(plain);
        final encSchema = _schemaObjects(enc);
        if (plainSchema.join('|') != encSchema.join('|')) {
          throw StateError(
            'Schema differs after encryption: $plainSchema vs $encSchema',
          );
        }
        // Every table, not a hand-picked few: the point of this step is to
        // prove nothing was lost, and a table nobody listed is exactly where
        // that would hide.
        for (final table in _userTables(plain)) {
          final plainCount = plain
              .select('SELECT count(*) AS c FROM "$table"')
              .first['c'];
          final encCount = enc
              .select('SELECT count(*) AS c FROM "$table"')
              .first['c'];
          if (plainCount != encCount) {
            throw StateError(
              'Row count mismatch on $table after encryption: '
              '$plainCount vs $encCount',
            );
          }
        }
      } finally {
        plain.close();
      }
    } finally {
      enc.close();
    }
  }

  /// Every schema object the database defines, as `type name` and in a stable
  /// order, so two databases can be compared as one string.
  static List<String> _schemaObjects(raw.Database db) => db
      .select(
        "SELECT type || ' ' || name AS o FROM sqlite_master "
        "WHERE name NOT LIKE 'sqlite_%' ORDER BY o",
      )
      .map((row) => row['o']! as String)
      .toList();

  static List<String> _userTables(raw.Database db) => db
      .select(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .map((row) => row['name']! as String)
      .toList();

  Future<Uint8List?> unlockWithPassphrase(
    String firmId,
    String passphrase,
  ) async {
    final envelope = await _storeFor(firmId).read();
    if (envelope == null) return null;
    final wrappingKey = await deriveWrappingKey(
      passphrase,
      salt: envelope.passphraseSalt,
    );
    try {
      return await unwrapKey(
        envelope.byPassphrase,
        wrappingKeyBytes: wrappingKey,
      );
    } on SecretBoxAuthenticationError catch (_) {
      return null; // wrong passphrase -- fail closed, not an exception the caller must catch
    }
  }

  Future<Uint8List?> unlockWithRecoveryCode(
    String firmId,
    String recoveryCode,
  ) async {
    final envelope = await _storeFor(firmId).read();
    if (envelope == null) return null;
    if (decodeRecoveryCode(recoveryCode) == null) {
      return null; // invalid check symbol
    }
    final wrappingKey = await deriveWrappingKey(
      recoveryCode,
      salt: envelope.recoveryCodeSalt,
    );
    try {
      return await unwrapKey(
        envelope.byRecoveryCode,
        wrappingKeyBytes: wrappingKey,
      );
    } on SecretBoxAuthenticationError catch (_) {
      return null;
    }
  }

  Future<void> changePassphrase(
    String firmId, {
    required Uint8List masterKey,
    required String newPassphrase,
  }) async {
    final store = _storeFor(firmId);
    final existing = await store.read();
    if (existing == null) {
      throw StateError('No envelope exists for firm $firmId');
    }
    final newSalt = _randomBytes(16);
    final newWrappingKey = await deriveWrappingKey(
      newPassphrase,
      salt: newSalt,
    );
    await store.write(
      KeyEnvelope(
        byPassphrase: await wrapKey(
          masterKey,
          wrappingKeyBytes: newWrappingKey,
        ),
        passphraseSalt: newSalt,
        byRecoveryCode: existing.byRecoveryCode,
        recoveryCodeSalt: existing.recoveryCodeSalt,
      ),
    );
  }

  Future<String> rotateRecoveryCode(
    String firmId, {
    required Uint8List masterKey,
  }) async {
    final store = _storeFor(firmId);
    final existing = await store.read();
    if (existing == null) {
      throw StateError('No envelope exists for firm $firmId');
    }
    final newRecoverySecret = _randomBytes(32);
    final newCode = encodeRecoveryCode(newRecoverySecret);
    final newSalt = _randomBytes(16);
    final newWrappingKey = await deriveWrappingKey(newCode, salt: newSalt);
    await store.write(
      KeyEnvelope(
        byPassphrase: existing.byPassphrase,
        passphraseSalt: existing.passphraseSalt,
        byRecoveryCode: await wrapKey(
          masterKey,
          wrappingKeyBytes: newWrappingKey,
        ),
        recoveryCodeSalt: newSalt,
      ),
    );
    return newCode;
  }
}
