import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:ledgerly/bootstrap/app_paths.dart';
import 'package:ledgerly/features/encryption/encryption_service.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:test/test.dart';

/// The one migration in this app that rewrites a firm's live database file
/// while real customer and transaction rows are already in it. Everything
/// here is about one property: the plaintext original is never touched until
/// an encrypted copy has been proved good, and is still recoverable after.
///
/// Runs under `flutter test`, not plain `dart test`: EncryptionService reaches
/// AppPaths, which imports path_provider, which pulls in dart:ui. It is a
/// plain `test()` and never a `testWidgets()`, so its real file I/O never goes
/// near the widget tester that would wedge on it.
void main() {
  late Directory tmp;
  late AppPaths paths;
  late EncryptionService service;
  const firmId = '11111111-1111-4111-8111-111111111111';
  const passphrase = 'correct horse battery staple';

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('encryption_migration_test');
    paths = AppPaths(tmp);
    await paths.firms.create(recursive: true);
    service = EncryptionService(paths: paths);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  String hexOf(Uint8List key) =>
      key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// A real, plaintext firm database of the shape an existing customer already
  /// has on disk: the full drift schema plus rows in several tables. Closed
  /// before it is returned -- SQLite must not have the file open while
  /// sqlcipher_export rewrites it.
  Future<void> seedPlaintextFirm() async {
    final db = AppDatabase(NativeDatabase(paths.firmDatabase(firmId)));
    final ctx = DeviceContext(
      firmId: firmId,
      deviceId: '22222222-2222-4222-8222-222222222222',
      deviceShortCode: 'A3F9',
      userId: '33333333-3333-4333-8333-333333333333',
      hlc: Hlc(clock: () => 1000),
    );
    await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
    await CustomersRepository(db, ctx).create(name: 'Rashid Traders');
    await CustomersRepository(db, ctx).create(name: 'Bilal Fabrics');
    await db.close();
  }

  raw.Database openKeyed(File file, Uint8List key) =>
      raw.sqlite3.open(file.path, mode: raw.OpenMode.readOnly)
        ..execute('PRAGMA key = "x\'${hexOf(key)}\'";');

  test('migrating encrypts the live file in place, keeps the plaintext '
      'original, and the envelope unlocks what was written', () async {
    await seedPlaintextFirm();
    final live = paths.firmDatabase(firmId);
    final plaintextBytes = live.readAsBytesSync();

    String? recoveryCode;
    await service.migrateToEncrypted(
      firmId,
      passphrase: passphrase,
      onRecoveryCodeGenerated: (code) => recoveryCode = code,
    );

    // The live file is now ciphertext...
    expect(
      String.fromCharCodes(live.readAsBytesSync().sublist(0, 16)),
      isNot(startsWith('SQLite format 3')),
    );
    // ...the plaintext original survives beside it, byte for byte...
    final kept = File('${live.path}.pre-encryption');
    expect(kept.existsSync(), isTrue);
    expect(kept.readAsBytesSync(), plaintextBytes);
    // ...and the scratch file is gone.
    expect(File('${live.path}.encrypting.tmp').existsSync(), isFalse);

    // The envelope's key is genuinely the key the file was written with:
    // the only way to know is a real read, which PRAGMA key alone is not.
    expect(await service.isEncrypted(firmId), isTrue);
    final key = await service.unlockWithPassphrase(firmId, passphrase);
    expect(key, isNotNull);
    final probe = openKeyed(live, key!);
    expect(probe.select('PRAGMA quick_check').first.values.first, 'ok');
    expect(probe.select('SELECT count(*) AS c FROM customers').first['c'], 2);
    expect(probe.select('SELECT count(*) AS c FROM firms').first['c'], 1);
    // drift stores its schema version here. Lose it and the next open looks
    // like a brand-new database and re-runs onCreate over a full one.
    expect(probe.select('PRAGMA user_version').first.values.first, 1);
    probe.close();

    // And the same key opens it through drift itself, as the app will.
    final keyed = raw.sqlite3.open(live.path)
      ..execute('PRAGMA key = "x\'${hexOf(key)}\'";');
    final db = AppDatabase(NativeDatabase.opened(keyed));
    final names = await db.customSelect('SELECT name FROM customers').get();
    expect(names.length, 2);
    await db.close();

    // The recovery code unlocks the same file too.
    expect(recoveryCode, isNotNull);
    final viaCode = await service.unlockWithRecoveryCode(firmId, recoveryCode!);
    expect(viaCode, key);
  });

  test('a database that cannot be exported leaves the live file untouched and '
      'the firm unencrypted', () async {
    final live = paths.firmDatabase(firmId);
    final garbage = Uint8List.fromList(List.generate(4096, (i) => i % 256));
    live.writeAsBytesSync(garbage);

    await expectLater(
      service.migrateToEncrypted(
        firmId,
        passphrase: passphrase,
        onRecoveryCodeGenerated: (_) => fail('must not reach the envelope'),
      ),
      throwsA(anything),
    );

    expect(live.readAsBytesSync(), garbage);
    expect(await service.isEncrypted(firmId), isFalse);
    expect(File('${live.path}.pre-encryption').existsSync(), isFalse);
    expect(File('${live.path}.encrypting.tmp').existsSync(), isFalse);
  });

  test('migrating a firm that is already encrypted is refused, so the one '
      'plaintext copy is never overwritten with ciphertext', () async {
    await seedPlaintextFirm();
    final live = paths.firmDatabase(firmId);
    await service.migrateToEncrypted(
      firmId,
      passphrase: passphrase,
      onRecoveryCodeGenerated: (_) {},
    );
    final keptBytes = File('${live.path}.pre-encryption').readAsBytesSync();

    await expectLater(
      service.migrateToEncrypted(
        firmId,
        passphrase: passphrase,
        onRecoveryCodeGenerated: (_) {},
      ),
      throwsA(isA<StateError>()),
    );
    expect(File('${live.path}.pre-encryption').readAsBytesSync(), keptBytes);
    expect(
      String.fromCharCodes(keptBytes.sublist(0, 16)),
      startsWith('SQLite format 3'),
    );
  });

  test('migrating a firm with no database file at all is refused', () async {
    await expectLater(
      service.migrateToEncrypted(
        firmId,
        passphrase: passphrase,
        onRecoveryCodeGenerated: (_) {},
      ),
      throwsA(isA<StateError>()),
    );
    expect(paths.firmDatabase(firmId).existsSync(), isFalse);
  });
}
