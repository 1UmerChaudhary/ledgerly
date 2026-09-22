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
      mutatedCode.add(
        mutatedRaw.substring(
          i,
          i + 4 > mutatedRaw.length ? mutatedRaw.length : i + 4,
        ),
      );
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
      mutatedCode.add(
        mutatedRaw.substring(
          i,
          i + 4 > mutatedRaw.length ? mutatedRaw.length : i + 4,
        ),
      );
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

  group('canonicaliseRecoveryCode', () {
    test('a code typed in lower case, without dashes, canonicalises back to '
        'the exact string encodeRecoveryCode printed', () {
      final secret = Uint8List.fromList(List.generate(32, (i) => i * 7 % 256));
      final printed = encodeRecoveryCode(secret);
      final asTyped = printed.toLowerCase().replaceAll('-', ' ');
      expect(canonicaliseRecoveryCode(asTyped), printed);
    });

    test(
      'Crockford\'s confusable letters fold to the digits they look like',
      () {
        final secret = Uint8List.fromList(List.generate(32, (i) => i));
        final printed = encodeRecoveryCode(secret);
        // A user copying off a printed sheet types O for 0 and I for 1; the
        // canonical form they get back is the code as printed. Only the body
        // is folded -- the trailing check symbol has its own alphabet.
        final raw = printed.replaceAll('-', '');
        final asTyped =
            raw
                .substring(0, raw.length - 1)
                .replaceAll('0', 'O')
                .replaceAll('1', 'I') +
            raw[raw.length - 1];
        expect(canonicaliseRecoveryCode(asTyped), printed);
      },
    );

    test('an already-canonical code is returned unchanged', () {
      final printed = encodeRecoveryCode(
        Uint8List.fromList(List.generate(32, (i) => 255 - i)),
      );
      expect(canonicaliseRecoveryCode(printed), printed);
    });

    test('a code that fails its check symbol canonicalises to null', () {
      expect(canonicaliseRecoveryCode('XXXX-XXXX-XXXX'), isNull);
      expect(canonicaliseRecoveryCode(''), isNull);
      expect(canonicaliseRecoveryCode('not a real code'), isNull);
    });
  });

  test('the check symbol folds the same look-alikes the body does: a 0 '
      'transcribed as O is still the right code', () {
    // Crockford's alphabet exists precisely so a hand-copied character
    // cannot be misread as another one. The body honoured that and the
    // check symbol did not, which made the single position most likely to
    // be written down on its own -- the one after the last dash -- the one
    // position where the confusion it was designed to prevent still
    // rejected a correct code.
    var folded = 0;
    for (var seed = 0; seed < 40; seed++) {
      final code = encodeRecoveryCode(
        Uint8List.fromList(List.generate(32, (i) => (seed * 31 + i) % 256)),
      );
      final checkChar = code[code.length - 1];
      const lookAlikes = {'0': 'O', '1': 'I'};
      final typed = lookAlikes[checkChar];
      if (typed == null) continue;
      folded++;
      expect(
        decodeRecoveryCode(code.substring(0, code.length - 1) + typed),
        isNotNull,
        reason: '$checkChar written as $typed must still decode',
      );
    }
    expect(folded, greaterThan(0), reason: 'no foldable check symbol tried');
  });

  test('a check symbol that is genuinely wrong is still rejected', () {
    final code = encodeRecoveryCode(
      Uint8List.fromList(List.generate(32, (i) => i)),
    );
    final checkChar = code[code.length - 1];
    final wrong = checkChar == 'Z' ? 'Y' : 'Z';
    expect(
      decodeRecoveryCode(code.substring(0, code.length - 1) + wrong),
      isNull,
    );
  });
}
