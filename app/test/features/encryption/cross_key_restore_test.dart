import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:ledgerly/bootstrap/app_paths.dart';
import 'package:ledgerly/features/encryption/encryption_service.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:test/test.dart';

/// Restoring an encrypted backup onto a machine that has never seen this firm
/// — a reinstall, a replacement PC, a backup older than a recovery-code
/// rotation. The key that opens it is not the key this session holds (there
/// isn't one); it is wrapped inside the envelope that travelled beside the
/// `.db` file, and the only things that can unwrap it are the passphrase or
/// the recovery code THAT backup was made under.
///
/// Runs under `flutter test` as a plain `test()`, never a `testWidgets()`:
/// AppPaths pulls in path_provider (and so dart:ui), while the real file I/O
/// here would wedge the widget tester — same shape as
/// `encryption_migration_test.dart`.
void main() {
  late Directory deviceA;
  late Directory deviceB;
  const firmId = '11111111-1111-4111-8111-111111111111';
  const passphrase = 'correct horse battery staple';

  setUp(() async {
    // Several throwaway connections per test, by design; this is not the
    // production multi-database misuse the warning exists to catch.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    deviceA = Directory.systemTemp.createTempSync('cross_key_restore_A');
    deviceB = Directory.systemTemp.createTempSync('cross_key_restore_B');
  });
  tearDown(() {
    deviceA.deleteSync(recursive: true);
    deviceB.deleteSync(recursive: true);
  });

  String hexOf(List<int> key) =>
      key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// What the user carries over on a USB stick: exactly the two files a real
  /// backup leaves in the backup folder.
  Future<({File db, File envelope, String code, Uint8List key})>
  makeBackup() async {
    final paths = AppPaths(deviceA);
    await paths.firms.create(recursive: true);
    await paths.backups.create(recursive: true);
    final ctx = DeviceContext(
      firmId: firmId,
      deviceId: '22222222-2222-4222-8222-222222222222',
      deviceShortCode: 'A3F9',
      userId: '33333333-3333-4333-8333-333333333333',
      hlc: Hlc(clock: () => 1000),
    );

    final seedDb = AppDatabase(NativeDatabase(paths.firmDatabase(firmId)));
    await FirmSetup(
      seedDb,
      ctx,
    ).createFirm(name: 'Mill', contactNumber: '0300');
    await CustomersRepository(seedDb, ctx).create(name: 'Rashid Traders');
    await seedDb.close();

    final service = EncryptionService(paths: paths);
    late String code;
    await service.migrateToEncrypted(
      firmId,
      passphrase: passphrase,
      onRecoveryCodeGenerated: (c) => code = c,
    );
    final key = (await service.unlockWithPassphrase(firmId, passphrase))!;

    final live = raw.sqlite3.open(paths.firmDatabase(firmId).path)
      ..execute('PRAGMA key = "x\'${hexOf(key)}\'";');
    final db = AppDatabase(NativeDatabase.opened(live));
    final result = await BackupService(
      db: db,
      databaseFile: paths.firmDatabase(firmId),
      keyEnvelopeFile: paths.firmKeyEnvelope(firmId),
      localBackupDir: paths.backups,
      masterKey: key,
    ).backupNow();
    await db.close();

    return (
      db: result.localFile,
      envelope: BackupService.envelopeSidecarFor(result.localFile),
      code: code,
      key: key,
    );
  }

  /// The pair, and nothing else, sitting in a folder on the new machine.
  ({File db, File envelope}) carryTo(Directory folder, File db, File envelope) {
    folder.createSync(recursive: true);
    final carriedDb = db.copySync('${folder.path}/${db.uri.pathSegments.last}');
    final carriedEnvelope = envelope.copySync(
      BackupService.envelopeSidecarFor(carriedDb).path,
    );
    return (db: carriedDb, envelope: carriedEnvelope);
  }

  /// Device B as it really is before the restore: an installed app with its
  /// own empty folders and no key, no envelope and no database for this firm.
  ({AppPaths paths, BackupService restore}) freshDevice() {
    final paths = AppPaths(deviceB);
    paths.firms.createSync(recursive: true);
    paths.backups.createSync(recursive: true);
    return (
      paths: paths,
      restore: BackupService(
        // Never read by validateBackup/restoreFrom; a restore happens with
        // the firm's own connection closed, which on a fresh device was
        // never opened at all.
        db: AppDatabase(NativeDatabase.memory()),
        databaseFile: paths.firmDatabase(firmId),
        keyEnvelopeFile: paths.firmKeyEnvelope(firmId),
        localBackupDir: paths.backups,
      ),
    );
  }

  test('a backup+envelope pair carried to a machine that has never seen this '
      'firm restores under the pair OWN passphrase, and the firm is left '
      'holding that pair envelope', () async {
    final made = await makeBackup();
    final carried = carryTo(
      Directory('${deviceB.path}/usb'),
      made.db,
      made.envelope,
    );
    final device = freshDevice();
    final service = EncryptionService(paths: device.paths);

    // Nothing about this session knows the key; it comes out of the
    // envelope that travelled with the file.
    final key = await service.unlockEnvelopeWithPassphrase(
      carried.envelope,
      passphrase,
    );
    expect(key, isNotNull);

    device.restore.validateBackup(carried.db, withKey: key);
    await device.restore.restoreFrom(carried.db, withKey: key);

    // Real rows, through the recovered key, out of the file now live on
    // device B.
    final restored = raw.sqlite3.open(
      device.paths.firmDatabase(firmId).path,
      mode: raw.OpenMode.readOnly,
    )..execute('PRAGMA key = "x\'${hexOf(key!)}\'";');
    expect(
      restored.select('SELECT name FROM customers').first['name'],
      'Rashid Traders',
    );
    restored.close();

    // And the firm's own envelope is the backup's: without this swap the
    // restored database would be keyed by something nothing on this device
    // can ever unwrap again.
    expect(
      device.paths.firmKeyEnvelope(firmId).readAsStringSync(),
      carried.envelope.readAsStringSync(),
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('the wrong passphrase against a carried envelope fails closed — no key, '
      'and the restore never runs', () async {
    final made = await makeBackup();
    final carried = carryTo(
      Directory('${deviceB.path}/usb'),
      made.db,
      made.envelope,
    );
    final device = freshDevice();
    final service = EncryptionService(paths: device.paths);

    expect(
      await service.unlockEnvelopeWithPassphrase(
        carried.envelope,
        'not the passphrase',
      ),
      isNull,
    );
    expect(
      await service.unlockEnvelopeWithRecoveryCode(
        carried.envelope,
        encodeRecoveryCode(Uint8List.fromList(List.filled(32, 7))),
      ),
      isNull,
    );
    // Nothing was restored: device B is still a device with no firm on it.
    expect(device.paths.firmDatabase(firmId).existsSync(), isFalse);
    expect(device.paths.firmKeyEnvelope(firmId).existsSync(), isFalse);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test(
    "the pair's own recovery code opens it too, for the user who reinstalled "
    'and no longer has the passphrase',
    () async {
      final made = await makeBackup();
      final carried = carryTo(
        Directory('${deviceB.path}/usb'),
        made.db,
        made.envelope,
      );
      final device = freshDevice();
      final service = EncryptionService(paths: device.paths);

      final key = await service.unlockEnvelopeWithRecoveryCode(
        carried.envelope,
        made.code,
      );
      expect(key, isNotNull);
      device.restore.validateBackup(carried.db, withKey: key);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'an encrypted backup whose envelope did NOT travel with it is refused, '
    'and is identifiable as ciphertext rather than as a broken file',
    () async {
      final made = await makeBackup();
      final folder = Directory('${deviceB.path}/usb')
        ..createSync(recursive: true);
      final orphan = made.db.copySync('${folder.path}/orphan.db');
      final device = freshDevice();

      expect(device.restore.pairedEnvelopeOf(orphan), isNull);
      expect(device.restore.isCiphertext(orphan), isTrue);
      expect(
        () => device.restore.validateBackup(orphan),
        throwsA(isA<InvalidBackupException>()),
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
