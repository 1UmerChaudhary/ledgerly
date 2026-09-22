import 'dart:math';
import 'dart:typed_data';

import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../../bootstrap/app_paths.dart';

/// The logic layer for passphrase encryption: generating/wrapping the master
/// key, unlocking via either path, and changing either secret independently.
/// UI screens call this, never Tasks 1-4's lower-level pieces directly.
class EncryptionService {
  EncryptionService({required this.paths});
  final AppPaths paths;

  final _random = Random.secure();

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
  }) async {
    final masterKey = _randomBytes(32);
    final recoverySecret = _randomBytes(32);
    final recoveryCode = encodeRecoveryCode(recoverySecret);

    final passphraseSalt = _randomBytes(16);
    final recoveryCodeSalt = _randomBytes(16);
    final passphraseWrappingKey = await deriveWrappingKey(
      passphrase,
      salt: passphraseSalt,
    );
    final recoveryWrappingKey = await deriveWrappingKey(
      encodeRecoveryCode(
        recoverySecret,
      ), // the code itself is the "secret" for its own KDF
      salt: recoveryCodeSalt,
    );

    final envelope = KeyEnvelope(
      byPassphrase: await wrapKey(
        masterKey,
        wrappingKeyBytes: passphraseWrappingKey,
      ),
      passphraseSalt: passphraseSalt,
      byRecoveryCode: await wrapKey(
        masterKey,
        wrappingKeyBytes: recoveryWrappingKey,
      ),
      recoveryCodeSalt: recoveryCodeSalt,
    );
    await _storeFor(firmId).write(envelope);
    onRecoveryCodeGenerated(recoveryCode);
  }

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
    } catch (_) {
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
    } catch (_) {
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
