import 'dart:io';

import 'package:drift/native.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:test/test.dart';

/// Backups of an ENCRYPTED firm. `VACUUM INTO` inherits the source
/// connection's key, so the backup file is ciphertext too -- which means every
/// probe connection BackupService opens against it has to be keyed, or a
/// backup of an encrypted firm fails its own verification step.
void main() {
  late Directory tmp;
  late DeviceContext ctx;

  final key = List.generate(32, (i) => i);
  final wrongKey = List.generate(32, (i) => 255 - i);
  String keyHex(List<int> k) =>
      k.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('backup_encrypted_test');
    ctx = DeviceContext(
      firmId: '11111111-1111-4111-8111-111111111111',
      deviceId: '22222222-2222-4222-8222-222222222222',
      deviceShortCode: 'A3F9',
      userId: '33333333-3333-4333-8333-333333333333',
      hlc: Hlc(clock: () => 1000),
    );
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  /// Opens + keys a raw connection and hands that SAME connection to drift via
  /// NativeDatabase.opened -- the identical shape the real app's
  /// databaseOpenerProvider produces (a `PRAGMA key` before drift touches
  /// anything), so this exercises the wiring rather than a shortcut around it.
  Future<AppDatabase> keyedFirm(File dbFile, List<int> k) async {
    await dbFile.parent.create(recursive: true);
    final seed = raw.sqlite3.open(dbFile.path)
      ..execute('PRAGMA key = "x\'${keyHex(k)}\'";');
    final db = AppDatabase(NativeDatabase.opened(seed));
    await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
    await CustomersRepository(db, ctx).create(name: 'Rashid Traders');
    return db;
  }

  Future<AppDatabase> plaintextFirm(File dbFile) async {
    await dbFile.parent.create(recursive: true);
    final db = AppDatabase(NativeDatabase(dbFile));
    await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
    await CustomersRepository(db, ctx).create(name: 'Rashid Traders');
    return db;
  }

  test('backing up an encrypted firm produces a backup that is genuinely '
      'ciphertext, and validates with the key', () async {
    final dbFile = File(p.join(tmp.path, 'firms', 'firm.db'));
    final db = await keyedFirm(dbFile, key);
    final service = BackupService(
      db: db,
      databaseFile: dbFile,
      localBackupDir: Directory(p.join(tmp.path, 'backups')),
      masterKey: key,
    );

    final result = await service.backupNow();
    await db.close();

    expect(result.customerCount, 1);
    // Not readable plaintext SQLite: without this the checks below would pass
    // just as happily against an accidentally-unencrypted backup.
    final header = result.localFile.readAsBytesSync().sublist(0, 16);
    expect(String.fromCharCodes(header), isNot(startsWith('SQLite format 3')));

    // The backup must NOT open with an unkeyed probe...
    final unkeyed = raw.sqlite3.open(
      result.localFile.path,
      mode: raw.OpenMode.readOnly,
    );
    expect(() => unkeyed.select('PRAGMA quick_check'), throwsA(anything));
    unkeyed.close();

    // ...but it does open, and holds the real rows, with the right key.
    final reopened = raw.sqlite3.open(
      result.localFile.path,
      mode: raw.OpenMode.readOnly,
    )..execute('PRAGMA key = "x\'${keyHex(key)}\'";');
    expect(
      reopened.select('SELECT count(*) AS c FROM customers').first['c'],
      1,
    );
    reopened.close();

    service.validateBackup(result.localFile); // must not throw
  });

  test('a keyed service rejects a backup it cannot actually read', () async {
    final dbFile = File(p.join(tmp.path, 'firms', 'firm.db'));
    final db = await keyedFirm(dbFile, key);
    final encryptedBackup = (await BackupService(
      db: db,
      databaseFile: dbFile,
      localBackupDir: Directory(p.join(tmp.path, 'backups')),
      masterKey: key,
    ).backupNow()).localFile;
    await db.close();

    // Wrong key: PRAGMA key accepts anything, so this can only be caught by
    // the first real read -- it must surface as a rejection, not a crash.
    final wrong = BackupService(
      db: db,
      databaseFile: dbFile,
      localBackupDir: Directory(p.join(tmp.path, 'backups')),
      masterKey: wrongKey,
    );
    expect(
      () => wrong.validateBackup(encryptedBackup),
      throwsA(isA<InvalidBackupException>()),
    );

    // No key at all against an encrypted backup: same rejection.
    final unkeyed = BackupService(
      db: db,
      databaseFile: dbFile,
      localBackupDir: Directory(p.join(tmp.path, 'backups')),
    );
    expect(
      () => unkeyed.validateBackup(encryptedBackup),
      throwsA(isA<InvalidBackupException>()),
    );
  });

  test(
    'a null masterKey leaves the unencrypted firm path exactly as it was',
    () async {
      final dbFile = File(p.join(tmp.path, 'firms', 'firm.db'));
      final db = await plaintextFirm(dbFile);
      final service = BackupService(
        db: db,
        databaseFile: dbFile,
        localBackupDir: Directory(p.join(tmp.path, 'backups')),
      );

      final result = await service.backupNow();
      expect(result.customerCount, 1);
      final header = result.localFile.readAsBytesSync().sublist(0, 16);
      expect(String.fromCharCodes(header), startsWith('SQLite format 3'));
      service.validateBackup(result.localFile); // must not throw

      // And a keyed service must not silently accept that plaintext backup.
      final keyed = BackupService(
        db: db,
        databaseFile: dbFile,
        localBackupDir: Directory(p.join(tmp.path, 'backups')),
        masterKey: key,
      );
      expect(
        () => keyed.validateBackup(result.localFile),
        throwsA(isA<InvalidBackupException>()),
      );
      await db.close();
    },
  );
}
