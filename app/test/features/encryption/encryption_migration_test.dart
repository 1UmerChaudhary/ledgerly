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
/// here is about two properties: the plaintext original is never touched until
/// an encrypted copy has been proved good, and no state this can be
/// interrupted in leaves the firm quietly running on plaintext.
///
/// Runs under `flutter test`, not plain `dart test`: EncryptionService reaches
/// AppPaths, which imports path_provider, which pulls in dart:ui. It is a
/// plain `test()` and never a `testWidgets()`, so its real file I/O never goes
/// near the widget tester that would wedge on it.
/// Why a chmod-based "this delete will fail" setup cannot be trusted here, or
/// null when it can. Windows does not gate unlink on directory permissions at
/// all; root ignores them, so under the root user common in Docker CI the
/// delete SUCCEEDS and the test fails rather than skipping -- a red build that
/// says nothing about the code.
String? get _cannotBlockUnlink {
  if (Platform.isWindows) return 'chmod does not gate unlink on Windows';
  // No dart:io uid getter, so ask the OS. A non-zero exit (no `id` on PATH)
  // is itself a reason not to rely on the setup.
  final id = Process.runSync('id', ['-u']);
  if (id.exitCode != 0) return 'could not determine the user id';
  return (id.stdout as String).trim() == '0'
      ? 'root ignores directory permissions, so the delete would succeed'
      : null;
}

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

  File live() => paths.firmDatabase(firmId);
  File envelope() => paths.firmKeyEnvelope(firmId);
  File pendingEnvelope() => File('${envelope().path}.pending');
  File scratch() => File('${live().path}.encrypting.tmp');
  File keptPlaintext() => File('${live().path}.pre-encryption');

  bool isCiphertext(File file) =>
      !String.fromCharCodes(file.readAsBytesSync().sublist(0, 16))
          .startsWith('SQLite format 3');

  /// A real, plaintext firm database of the shape an existing customer already
  /// has on disk: the full drift schema plus rows in several tables. Closed
  /// before it is returned -- SQLite must not have the file open while
  /// sqlcipher_export rewrites it.
  Future<void> seedPlaintextFirm() async {
    final db = AppDatabase(NativeDatabase(live()));
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

  /// Migrates, dying in the swap-to-promotion window, then recovers: the state
  /// that strands a `.pre-encryption` copy for a keyed caller to retire later.
  Future<Uint8List> crashMigrateThenRecover() async {
    await seedPlaintextFirm();
    service.afterDatabaseSwapHook = () async =>
        throw const FormatException('simulated crash');
    await expectLater(
      service.migrateToEncrypted(
        firmId,
        passphrase: passphrase,
        onRecoveryCodeGenerated: (_) {},
      ),
      throwsA(isA<FormatException>()),
    );
    service.afterDatabaseSwapHook = null;
    expect(
      await service.recoverInterruptedMigration(firmId),
      RecoveryOutcome.promotedToEncrypted,
    );
    final key = await service.unlockWithPassphrase(firmId, passphrase);
    expect(key, isNotNull);
    return key!;
  }

  test('migrating encrypts the live file in place, retires the plaintext '
      'copy, and the envelope unlocks what was written', () async {
    await seedPlaintextFirm();

    String? recoveryCode;
    await service.migrateToEncrypted(
      firmId,
      passphrase: passphrase,
      onRecoveryCodeGenerated: (code) => recoveryCode = code,
    );

    // The live file is now ciphertext, and NOTHING plaintext is left behind:
    // a copy of the ledger sitting beside the encrypted one would undo the
    // entire point of encrypting it.
    expect(isCiphertext(live()), isTrue);
    expect(keptPlaintext().existsSync(), isFalse);
    expect(scratch().existsSync(), isFalse);
    expect(pendingEnvelope().existsSync(), isFalse);
    expect(
      paths.firms
          .listSync()
          .map((e) => e.path.split(Platform.pathSeparator).last)
          .toList()
        ..sort(),
      ['$firmId.db', '$firmId.key.json'],
    );

    // The envelope's key is genuinely the key the file was written with:
    // the only way to know is a real read, which PRAGMA key alone is not.
    expect(await service.isEncrypted(firmId), isTrue);
    final key = await service.unlockWithPassphrase(firmId, passphrase);
    expect(key, isNotNull);
    final probe = openKeyed(live(), key!);
    expect(probe.select('PRAGMA quick_check').first.values.first, 'ok');
    expect(probe.select('SELECT count(*) AS c FROM customers').first['c'], 2);
    expect(probe.select('SELECT count(*) AS c FROM firms').first['c'], 1);
    // drift stores its schema version here. Lose it and the next open looks
    // like a brand-new database and re-runs onCreate over a full one.
    expect(probe.select('PRAGMA user_version').first.values.first, 1);
    probe.close();

    // And the same key opens it through drift itself, as the app will.
    final keyed = raw.sqlite3.open(live().path)
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

  test('a crash between the database swap and the envelope promotion leaves '
      'the firm unencrypted-and-loud, never encrypted-and-silent', () async {
    await seedPlaintextFirm();
    service.afterDatabaseSwapHook = () async =>
        throw const FormatException('simulated crash');

    await expectLater(
      service.migrateToEncrypted(
        firmId,
        passphrase: passphrase,
        onRecoveryCodeGenerated: (_) => fail('the crash preceded this'),
      ),
      throwsA(isA<FormatException>()),
    );

    // The database really was swapped...
    expect(isCiphertext(live()), isTrue);
    // ...but the firm does NOT claim to be encrypted, because the envelope was
    // never promoted. That is the whole point: an unkeyed open of a ciphertext
    // file fails loudly, where the reverse mistake -- a firm calling itself
    // encrypted over a plaintext file -- would keep writing ledger rows in
    // the clear while every screen said it was protected.
    expect(await service.isEncrypted(firmId), isFalse);
    expect(envelope().existsSync(), isFalse);
    // The key material and the original data are both still on disk.
    expect(pendingEnvelope().existsSync(), isTrue);
    expect(keptPlaintext().existsSync(), isTrue);
    expect(isCiphertext(keptPlaintext()), isFalse);
    final unkeyed = raw.sqlite3.open(live().path, mode: raw.OpenMode.readOnly);
    expect(() => unkeyed.select('PRAGMA quick_check'), throwsA(anything));
    unkeyed.close();

    // Recovery promotes the staged envelope and the firm comes up encrypted.
    service.afterDatabaseSwapHook = null;
    expect(
      await service.recoverInterruptedMigration(firmId),
      RecoveryOutcome.promotedToEncrypted,
    );
    expect(await service.isEncrypted(firmId), isTrue);
    expect(pendingEnvelope().existsSync(), isFalse);
    final key = await service.unlockWithPassphrase(firmId, passphrase);
    expect(key, isNotNull);
    final probe = openKeyed(live(), key!);
    expect(probe.select('SELECT count(*) AS c FROM customers').first['c'], 2);
    probe.close();

    // Recovery must NOT have retired the plaintext copy. It has no key, so all
    // it can say about the live file is "this looks like ciphertext" -- never
    // "this decrypts to the same data". Deleting the last plaintext copy of a
    // ledger on that weaker claim is exactly what must not happen.
    expect(keptPlaintext().existsSync(), isTrue);
    expect(isCiphertext(keptPlaintext()), isFalse);

    // Whoever holds the key finishes the job -- Task 7's unlock flow, here
    // the unlock above.
    await service.retirePreEncryptionCopy(firmId, key);
    expect(keptPlaintext().existsSync(), isFalse);
    // And it is a no-op the second time, so any caller may call it freely.
    await service.retirePreEncryptionCopy(firmId, key);
    expect(keptPlaintext().existsSync(), isFalse);
  });

  test('recovery neither promotes nor drops when it cannot read the live '
      'file header', () async {
    await seedPlaintextFirm();
    pendingEnvelope().writeAsStringSync('{}');
    // A live file too short to hold a header: nothing can prove whether the
    // swap happened, so nothing may act on either assumption.
    live().writeAsBytesSync(Uint8List.fromList([1, 2, 3]));

    expect(
      await service.recoverInterruptedMigration(firmId),
      RecoveryOutcome.indeterminate,
    );

    expect(await service.isEncrypted(firmId), isFalse);
    expect(envelope().existsSync(), isFalse);
    expect(pendingEnvelope().existsSync(), isTrue);
  });

  test('a retry after an interrupted migration heals it first, then refuses '
      'as already encrypted instead of re-encrypting', () async {
    await seedPlaintextFirm();
    service.afterDatabaseSwapHook = () async =>
        throw const FormatException('simulated crash');
    await expectLater(
      service.migrateToEncrypted(
        firmId,
        passphrase: passphrase,
        onRecoveryCodeGenerated: (_) {},
      ),
      throwsA(isA<FormatException>()),
    );

    // A journal left beside the live path belongs to the plaintext database
    // the swap replaced; the promotion branch has to sweep it just as the
    // crash-free path does.
    final shm = File('${live().path}-shm')..writeAsStringSync('stale');

    service.afterDatabaseSwapHook = null;
    await expectLater(
      service.migrateToEncrypted(
        firmId,
        passphrase: passphrase,
        onRecoveryCodeGenerated: (_) {},
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('already encrypted'),
        ),
      ),
    );
    expect(shm.existsSync(), isFalse);
    expect(await service.isEncrypted(firmId), isTrue);
    final key = await service.unlockWithPassphrase(firmId, passphrase);
    final probe = openKeyed(live(), key!);
    expect(probe.select('SELECT count(*) AS c FROM customers').first['c'], 2);
    probe.close();
  });

  test('a staged envelope beside a still-plaintext database is dropped, not '
      'promoted', () async {
    await seedPlaintextFirm();
    final plaintextBytes = live().readAsBytesSync();
    // The state a crash between staging the envelope and the swap leaves.
    pendingEnvelope().writeAsStringSync('{}');
    scratch().writeAsStringSync('leftover');
    // The header check proves the live file is still plaintext, so this copy
    // is a duplicate of it rather than a safety net.
    keptPlaintext().writeAsBytesSync(plaintextBytes);

    expect(
      await service.recoverInterruptedMigration(firmId),
      RecoveryOutcome.revertedToPlaintext,
    );

    expect(await service.isEncrypted(firmId), isFalse);
    expect(envelope().existsSync(), isFalse);
    expect(pendingEnvelope().existsSync(), isFalse);
    expect(scratch().existsSync(), isFalse);
    expect(keptPlaintext().existsSync(), isFalse);
    expect(live().readAsBytesSync(), plaintextBytes);
  });

  test('the plaintext safety copy survives a revert when the live file is '
      'plaintext but not this firm', () async {
    // The header check that drives this branch proves one thing only: the
    // live file is not ciphertext. It cannot tell the RIGHT plaintext
    // database from a truncated, half-written or unrelated one -- and the
    // copy about to be deleted is the only other copy of the ledger. The
    // live file is plaintext here by that same proof, so the stronger read
    // costs nothing: no key is needed for it.
    await seedPlaintextFirm();
    final goodBytes = live().readAsBytesSync();
    keptPlaintext().writeAsBytesSync(goodBytes);
    pendingEnvelope().writeAsStringSync('{}');
    // A valid, readable SQLite database with a perfect header -- of some
    // other firm entirely.
    final stranger = AppDatabase(NativeDatabase(live()..deleteSync()));
    await FirmSetup(
      stranger,
      DeviceContext(
        firmId: '99999999-9999-4999-8999-999999999999',
        deviceId: '22222222-2222-4222-8222-222222222222',
        deviceShortCode: 'ZZ99',
        userId: '33333333-3333-4333-8333-333333333333',
        hlc: Hlc(clock: () => 1000),
      ),
    ).createFirm(name: 'Someone Else', contactNumber: '0300');
    await stranger.close();

    await service.recoverInterruptedMigration(firmId);

    expect(
      keptPlaintext().existsSync(),
      isTrue,
      reason:
          'the only remaining copy of this firm must not be deleted on '
          'the strength of a 16-byte header',
    );
    expect(keptPlaintext().readAsBytesSync(), goodBytes);
  });

  test('a database that cannot be exported leaves the live file untouched and '
      'the firm unencrypted', () async {
    final garbage = Uint8List.fromList(List.generate(4096, (i) => i % 256));
    live().writeAsBytesSync(garbage);

    await expectLater(
      service.migrateToEncrypted(
        firmId,
        passphrase: passphrase,
        onRecoveryCodeGenerated: (_) => fail('must not reach the envelope'),
      ),
      throwsA(anything),
    );

    expect(live().readAsBytesSync(), garbage);
    expect(await service.isEncrypted(firmId), isFalse);
    expect(keptPlaintext().existsSync(), isFalse);
    expect(scratch().existsSync(), isFalse);
    expect(pendingEnvelope().existsSync(), isFalse);
  });

  test('a database in WAL mode is refused, because the rename-based swap '
      'would strand its -wal beside the ciphertext', () async {
    await seedPlaintextFirm();
    final toWal = raw.sqlite3.open(live().path)
      ..execute('PRAGMA journal_mode = WAL;');
    toWal.close();
    final walBytes = live().readAsBytesSync();

    await expectLater(
      service.migrateToEncrypted(
        firmId,
        passphrase: passphrase,
        onRecoveryCodeGenerated: (_) => fail('must not reach the envelope'),
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('journal mode'),
        ),
      ),
    );

    expect(live().readAsBytesSync(), walBytes);
    expect(await service.isEncrypted(firmId), isFalse);
    expect(scratch().existsSync(), isFalse);
  });

  test('stale journal sidecars do not survive the swap next to the encrypted '
      'file', () async {
    await seedPlaintextFirm();
    final shm = File('${live().path}-shm')..writeAsStringSync('stale');

    await service.migrateToEncrypted(
      firmId,
      passphrase: passphrase,
      onRecoveryCodeGenerated: (_) {},
    );

    expect(shm.existsSync(), isFalse);
    expect(isCiphertext(live()), isTrue);
  });

  test('migrating a firm with no database file at all is refused', () async {
    await expectLater(
      service.migrateToEncrypted(
        firmId,
        passphrase: passphrase,
        onRecoveryCodeGenerated: (_) {},
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('no database file'),
        ),
      ),
    );
    expect(live().existsSync(), isFalse);
  });

  test('retiring the plaintext copy still works long after the firm has moved '
      'on from it', () async {
    final key = await crashMigrateThenRecover();
    expect(keptPlaintext().existsSync(), isTrue);

    // Real use after the migration: a new customer, and a schema version bump
    // of the kind a later drift migration would make. Both make the live file
    // diverge from the frozen `.pre-encryption` snapshot, which is exactly
    // what a row-count/schema comparison would have choked on -- permanently,
    // since there is no way back from that once it starts throwing.
    final keyed = raw.sqlite3.open(live().path)
      ..execute('PRAGMA key = "x\'${hexOf(key)}\'";');
    final db = AppDatabase(NativeDatabase.opened(keyed));
    await CustomersRepository(
      db,
      DeviceContext(
        firmId: firmId,
        deviceId: '22222222-2222-4222-8222-222222222222',
        deviceShortCode: 'A3F9',
        userId: '33333333-3333-4333-8333-333333333333',
        hlc: Hlc(clock: () => 2000),
      ),
    ).create(name: 'Added After Encrypting');
    await db.customStatement('PRAGMA user_version = 2');
    await db.close();

    await service.retirePreEncryptionCopy(firmId, key);
    expect(keptPlaintext().existsSync(), isFalse);

    // The data is all still there, new row included.
    final probe = openKeyed(live(), key);
    expect(probe.select('SELECT count(*) AS c FROM customers').first['c'], 3);
    probe.close();
  });

  test('the plaintext copy is not retired on a key that cannot actually read '
      'the live file', () async {
    await crashMigrateThenRecover();
    final wrongKey = Uint8List.fromList(List.generate(32, (i) => 255 - i));

    await expectLater(
      service.retirePreEncryptionCopy(firmId, wrongKey),
      throwsA(isA<StateError>()),
    );
    expect(keptPlaintext().existsSync(), isTrue);
    expect(isCiphertext(keptPlaintext()), isFalse);
  });

  test('the plaintext copy is not retired when the live file no longer holds '
      'this firm', () async {
    final key = await crashMigrateThenRecover();
    final keyed = raw.sqlite3.open(live().path)
      ..execute('PRAGMA key = "x\'${hexOf(key)}\'";')
      ..execute('DELETE FROM firms');
    keyed.close();

    await expectLater(
      service.retirePreEncryptionCopy(firmId, key),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('no row for firm'),
        ),
      ),
    );
    expect(keptPlaintext().existsSync(), isTrue);
  });

  test('a plaintext copy that cannot be DELETED is reported as exactly that, '
      'not as a database that failed to verify', () async {
    final key = await crashMigrateThenRecover();
    // The live database is fine -- the verification above the delete proves
    // it every time this runs. Only the unlink fails, the way it does against
    // a file an antivirus has open or a volume mounted read-only. A caller
    // cannot tell the two apart from a bare StateError, and the difference
    // decides whether a healthy firm opens at all.
    Process.runSync('chmod', ['555', paths.firms.path]);
    try {
      await expectLater(
        service.retirePreEncryptionCopy(firmId, key),
        throwsA(
          isA<PlaintextCopyNotRetired>().having(
            (e) => e.path,
            'path',
            keptPlaintext().path,
          ),
        ),
      );
      expect(keptPlaintext().existsSync(), isTrue);
    } finally {
      Process.runSync('chmod', ['755', paths.firms.path]);
    }
  }, skip: _cannotBlockUnlink);

  test('a migration whose own plaintext copy vanishes fails loudly rather '
      'than passing as a success', () async {
    await seedPlaintextFirm();
    // The hook fires in the swap-to-promotion window; deleting the sidecar
    // there is the only way this method can reach its own retirement step with
    // nothing to retire.
    service.afterDatabaseSwapHook = () async => keptPlaintext().deleteSync();

    await expectLater(
      service.migrateToEncrypted(
        firmId,
        passphrase: passphrase,
        onRecoveryCodeGenerated: (_) => fail('this is not a success'),
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('disappeared mid-migration'),
        ),
      ),
    );
  });
}
