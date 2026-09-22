import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:meta/meta.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

import '../../bootstrap/app_paths.dart';

/// What [EncryptionService.recoverInterruptedMigration] found and did, so a
/// caller can tell "nothing needed repairing" apart from "I found a firm I
/// could not safely make a decision about".
enum RecoveryOutcome {
  nothingToRecover,
  revertedToPlaintext,
  promotedToEncrypted,
  indeterminate,
}

/// The live database was PROVED sound, and only the plaintext copy beside it
/// could not be deleted -- a file locked by antivirus, a read-only volume, a
/// full disk. Kept distinct from every other way
/// [EncryptionService.retirePreEncryptionCopy] can fail, all of which mean the
/// database itself did not stand up: this firm is safe to open, and what is
/// left over is a file that should not be there. A caller that treats the two
/// alike bricks a healthy firm for a reason that has nothing to do with it.
class PlaintextCopyNotRetired implements Exception {
  const PlaintextCopyNotRetired(this.path, this.cause);

  /// The plaintext copy still on disk.
  final String path;
  final Object cause;

  @override
  String toString() =>
      'An unprotected copy of this firm is still on disk at $path, because it '
      'could not be deleted: $cause';
}

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
    final keyHex = _hex(masterKey);
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
    await liveFile.copy(_preEncryptionFile(firmId).path);

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

    // Retire the last plaintext copy of the ledger -- but only after reading
    // the file that is now live, not the scratch file verified before the
    // rename, back through the key. Same method the keyless crash-recovery
    // path has to leave for Task 7's unlock flow to call.
    //
    // That method no-ops when there is nothing to retire, which is right for
    // its other caller and wrong here: this method wrote that copy itself, a
    // few lines up. If it has gone, something is badly wrong and must not pass
    // as a successful migration.
    if (!_preEncryptionFile(firmId).existsSync()) {
      throw StateError(
        'The pre-encryption copy for firm $firmId disappeared mid-migration',
      );
    }
    await retirePreEncryptionCopy(firmId, masterKey);

    // Last, so that a caller whose callback throws cannot strand the plaintext
    // sidecar that the two lines above exist to remove.
    onRecoveryCodeGenerated(recoveryCode);
  }

  /// Retires the `.pre-encryption` plaintext safety copy, but only after
  /// proving -- with [masterKey], through a real keyed read -- that the live
  /// encrypted database stands up on its own. A no-op when there is nothing to
  /// retire, so it is safe to call on any firm at any time.
  ///
  /// What it proves is deliberately a property of the live file ALONE, not a
  /// comparison against the `.pre-encryption` snapshot: that the file decrypts
  /// under this key, passes SQLite's own integrity check, holds this firm's
  /// row, and still has every table the snapshot had. Row counts and schema
  /// DDL are pointedly NOT compared. That comparison's job -- proving the
  /// export was a faithful, complete copy -- was already done once, correctly,
  /// by [_verifyEncryptedCopy] between the export and the swap. Repeating it
  /// here would make this method un-callable the moment the firm is used
  /// normally: one new transaction, or a drift migration bumping the schema,
  /// and it would throw forever, stranding the plaintext copy permanently --
  /// which is the very thing it exists to prevent. After the swap,
  /// `.pre-encryption` is an unused safety net, not a reference copy.
  ///
  /// Public because [recoverInterruptedMigration] **cannot** do this. Recovery
  /// is keyless by construction -- the key it is promoting is inside the very
  /// envelope in question -- and a file-header check only ever proves "this
  /// looks like ciphertext", never "this decrypts correctly". Retiring the
  /// last plaintext copy of a firm's ledger on the strength of the weaker
  /// claim is exactly the compromise the rest of this file exists to avoid.
  ///
  /// The consequence is a real, tracked follow-up: a firm whose migration
  /// crashed between the swap and the promotion, and was then auto-recovered,
  /// still has a complete plaintext copy of its ledger on disk. **Task 7's
  /// unlock/open flow MUST call `retirePreEncryptionCopy(firmId, masterKey)`
  /// after a successful unlock**, which is the first moment anything in the
  /// app holds the key needed to finish the job -- and, per the paragraph
  /// above, it stays callable however long after the migration that is.
  Future<void> retirePreEncryptionCopy(
    String firmId,
    Uint8List masterKey,
  ) async {
    final keptPlaintext = _preEncryptionFile(firmId);
    if (!keptPlaintext.existsSync()) return;
    _verifyLiveDatabase(
      firmId,
      keyHex: _hex(masterKey),
      tablesExpectedFrom: keptPlaintext,
    );
    try {
      keptPlaintext.deleteSync();
    } on FileSystemException catch (e) {
      // Everything above this line passed, so the live database is sound and
      // the firm can be opened. Only the leftover is stuck -- say exactly
      // that, rather than throwing something indistinguishable from "this
      // database does not decrypt".
      throw PlaintextCopyNotRetired(keptPlaintext.path, e);
    }
  }

  /// Asks the one question that never goes stale with normal use: does this
  /// firm's live database genuinely decrypt under this key, and is what comes
  /// out sound and complete for this firm?
  void _verifyLiveDatabase(
    String firmId, {
    required String keyHex,
    required File tablesExpectedFrom,
  }) {
    final expectedTables = _tableNamesOf(tablesExpectedFrom);
    final live = raw.sqlite3.open(
      paths.firmDatabase(firmId).path,
      mode: raw.OpenMode.readOnly,
    );
    try {
      live.execute('PRAGMA key = "x\'$keyHex\'";');
      // PRAGMA key accepts any key without complaint; only a real read shows
      // whether it was the right one. Everything below is such a read.
      final cipherErrors = live.select('PRAGMA cipher_integrity_check');
      if (cipherErrors.isNotEmpty) {
        throw StateError(
          'The live database for firm $firmId failed its cipher integrity '
          'check: ${cipherErrors.rows}',
        );
      }
      final quickCheck = live.select('PRAGMA quick_check').first.values.first;
      if (quickCheck != 'ok') {
        throw StateError(
          'The live database for firm $firmId failed quick_check: $quickCheck',
        );
      }
      // Decrypting cleanly is not the same as being the right database.
      final firm = live.select('SELECT 1 FROM firms WHERE id = ?', [firmId]);
      if (firm.isEmpty) {
        throw StateError('The live database holds no row for firm $firmId');
      }
      // Names only, and only as a floor: a later drift migration may
      // legitimately ADD tables, but it will never make the firm's original
      // ones vanish.
      final liveTables = _userTables(live).toSet();
      final missing = expectedTables
          .where((table) => !liveTables.contains(table))
          .toList();
      if (missing.isNotEmpty) {
        throw StateError(
          'The live database for firm $firmId is missing tables the '
          'pre-encryption copy had: $missing',
        );
      }
    } finally {
      live.close();
    }
  }

  static List<String> _tableNamesOf(File plaintextFile) {
    final db = raw.sqlite3.open(
      plaintextFile.path,
      mode: raw.OpenMode.readOnly,
    );
    try {
      return _userTables(db);
    } finally {
      db.close();
    }
  }

  /// Repairs a [migrateToEncrypted] that died between the database swap and
  /// the envelope promotion -- the only window that leaves the two disagreeing.
  ///
  /// It cannot read the database to decide (the key is inside the very
  /// envelope in question), so it reads the file header instead: SQLCipher
  /// encrypts page 1 whole, including SQLite's magic string, so finding that
  /// string is a reliable "this file is still plaintext". Where it promotes,
  /// it deliberately does NOT retire the `.pre-encryption` copy -- see
  /// [retirePreEncryptionCopy] for why, and for whose job that is.
  ///
  /// The returned [RecoveryOutcome] is what a caller reacts to: an
  /// [RecoveryOutcome.indeterminate] firm is one whose database could not be
  /// classified at all, and deserves a clear error state rather than an opaque
  /// SQLite failure surfacing later with no explanation.
  ///
  /// [migrateToEncrypted] calls this itself before doing anything. Task 7's
  /// open/unlock flow should call it at firm-open time too, as defence in
  /// depth -- a firm that crashed mid-migration and is never migrated again
  /// would otherwise stay stranded.
  Future<RecoveryOutcome> recoverInterruptedMigration(String firmId) async {
    final pendingEnvelope = _pendingEnvelopeFile(firmId);
    final liveFile = paths.firmDatabase(firmId);
    var outcome = RecoveryOutcome.nothingToRecover;
    if (pendingEnvelope.existsSync()) {
      final envelope = paths.firmKeyEnvelope(firmId);
      // No database at all means the swap certainly did not happen.
      final isPlaintext = liveFile.existsSync()
          ? _isPlaintextSqlite(liveFile)
          : true;
      if (envelope.existsSync()) {
        // A real envelope already won; this staged copy is a leftover.
        pendingEnvelope.deleteSync();
      } else if (isPlaintext == true) {
        // The swap never happened, so the staged key wraps a database that is
        // not there. The live file is PROVED plaintext, which also makes
        // `.pre-encryption` a redundant duplicate of it rather than a safety
        // net -- retire it here rather than leave it for a retry that may
        // never come.
        pendingEnvelope.deleteSync();
        final keptPlaintext = _preEncryptionFile(firmId);
        if (keptPlaintext.existsSync()) keptPlaintext.deleteSync();
        outcome = RecoveryOutcome.revertedToPlaintext;
      } else if (isPlaintext == false) {
        // The swap happened: this staged envelope holds the only wrapped copy
        // of the key for the file now on disk. Finish what was interrupted.
        await pendingEnvelope.rename(envelope.path);
        _deleteJournalSidecars(liveFile);
        outcome = RecoveryOutcome.promotedToEncrypted;
      } else {
        // The header could not be read, so neither case is proved. Promoting
        // would mark the firm encrypted over a file nothing has vouched for;
        // dropping would destroy the only wrapped copy of a key that might
        // belong to it. Touch neither, and say so.
        outcome = RecoveryOutcome.indeterminate;
      }
    }
    for (final leftover in [
      File('${pendingEnvelope.path}.tmp'),
      File('${liveFile.path}.encrypting.tmp'),
    ]) {
      _deleteJournalSidecars(leftover);
      if (leftover.existsSync()) leftover.deleteSync();
    }
    return outcome;
  }

  File _pendingEnvelopeFile(String firmId) =>
      File('${paths.firmKeyEnvelope(firmId).path}.pending');

  File _preEncryptionFile(String firmId) =>
      File('${paths.firmDatabase(firmId).path}.pre-encryption');

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// True when [file] starts with SQLite's plaintext magic, false when it
  /// definitely does not, and **null when the answer cannot be established**
  /// -- a truncated header, an unreadable file. Reads only those 16 bytes,
  /// never the whole (potentially large) database.
  ///
  /// The three-way answer is the point: the caller promotes an envelope on
  /// `false`, and promoting over a file it could not read would mark a firm
  /// encrypted on no evidence at all.
  static bool? _isPlaintextSqlite(File file) {
    try {
      final handle = file.openSync();
      try {
        final header = handle.readSync(16);
        if (header.length < 16) return null;
        return String.fromCharCodes(header.sublist(0, 15)) ==
                'SQLite format 3' &&
            header[15] == 0;
      } finally {
        handle.closeSync();
      }
    } on FileSystemException {
      return null;
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

  Future<Uint8List?> unlockWithPassphrase(String firmId, String passphrase) =>
      unlockEnvelopeWithPassphrase(paths.firmKeyEnvelope(firmId), passphrase);

  Future<Uint8List?> unlockWithRecoveryCode(
    String firmId,
    String recoveryCode,
  ) => unlockEnvelopeWithRecoveryCode(
    paths.firmKeyEnvelope(firmId),
    recoveryCode,
  );

  /// Unlocks an envelope by FILE rather than by firm — the envelope that
  /// travelled beside a backup, which is the only thing that can open that
  /// backup once it is somewhere this firm's current session key means
  /// nothing: another device, or a backup taken before a recovery-code
  /// rotation on this one. The two methods above are this same logic aimed
  /// at the firm's own sidecar.
  Future<Uint8List?> unlockEnvelopeWithPassphrase(
    File envelopeFile,
    String passphrase,
  ) async {
    final envelope = await KeyEnvelopeStore(envelopeFile).read();
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

  Future<Uint8List?> unlockEnvelopeWithRecoveryCode(
    File envelopeFile,
    String recoveryCode,
  ) async {
    final envelope = await KeyEnvelopeStore(envelopeFile).read();
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
