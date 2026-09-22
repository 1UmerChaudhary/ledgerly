import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

// Re-exported so callers of [unwrapKey] can narrow a catch clause to the
// documented wrong-key failure mode without importing `package:cryptography`
// directly -- that import stays contained to this one file for everything
// else (see [WrappedKey]'s doc comment below), but the exception type itself
// is part of this file's public contract: "throws on a wrong key" is only
// useful to a caller if they can name what it throws.
export 'package:cryptography/cryptography.dart' show SecretBoxAuthenticationError;

/// One AES-GCM-wrapped copy of a key. Structurally identical to
/// [SecretBox]'s three fields -- this exists so callers of this file never
/// import `package:cryptography` directly, keeping the crypto dependency
/// contained to this one file.
class WrappedKey {
  const WrappedKey({required this.nonce, required this.cipherText, required this.mac});
  final List<int> nonce;
  final List<int> cipherText;
  final List<int> mac;
}

/// Argon2id parameters for deriving a wrapping key from a passphrase or a
/// recovery code. Memory cost is the primary security lever (raising
/// iterations helps less than raising memory against GPU/ASIC attacks);
/// these values target roughly 200-500ms on a modest Android phone --
/// annoying is fine for something typed a few times a week, minutes would
/// not be.
const _argon2Memory = 19 * 1024; // 19 MiB, matching OWASP's Argon2id baseline
const _argon2Parallelism = 1;
const _argon2Iterations = 2;
const _argon2HashLength = 32; // AES-256 needs a 32-byte key

Argon2id _kdf() => Argon2id(
  memory: _argon2Memory,
  parallelism: _argon2Parallelism,
  iterations: _argon2Iterations,
  hashLength: _argon2HashLength,
);

/// Derives a 32-byte wrapping key from a passphrase or recovery-code secret
/// and a salt. The same [secret] and [salt] always derive the same bytes --
/// callers store the salt (not secret) alongside the wrapped key so the
/// same derivation can be repeated at unlock time.
Future<Uint8List> deriveWrappingKey(String secret, {required List<int> salt}) async {
  final secretKey = await _kdf().deriveKeyFromPassword(password: secret, nonce: salt);
  return Uint8List.fromList(await secretKey.extractBytes());
}

/// Encrypts [keyToWrap] (expected to be a 32-byte master key, but this
/// function doesn't care about length) under [wrappingKeyBytes], with a
/// fresh random nonce every call -- reusing a nonce with the same wrapping
/// key is the one AES-GCM mistake that actually breaks the cipher, so this
/// is never left to a caller to remember.
Future<WrappedKey> wrapKey(Uint8List keyToWrap, {required Uint8List wrappingKeyBytes}) async {
  final algorithm = AesGcm.with256bits();
  final wrappingKey = SecretKey(wrappingKeyBytes);
  final box = await algorithm.encrypt(keyToWrap, secretKey: wrappingKey);
  return WrappedKey(nonce: box.nonce, cipherText: box.cipherText, mac: box.mac.bytes);
}

/// Decrypts a [WrappedKey] back to the original bytes passed to [wrapKey].
/// Throws (a [SecretBoxAuthenticationError] from `package:cryptography`) if
/// [wrappingKeyBytes] is wrong -- AES-GCM's authentication tag means a wrong
/// key is detected here, not discovered later as garbage decrypted bytes.
Future<Uint8List> unwrapKey(WrappedKey wrapped, {required Uint8List wrappingKeyBytes}) async {
  final algorithm = AesGcm.with256bits();
  final wrappingKey = SecretKey(wrappingKeyBytes);
  final box = SecretBox(wrapped.cipherText, nonce: wrapped.nonce, mac: Mac(wrapped.mac));
  final clear = await algorithm.decrypt(box, secretKey: wrappingKey);
  return Uint8List.fromList(clear);
}
