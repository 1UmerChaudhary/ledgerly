import 'dart:io';

import 'package:ledgerly/bootstrap/app_paths.dart';
import 'package:ledgerly/features/encryption/encryption_service.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late AppPaths paths;
  const firmId = 'test-firm';

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('encryption_service_test');
    paths = AppPaths(tmp);
    await paths.firms.create(recursive: true);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('enabling encryption returns a working recovery code, and the passphrase unlocks', () async {
    final service = EncryptionService(paths: paths);
    String? recoveryCode;
    await service.enableEncryption(
      firmId,
      passphrase: 'correct horse battery staple',
      onRecoveryCodeGenerated: (code) => recoveryCode = code,
    );

    expect(recoveryCode, isNotNull);
    expect(await service.isEncrypted(firmId), isTrue);

    final unlocked = await service.unlockWithPassphrase(
      firmId,
      'correct horse battery staple',
    );
    expect(unlocked, isNotNull);
  });

  test('a wrong passphrase fails closed (returns null, not a key)', () async {
    final service = EncryptionService(paths: paths);
    await service.enableEncryption(
      firmId,
      passphrase: 'right one',
      onRecoveryCodeGenerated: (_) {},
    );
    expect(await service.unlockWithPassphrase(firmId, 'wrong one'), isNull);
  });

  test(
    'the recovery code unlocks to the exact same master key as the passphrase',
    () async {
      final service = EncryptionService(paths: paths);
      String? recoveryCode;
      await service.enableEncryption(
        firmId,
        passphrase: 'a passphrase',
        onRecoveryCodeGenerated: (code) => recoveryCode = code,
      );

      final viaPassphrase = await service.unlockWithPassphrase(
        firmId,
        'a passphrase',
      );
      final viaRecovery = await service.unlockWithRecoveryCode(
        firmId,
        recoveryCode!,
      );
      expect(viaRecovery, equals(viaPassphrase));
    },
  );

  test('a wrong recovery code fails closed', () async {
    final service = EncryptionService(paths: paths);
    await service.enableEncryption(
      firmId,
      passphrase: 'x',
      onRecoveryCodeGenerated: (_) {},
    );
    expect(
      await service.unlockWithRecoveryCode(firmId, 'XXXX-XXXX-XXXX-XXXX-X'),
      isNull,
    );
  });

  test('changing the passphrase: old passphrase stops working, new one works, recovery code unchanged', () async {
    final service = EncryptionService(paths: paths);
    String? recoveryCode;
    await service.enableEncryption(
      firmId,
      passphrase: 'old passphrase',
      onRecoveryCodeGenerated: (code) => recoveryCode = code,
    );
    final masterKey = (await service.unlockWithPassphrase(
      firmId,
      'old passphrase',
    ))!;

    await service.changePassphrase(
      firmId,
      masterKey: masterKey,
      newPassphrase: 'new passphrase',
    );

    expect(
      await service.unlockWithPassphrase(firmId, 'old passphrase'),
      isNull,
    );
    final viaNew = await service.unlockWithPassphrase(firmId, 'new passphrase');
    expect(viaNew, equals(masterKey));
    final viaRecovery = await service.unlockWithRecoveryCode(
      firmId,
      recoveryCode!,
    );
    expect(
      viaRecovery,
      equals(masterKey),
      reason: 'recovery code must survive a passphrase change',
    );
  });

  test(
    'rotating the recovery code invalidates the old one and the new one works',
    () async {
      final service = EncryptionService(paths: paths);
      String? oldCode;
      await service.enableEncryption(
        firmId,
        passphrase: 'p',
        onRecoveryCodeGenerated: (code) => oldCode = code,
      );
      final masterKey = (await service.unlockWithPassphrase(firmId, 'p'))!;

      final newCode = await service.rotateRecoveryCode(
        firmId,
        masterKey: masterKey,
      );

      expect(await service.unlockWithRecoveryCode(firmId, oldCode!), isNull);
      expect(
        await service.unlockWithRecoveryCode(firmId, newCode),
        equals(masterKey),
      );
      expect(
        await service.unlockWithPassphrase(firmId, 'p'),
        equals(masterKey),
        reason: 'passphrase must survive a recovery-code rotation',
      );
    },
  );

  test('a firm with no envelope file is reported as not encrypted', () async {
    final service = EncryptionService(paths: paths);
    expect(await service.isEncrypted(firmId), isFalse);
  });
}
