import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:meta/meta.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

import '../../bootstrap/app_paths.dart';

/// The logic layer for passphrase encryption: generating/wrapping the master
/// key, unlocking via either path, and changing either secret independently.
/// UI screens call this, never Tasks 1-4's lower-level pieces directly.
class EncryptionService {
  EncryptionService({required this.paths});
  final AppPaths paths;

  final _random = Random.secure();

  /// Test-only hook: fires inside [migrateToEncrypted] after the encrypted
  /// file has been renamed over the live one and BEFORE the staged envelope is
  /// promoted -- the one window where a crash leaves the database ciphertext
  /// while the firm still reads as unencrypted. Throwing from it simulates the
  /// process dying exactly there. No-op in production.
  @visibleForTesting
  Future<void> Function()? afterDatabaseSwapHook;

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
  }) async => onRecoveryCodeGenerated(
    await _writeEnvelopeTo(
      _storeFor(firmId),
      masterKey: masterKey,
      passphrase: passphrase,
    ),
  );

  /// Wraps [masterKey] under both secrets and writes the envelope to [store],
  /// returning the recovery code generated for it. Takes the store rather than
  /// a firm id because [migrateToEncrypted] writes its envelope to a staging
  /// path first -- see there for why that matters.
  Future<String> _writeEnvelopeTo(
    KeyEnvelopeStore store, {
    required Uint8List masterKey,
    required String passphrase,
  }) async {
    final recoveryCode = encodeRecoveryCode(_randomBytes(32));
    final passphraseSalt = _randomBytes(16);
    final recoveryCodeSalt = _randomBytes(16);
    await store.write(
      KeyEnvelope(
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
      ),
    );
    return recoveryCode;
  }

  /// Turns an existing PLAINTEXT firm database into an encrypted one, in
  /// place, with real customer and transaction rows already in it.
  ///
  /// The caller MUST have closed the live connection first: SQLite cannot
  /// have the file open elsewhere while `sqlcipher_export` rewrites it --
  /// the same precondition `BackupService.restoreFrom` documents, for the
  /// same reason.
  ///
  /// The ordering below is the substance of this method, not decoration.
  ///
  /// 1. The encrypted copy is written to a scratch file and proved good
  ///    against the still-untouched original -- cipher integrity, SQL
  ///    integrity, schema, drift's schema version, and a row count per table.
  /// 2. The plaintext original is kept beside it as a `.pre-encryption`
  ///    sidecar.
  /// 3. The envelope is written to a STAGING path, not its real one.
  /// 4. The encrypted file is renamed over the live database.
  /// 5. Only then is the staged envelope promoted to its real path.
  ///
  /// Steps 3-5 are in that order because [isEncrypted] -- the only thing that
  /// ever distinguishes an encrypted firm from a plaintext one -- is just
  /// "does the envelope file exist". Promote the envelope before the swap and
  /// a crash in between leaves a firm that reports itself encrypted while its
  /// database is still plaintext; nothing in this app keys a connection unless
  /// a session key is already in memory, so that firm would keep opening,
  /// reading and WRITING real ledger data in plaintext while every screen
  /// called it protected. In the order above the same crash leaves the
  /// envelope unpromoted, so the firm reads as unencrypted and an unkeyed open
  /// of the now-ciphertext file fails loudly -- and
  /// [recoverInterruptedMigration] repairs it from the staged envelope.
  ///
  /// [onRecoveryCodeGenerated] fires last of all, once the live encrypted file
  /// has been read back and the plaintext sidecar retired, so that a caller
  /// whose callback throws cannot leave a plaintext copy of the ledger on
  /// disk. If this method throws after the swap, the firm is encrypted and
  /// unlockable by the passphrase it was given even though no recovery code
  /// was issued -- `rotateRecoveryCode` mints a fresh one after unlocking.
  Future<void> migrateToEncrypted(
    String firmId, {
    required String passphrase,
    required void Function(String recoveryCode) onRecoveryCodeGenerated,
  }) async {
    // A previous attempt may have died between the swap and the promotion.
    // Settle that first, so a retry heals rather than tripping the guards.
    await recoverInterruptedMigration(firmId);

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
    // replace; it is the fallback for every step from here on, and is retired
    // at the end of this method once the live encrypted file has been read
    // back successfully.
    final keptPlaintext = File('${liveFile.path}.pre-encryption');
    await liveFile.copy(keptPlaintext.path);

    final pendingEnvelope = _pendingEnvelopeFile(firmId);
    final recoveryCode = await _writeEnvelopeTo(
      KeyEnvelopeStore(pendingEnvelope),
      masterKey: masterKey,
      passphrase: passphrase,
    );

    await tmpEncrypted.rename(liveFile.path);
    // Any rollback journal beside the live path belongs to the plaintext
    // database that was just replaced, and that database is preserved in the
    // sidecar. Leaving one next to a ciphertext file is both a corruption risk
    // and a plaintext leak.
    _deleteJournalSidecars(liveFile);
    await afterDatabaseSwapHook?.call();
    await pendingEnvelope.rename(paths.firmKeyEnvelope(firmId).path);

    // Read the file that is now live -- not the scratch file that was verified
    // before the rename -- back through the key, against the plaintext copy.
    // Only a clean read retires the last plaintext copy of the ledger; leaving
    // one on disk would undo the point of encrypting at all.
    _verifyEncryptedCopy(
      plaintext: keptPlaintext,
      encrypted: liveFile,
      keyHex: keyHex,
    );
    keptPlaintext.deleteSync();

    // Last, so that a caller whose callback throws cannot strand the plaintext
    // sidecar that the two lines above exist to remove.
    onRecoveryCodeGenerated(recoveryCode);
  }

  /// Repairs a [migrateToEncrypted] that died between the database swap and
  /// the envelope promotion -- the only window that leaves the two disagreeing.
  ///
  /// It cannot read the database to decide (the key is inside the very
  /// envelope in question), so it reads the file header instead: SQLCipher
  /// encrypts page 1 whole, including SQLite's magic string, so finding that
  /// string is a reliable "this file is still plaintext".
  ///
  /// [migrateToEncrypted] calls this itself before doing anything. Task 7's
  /// open/unlock flow should call it at firm-open time too, as defence in
  /// depth -- a firm that crashed mid-migration and is never migrated again
  /// would otherwise stay stranded.
  Future<void> recoverInterruptedMigration(String firmId) async {
    final pendingEnvelope = _pendingEnvelopeFile(firmId);
    final liveFile = paths.firmDatabase(firmId);
    if (pendingEnvelope.existsSync()) {
      final envelope = paths.firmKeyEnvelope(firmId);
      if (!envelope.existsSync() &&
          liveFile.existsSync() &&
          !_isPlaintextSqlite(liveFile)) {
        // The swap happened: this staged envelope holds the only wrapped copy
        // of the key for the file now on disk. Finish what was interrupted.
        await pendingEnvelope.rename(envelope.path);
      } else {
        // The swap never happened (or a real envelope is already in place), so
        // the staged key wraps a database that is not there. Drop it and leave
        // the firm as the plaintext, unencrypted firm it still is.
        pendingEnvelope.deleteSync();
      }
    }
    for (final leftover in [
      File('${pendingEnvelope.path}.tmp'),
      File('${liveFile.path}.encrypting.tmp'),
    ]) {
      if (leftover.existsSync()) leftover.deleteSync();
    }
  }

  File _pendingEnvelopeFile(String firmId) =>
      File('${paths.firmKeyEnvelope(firmId).path}.pending');

  /// Reads only the 16-byte header, never the whole (potentially large) file.
  static bool _isPlaintextSqlite(File file) {
    final handle = file.openSync();
    try {
      final header = handle.readSync(16);
      return header.length == 16 &&
          String.fromCharCodes(header.sublist(0, 15)) == 'SQLite format 3' &&
          header[15] == 0;
    } finally {
      handle.closeSync();
    }
  }

  static void _deleteJournalSidecars(File databaseFile) {
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final sidecar = File('${databaseFile.path}$suffix');
      if (sidecar.existsSync()) sidecar.deleteSync();
    }
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
      // The swap at the end of migrateToEncrypted is a file rename, which
      // moves only the database file. In WAL mode the old plaintext database's
      // -wal/-shm would be left sitting beside the new ciphertext one: a
      // corruption risk and a plaintext leak at once. Nothing in this app sets
      // journal_mode today, so this only ever fires if that changes -- and
      // then it fires before anything has been written.
      final journalMode = source
          .select('PRAGMA main.journal_mode')
          .first
          .values
          .first
          .toString()
          .toLowerCase();
      if (journalMode != 'delete') {
        throw StateError(
          'Refusing to encrypt a database in "$journalMode" journal mode: '
          'the rename-based swap only carries the main database file.',
        );
      }
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
