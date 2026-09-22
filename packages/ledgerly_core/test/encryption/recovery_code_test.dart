import 'dart:typed_data';

import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:test/test.dart';

void main() {
  test('a recovery code round-trips through encode then decode', () {
    final secret = Uint8List.fromList(List.generate(32, (i) => i * 7 % 256));
    final code = encodeRecoveryCode(secret);
    expect(decodeRecoveryCode(code), equals(secret));
  });

  test('decoding is case-insensitive and ignores the grouping dashes', () {
    final secret = Uint8List.fromList(List.generate(32, (i) => i));
    final code = encodeRecoveryCode(secret);
    final messy = code.toLowerCase().replaceAll('-', ' ');
    expect(decodeRecoveryCode(messy), equals(secret));
  });

  test('a single mistyped character is rejected, not silently decoded to a different key', () {
    final secret = Uint8List.fromList(List.generate(32, (i) => i));
    final code = encodeRecoveryCode(secret);
    final typo = code.substring(0, code.length - 2) +
        (code[code.length - 2] == 'A' ? 'B' : 'A') +
        code[code.length - 1];
    expect(decodeRecoveryCode(typo), isNull);
  });

  test('garbage input decodes to null instead of throwing', () {
    expect(decodeRecoveryCode('not a real code'), isNull);
  });
}
