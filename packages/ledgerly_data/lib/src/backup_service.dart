import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as raw;

import 'db/app_database.dart';

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
    this.userBackupDir,
    this.keep = 30,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AppDatabase db;
  final File databaseFile;
  final Directory localBackupDir;
  final Directory? userBackupDir;
  final int keep;
  final DateTime Function() _now;

  String get _base => p.basenameWithoutExtension(databaseFile.path);

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

    File? userCopy;
    String? userCopyError;
    final target = userBackupDir;
    if (target != null) {
      try {
        await target.create(recursive: true);
        userCopy = await finalFile.copy(
          p.join(target.path, p.basename(finalFile.path)),
        );
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
    }
  }

  static void _verify(
    File copy, {
    required int customers,
    required int transactions,
  }) {
    final probe = raw.sqlite3.open(copy.path, mode: raw.OpenMode.readOnly);
    try {
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
