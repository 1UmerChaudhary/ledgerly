import 'dart:typed_data';

// Crockford's base32 alphabet -- deliberately excludes I, L, O, U to avoid
// visual confusion with 1, 1, 0, V on a printed or handwritten sheet.
const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
// The check-symbol alphabet extends the above with 7 more symbols, per
// Crockford's spec, giving a mod-37 check digit.
const _checkAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ*~\$=U';

int _valueOf(String char) {
  final upper = char.toUpperCase();
  switch (upper) {
    case 'O':
      return _alphabet.indexOf('0');
    case 'I':
    case 'L':
      return _alphabet.indexOf('1');
    default:
      return _alphabet.indexOf(upper);
  }
}

/// Encodes [secretBytes] as a human-typeable Crockford base32 string, grouped
/// in 4-character blocks with a trailing check symbol, e.g. "XM4K-9QRT-...-7".
String encodeRecoveryCode(Uint8List secretBytes) {
  // Standard base-32 bit-packing: accumulate bits, emit 5 at a time.
  var buffer = 0;
  var bitsInBuffer = 0;
  final chars = <String>[];
  for (final byte in secretBytes) {
    buffer = (buffer << 8) | byte;
    bitsInBuffer += 8;
    while (bitsInBuffer >= 5) {
      bitsInBuffer -= 5;
      chars.add(_alphabet[(buffer >> bitsInBuffer) & 0x1F]);
    }
  }
  if (bitsInBuffer > 0) {
    chars.add(_alphabet[(buffer << (5 - bitsInBuffer)) & 0x1F]);
  }

  // Mod-37 check symbol over the numeric value of the whole string, per
  // Crockford's check-symbol scheme.
  var checkValue = 0;
  for (final c in chars) {
    checkValue = (checkValue * 32 + _alphabet.indexOf(c)) % 37;
  }
  chars.add(_checkAlphabet[checkValue]);

  final joined = chars.join();
  final grouped = <String>[];
  for (var i = 0; i < joined.length; i += 4) {
    grouped.add(joined.substring(i, i + 4 > joined.length ? joined.length : i + 4));
  }
  return grouped.join('-');
}

/// Decodes a recovery code produced by [encodeRecoveryCode]. Returns `null`
/// (never throws) for anything that fails the check symbol or contains a
/// character outside the accepted alphabet -- the UI needs "that code isn't
/// right" as data, not an exception to catch.
Uint8List? decodeRecoveryCode(String input) {
  final cleaned = input.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
  if (cleaned.isEmpty) return null;
  final body = cleaned.substring(0, cleaned.length - 1);
  final checkChar = cleaned[cleaned.length - 1];

  var checkValue = 0;
  for (final c in body.split('')) {
    final v = _valueOf(c);
    if (v == -1) return null;
    checkValue = (checkValue * 32 + v) % 37;
  }
  if (_checkAlphabet.indexOf(checkChar) != checkValue) return null;

  var buffer = 0;
  var bitsInBuffer = 0;
  final bytes = <int>[];
  for (final c in body.split('')) {
    final v = _valueOf(c);
    buffer = (buffer << 5) | v;
    bitsInBuffer += 5;
    if (bitsInBuffer >= 8) {
      bitsInBuffer -= 8;
      bytes.add((buffer >> bitsInBuffer) & 0xFF);
    }
  }
  return Uint8List.fromList(bytes);
}
