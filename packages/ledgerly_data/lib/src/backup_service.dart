import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as raw;

import 'db/app_database.dart';

/// A backup file failed validation before it was ever allowed to overwrite
/// anything — never silently proceed with a corrupt or unrelated file.
class InvalidBackupException implements Exception {
  InvalidBackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BackupResult {
  const BackupResult({
    required this.localFile,
    required this.customerCount,
    this.userCopy,
    this.userCopyError,
  });
  final File localFile;
  final int customerCount;
  final File? userCopy;
  final String? userCopyError;
}

/// Phase 1 lives on one machine for months, so backups are not optional.
///
/// Order matters: write to a `.tmp` beside the app's own data (never straight
/// into a cloud-synced or removable folder), open the copy and check it, rename
/// it into place, copy it to the user's folder, and only then prune old ones.
class BackupService {
  BackupService({
    required this.db,
    required this.databaseFile,
    required this.localBackupDir,
    this.keyEnvelopeFile,
    this.userBackupDir,
    this.keep = 30,
    this.masterKey,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AppDatabase db;
  final File databaseFile;
  final Directory localBackupDir;
  final Directory? userBackupDir;
  final int keep;

  /// This firm's key envelope sidecar, or null for a firm that has none.
  ///
  /// Both wrapped copies of [masterKey] live only in this one small file, so
  /// a `.db`-only backup of an encrypted firm is undecryptable the moment the
  /// sidecar is lost — a disk failure, a reinstall, a new machine — no matter
  /// how carefully the passphrase and the printed recovery code were kept.
  /// The backup artifact is therefore the pair, always: see
  /// [envelopeSidecarFor] for how the two are named so nothing has to guess
  /// which envelope belongs to which backup.
  final File? keyEnvelopeFile;

  /// This session's SQLCipher master key, or null for an unencrypted firm.
  /// `VACUUM INTO` writes its copy with the source connection's key, so a
  /// backup of an encrypted firm is itself ciphertext: every probe connection
  /// below has to be keyed the same way or it cannot read what it just wrote.
  final List<int>? masterKey;

  final DateTime Function() _now;

  /// Applies this firm's key to a freshly opened probe connection. A no-op for
  /// an unencrypted firm, which must keep behaving exactly as it did before
  /// encryption existed.
  ///
  /// [override] is the key that belongs to one specific FILE rather than to
  /// this firm's current session — a backup restored from another device, or
  /// taken before a recovery-code rotation, unwrapped from the envelope that
  /// travelled with it.
  void _key(raw.Database probe, [List<int>? override]) {
    final key = override ?? masterKey;
    if (key == null) return;
    final hex = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    probe.execute('PRAGMA key = "x\'$hex\'";');
  }

  /// Where the envelope that belongs to [databaseBackup] lives: the backup's
  /// own path with `.key.json` appended, so the pair is unambiguous by name
  /// alone. A restore flow handed nothing but a `.db` file the user picked
  /// can find its key material from the filename, on a machine that has never
  /// seen this firm before.
  static File envelopeSidecarFor(File databaseBackup) =>
      File('${databaseBackup.path}.key.json');

  /// The envelope that travelled with [backupFile], or null when none did.
  /// An instance method rather than only the static naming rule so a test
  /// double can answer it without a real file on disk.
  File? pairedEnvelopeOf(File backupFile) {
    final sidecar = envelopeSidecarFor(backupFile);
    return sidecar.existsSync() ? sidecar : null;
  }

  /// Whether [backupFile] is ciphertext — the difference between "this backup
  /// is encrypted and its key file is missing" and "this file is not a
  /// database", which reject with the same words otherwise. An instance
  /// method for the same reason as [pairedEnvelopeOf].
  bool isCiphertext(File backupFile) => !looksLikePlaintextSqlite(backupFile);

  /// Whether [file] still carries SQLite's plaintext magic. SQLCipher
  /// encrypts page 1 whole, that magic string included, so `false` means the
  /// file is ciphertext — which is what lets a restore flow tell "this backup
  /// is encrypted and its key file is missing" apart from "this file is not a
  /// database", two failures that otherwise reject with the same words.
  static bool looksLikePlaintextSqlite(File file) {
    try {
      final handle = file.openSync();
      try {
        final header = handle.readSync(16);
        return header.length >= 16 &&
            String.fromCharCodes(header.sublist(0, 15)) == 'SQLite format 3' &&
            header[15] == 0;
      } finally {
        handle.closeSync();
      }
    } on FileSystemException {
      return false;
    }
  }

  String get _base => p.basenameWithoutExtension(databaseFile.path);

  /// Copies this firm's live envelope next to [databaseBackup]. A no-op for
  /// an unencrypted firm (nothing to carry) and for a firm whose sidecar has
  /// gone — the backup itself is still worth keeping, and a missing envelope
  /// is reported at restore time where the user can act on it.
  Future<void> _copyEnvelopeBeside(File databaseBackup) async {
    final envelope = keyEnvelopeFile;
    if (masterKey == null || envelope == null || !envelope.existsSync()) return;
    await envelope.copy(envelopeSidecarFor(databaseBackup).path);
  }

  Future<BackupResult> backupNow() async {
    await localBackupDir.create(recursive: true);
    final stampText = _format(_now());
    final finalFile = File(p.join(localBackupDir.path, '$_base-$stampText.db'));
    final tmp = File('${finalFile.path}.tmp');
    if (tmp.existsSync()) {
      tmp.deleteSync();
    }

    await db.customStatement("VACUUM INTO '${tmp.path.replaceAll("'", "''")}'");

    final liveCustomers = await _count(db, 'customers');
    final liveTransactions = await _count(db, 'transactions');
    _verify(tmp, customers: liveCustomers, transactions: liveTransactions);
    tmp.renameSync(finalFile.path);
    await _copyEnvelopeBeside(finalFile);

    File? userCopy;
    String? userCopyError;
    final target = userBackupDir;
    if (target != null) {
      try {
        await target.create(recursive: true);
        userCopy = await finalFile.copy(
          p.join(target.path, p.basename(finalFile.path)),
        );
        await _copyEnvelopeBeside(userCopy);
      } on FileSystemException catch (e) {
        userCopyError = 'Could not copy backup to ${target.path}: ${e.message}';
      }
    }
    _prune();
    return BackupResult(
      localFile: finalFile,
      customerCount: liveCustomers,
      userCopy: userCopy,
      userCopyError: userCopyError,
    );
  }

  /// Due when no verified backup is newer than 24 hours (by the timestamp in
  /// its name, so a restored or clock-shifted machine still answers sensibly).
  Future<bool> isDue({Duration every = const Duration(hours: 24)}) async {
    final newest = _backups()
        .map((f) => _parse(f))
        .whereType<DateTime>()
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    return newest == null || _now().difference(newest) >= every;
  }

  List<File> _backups() {
    if (!localBackupDir.existsSync()) return const [];
    return localBackupDir
        .listSync()
        .whereType<File>()
        .where(
          (f) =>
              p.basename(f.path).startsWith('$_base-') &&
              f.path.endsWith('.db'),
        )
        .toList();
  }

  void _prune() {
    final files = _backups()
      ..sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
    for (final old in files.skip(keep)) {
      old.deleteSync();
      // An envelope that outlives the backup it belongs to is key material
      // left on disk protecting nothing.
      final envelope = envelopeSidecarFor(old);
      if (envelope.existsSync()) envelope.deleteSync();
    }
  }

  /// Copies [backupFile] over the live database file, after checking it is
  /// really a Ledgerly database and after taking a safety copy of whatever
  /// is there now. The caller MUST close the open [db] connection before
  /// calling this (SQLite must not have the file open while it is replaced),
  /// then reopen a fresh connection to the same path afterwards — in this
  /// app that means invalidating the provider that owns the connection, not
  /// a full app relaunch. Returns the pre-restore safety copy, so an
  /// accidental restore is itself reversible.
  /// [withKey] restores a backup that is keyed differently from this session
  /// — a different device, or an older backup taken before a recovery-code
  /// rotation. Its envelope travels with it (see [envelopeSidecarFor]) and
  /// becomes this firm's envelope as part of the restore: without that swap
  /// the firm would end up holding a database whose key nothing on disk
  /// wraps any more.
  Future<File> restoreFrom(File backupFile, {List<int>? withKey}) async {
    validateBackup(backupFile, withKey: withKey);
    await localBackupDir.create(recursive: true);
    final preRestore = File(
      p.join(localBackupDir.path, '$_base-pre-restore-${_format(_now())}.db'),
    );
    if (databaseFile.existsSync()) {
      await databaseFile.copy(preRestore.path);
    }
    // Not gated on masterKey: what makes an undo possible is what is on disk
    // now, not whether this session happens to hold its key.
    final liveEnvelope = keyEnvelopeFile;
    if (liveEnvelope != null && liveEnvelope.existsSync()) {
      await liveEnvelope.copy(envelopeSidecarFor(preRestore).path);
    }
    await backupFile.copy(databaseFile.path);
    final backupEnvelope = envelopeSidecarFor(backupFile);
    if (liveEnvelope != null && backupEnvelope.existsSync()) {
      await backupEnvelope.copy(liveEnvelope.path);
    }
    return preRestore;
  }

  /// Checked by callers before closing the live connection, so a bad file
  /// picked by the user is rejected without ever disturbing the open firm.
  /// An instance method (not static) so a test double can replace it.
  void validateBackup(File backupFile, {List<int>? withKey}) {
    if (!backupFile.existsSync()) {
      throw InvalidBackupException('That file does not exist.');
    }
    // sqlite3.open() succeeds even on a non-database file — it only notices
    // once it actually reads the file, e.g. on the first query below.
    final raw.Database probe;
    try {
      probe = raw.sqlite3.open(backupFile.path, mode: raw.OpenMode.readOnly);
    } on Exception {
      throw InvalidBackupException('That is not a valid database file.');
    }
    try {
      // `PRAGMA key` never rejects a wrong (or missing) key by itself -- it is
      // the first real read below that reveals one, as a plain "file is not a
      // database". That is the same rejection an unrelated file gets, which is
      // exactly right here: either way this file is not one we can restore.
      try {
        _key(probe, withKey);
      } on raw.SqliteException {
        throw InvalidBackupException('That is not a valid database file.');
      }
      String check;
      try {
        check = probe.select('PRAGMA quick_check').first.values.first as String;
      } on raw.SqliteException {
        throw InvalidBackupException('That is not a valid database file.');
      }
      if (check != 'ok') {
        throw InvalidBackupException('That backup file is corrupted.');
      }
      try {
        final firms =
            probe.select('SELECT count(*) AS c FROM firms').first['c'] as int;
        if (firms == 0) {
          throw InvalidBackupException('That file has no firm in it.');
        }
      } on raw.SqliteException {
        throw InvalidBackupException('That file is not a Ledgerly backup.');
      }
    } finally {
      probe.close();
    }
  }

  /// Not static: an encrypted firm's copy only opens with [masterKey].
  void _verify(File copy, {required int customers, required int transactions}) {
    final probe = raw.sqlite3.open(copy.path, mode: raw.OpenMode.readOnly);
    try {
      _key(probe);
      final check = probe.select('PRAGMA quick_check').first.values.first;
      if (check != 'ok') {
        throw StateError('Backup failed integrity check: $check');
      }
      final c =
          probe.select('SELECT count(*) AS c FROM customers').first['c'] as int;
      final t =
          probe.select('SELECT count(*) AS c FROM transactions').first['c']
              as int;
      if (c != customers || t != transactions) {
        throw StateError(
          'Backup row counts differ (customers $c/$customers, transactions $t/$transactions)',
        );
      }
    } finally {
      probe.close();
    }
  }

  static Future<int> _count(AppDatabase db, String table) async {
    final row = await db
        .customSelect('SELECT count(*) AS c FROM $table')
        .getSingle();
    return row.read<int>('c');
  }

  static String _format(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}${two(t.second)}';
  }

  DateTime? _parse(File f) {
    final m = RegExp(r'-(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})\.db$')
        .firstMatch(f.path);
    if (m == null) return null;
    return DateTime.utc(
      int.parse(m[1]!),
      int.parse(m[2]!),
      int.parse(m[3]!),
      int.parse(m[4]!),
      int.parse(m[5]!),
      int.parse(m[6]!),
    );
  }
}
