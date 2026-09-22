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

  test('a single mistyped character in the data body is rejected', () {
    final secret = Uint8List.fromList(List.generate(32, (i) => i));
    final code = encodeRecoveryCode(secret);
    // Strip grouping dashes to get the raw encoded + check string
    final raw = code.replaceAll('-', '');
    // Mutate the first data character (index 0) to a different valid alphabet char
    final originalChar = raw[0];
    final newChar = originalChar == '0' ? '1' : '0';
    final mutatedRaw = newChar + raw.substring(1);
    // Re-group for realism (though decodeRecoveryCode handles ungrouped input)
    final mutatedCode = <String>[];
    for (var i = 0; i < mutatedRaw.length; i += 4) {
      mutatedCode.add(mutatedRaw.substring(
          i, i + 4 > mutatedRaw.length ? mutatedRaw.length : i + 4));
    }
    final mutatedGrouped = mutatedCode.join('-');
    expect(decodeRecoveryCode(mutatedGrouped), isNull);
  });

  test('a mutated check symbol is rejected', () {
    final secret = Uint8List.fromList(List.generate(32, (i) => i));
    final code = encodeRecoveryCode(secret);
    // The last character is the check symbol; mutate it
    final raw = code.replaceAll('-', '');
    final lastChar = raw[raw.length - 1];
    final newLastChar = lastChar == '0' ? '1' : '0';
    final mutatedRaw = raw.substring(0, raw.length - 1) + newLastChar;
    // Re-group
    final mutatedCode = <String>[];
    for (var i = 0; i < mutatedRaw.length; i += 4) {
      mutatedCode.add(mutatedRaw.substring(
          i, i + 4 > mutatedRaw.length ? mutatedRaw.length : i + 4));
    }
    final mutatedGrouped = mutatedCode.join('-');
    expect(decodeRecoveryCode(mutatedGrouped), isNull);
  });

  test('garbage input with out-of-alphabet characters decodes to null', () {
    expect(decodeRecoveryCode('XXXX-XXXX!'), isNull);
  });

  test('garbage input decodes to null instead of throwing', () {
    expect(decodeRecoveryCode('not a real code'), isNull);
  });
}
