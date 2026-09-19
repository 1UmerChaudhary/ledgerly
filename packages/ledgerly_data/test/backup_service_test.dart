import 'dart:io';

import 'package:drift/native.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late File dbFile;
  late AppDatabase db;
  late DeviceContext ctx;
  var now = DateTime.utc(2026, 9, 19, 9, 0);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('ledgerly_backup_');
    dbFile = File(p.join(tmp.path, 'firms', 'firm.db'));
    await dbFile.parent.create(recursive: true);
    db = AppDatabase(NativeDatabase(dbFile));
    ctx = DeviceContext(
      firmId: '11111111-1111-4111-8111-111111111111',
      deviceId: '22222222-2222-4222-8222-222222222222',
      deviceShortCode: 'A3F9',
      userId: '33333333-3333-4333-8333-333333333333',
      hlc: Hlc(clock: () => 1000),
    );
    await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
    await CustomersRepository(db, ctx).create(name: 'Rashid Traders');
  });
  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  BackupService service({int keep = 30}) => BackupService(
    db: db,
    databaseFile: dbFile,
    localBackupDir: Directory(p.join(tmp.path, 'backups')),
    userBackupDir: Directory(p.join(tmp.path, 'usb')),
    keep: keep,
    now: () => now,
  );

  test(
    'backupNow writes a verified copy locally and to the user folder',
    () async {
      final result = await service().backupNow();
      expect(result.localFile.existsSync(), isTrue);
      expect(result.userCopy!.existsSync(), isTrue);
      expect(p.basename(result.localFile.path), 'firm-20260919-090000.db');
      expect(result.customerCount, 1);
    },
  );

  test('a backup opens on its own and contains the same rows', () async {
    final result = await service().backupNow();
    final copy = AppDatabase(NativeDatabase(result.localFile));
    final rows = await copy
        .customSelect('SELECT count(*) AS c FROM customers')
        .getSingle();
    expect(rows.read<int>('c'), 1);
    await copy.close();
  });

  test(
    'prunes to the newest N, never counting an unverified .tmp file',
    () async {
      final s = service(keep: 2);
      for (var i = 0; i < 4; i++) {
        now = now.add(const Duration(hours: 1));
        await s.backupNow();
      }
      await File(p.join(tmp.path, 'backups', 'firm-junk.db.tmp'))
          .writeAsString('half written');
      final kept = Directory(
        p.join(tmp.path, 'backups'),
      ).listSync().map((f) => p.basename(f.path)).toList()..sort();
      expect(kept, [
        'firm-20260919-120000.db',
        'firm-20260919-130000.db',
        'firm-junk.db.tmp',
      ]);
    },
  );

  test('isDue when no backup in the last 24 hours', () async {
    final s = service();
    expect(await s.isDue(), isTrue);
    await s.backupNow();
    expect(await s.isDue(), isFalse);
    now = now.add(const Duration(hours: 25));
    expect(await s.isDue(), isTrue);
  });

  group('restoreFrom', () {
    test('copies a valid backup over the live file and keeps a pre-restore safety copy', () async {
      final result = await service().backupNow();
      await db.close(); // restoreFrom requires the live connection closed first

      final preRestore = await service().restoreFrom(result.localFile);
      expect(preRestore.existsSync(), isTrue);
      final restored = AppDatabase(NativeDatabase(dbFile));
      final rows = await restored
          .customSelect('SELECT count(*) AS c FROM customers')
          .getSingle();
      expect(
        rows.read<int>('c'),
        1,
      ); // Rashid Traders, from the outer setUp seed
      await restored.close();
    });

    test('rejects a file that is not a valid SQLite database', () async {
      await db.close();
      final junk = File(p.join(tmp.path, 'junk.db'));
      await junk.writeAsBytes([1, 2, 3, 4]);
      expect(
        () => service().restoreFrom(junk),
        throwsA(isA<InvalidBackupException>()),
      );
    });

    test('rejects a valid SQLite file with none of our tables', () async {
      await db.close();
      final empty = File(p.join(tmp.path, 'empty.db'));
      final rawDb = sqlite3.open(empty.path);
      rawDb.execute('CREATE TABLE unrelated (id INTEGER)');
      rawDb.close();
      expect(
        () => service().restoreFrom(empty),
        throwsA(isA<InvalidBackupException>()),
      );
    });

    test('rejects a file that does not exist', () {
      expect(
        () => service().restoreFrom(File(p.join(tmp.path, 'nope.db'))),
        throwsA(isA<InvalidBackupException>()),
      );
    });
  });

  test('a missing user folder is reported, not fatal', () async {
    final s = BackupService(
      db: db,
      databaseFile: dbFile,
      localBackupDir: Directory(p.join(tmp.path, 'backups')),
      userBackupDir: Directory('/nonexistent/volume/backups'),
      now: () => now,
    );
    final result = await s.backupNow();
    expect(result.localFile.existsSync(), isTrue);
    expect(result.userCopy, isNull);
    expect(result.userCopyError, isNotNull);
  });
}
