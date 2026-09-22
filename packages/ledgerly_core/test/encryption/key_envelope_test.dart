import 'dart:typed_data';

import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:test/test.dart';

void main() {
  test('a key wrapped and unwrapped with the same wrapping key round-trips exactly', () async {
    final masterKey = Uint8List.fromList(List.generate(32, (i) => i));
    final salt = List.generate(16, (i) => i * 3);
    final wrappingKey = await deriveWrappingKey('correct horse battery staple', salt: salt);

    final wrapped = await wrapKey(masterKey, wrappingKeyBytes: wrappingKey);
    final unwrapped = await unwrapKey(wrapped, wrappingKeyBytes: wrappingKey);

    expect(unwrapped, equals(masterKey));
  });

  test('the same secret and salt always derive the same wrapping key', () async {
    final salt = List.generate(16, (i) => i);
    final a = await deriveWrappingKey('same passphrase', salt: salt);
    final b = await deriveWrappingKey('same passphrase', salt: salt);
    expect(a, equals(b));
  });

  test('a different salt derives a different wrapping key from the same secret', () async {
    final a = await deriveWrappingKey('same passphrase', salt: List.filled(16, 1));
    final b = await deriveWrappingKey('same passphrase', salt: List.filled(16, 2));
    expect(a, isNot(equals(b)));
  });

  test('unwrapping with the wrong wrapping key throws instead of returning garbage bytes', () async {
    final masterKey = Uint8List.fromList(List.generate(32, (i) => i));
    final salt = List.generate(16, (i) => i);
    final rightKey = await deriveWrappingKey('right passphrase', salt: salt);
    final wrongKey = await deriveWrappingKey('wrong passphrase', salt: salt);
    final wrapped = await wrapKey(masterKey, wrappingKeyBytes: rightKey);

    expect(
      () => unwrapKey(wrapped, wrappingKeyBytes: wrongKey),
      throwsA(anything),
    );
  });

  test('wrapping the same key twice produces different ciphertext (fresh nonce each time)', () async {
    final masterKey = Uint8List.fromList(List.generate(32, (i) => i));
    final wrappingKey = await deriveWrappingKey('x', salt: List.filled(16, 0));
    final first = await wrapKey(masterKey, wrappingKeyBytes: wrappingKey);
    final second = await wrapKey(masterKey, wrappingKeyBytes: wrappingKey);
    expect(first.nonce, isNot(equals(second.nonce)));
  });
}
