import 'dart:typed_data';

// Crockford's base32 alphabet -- deliberately excludes I, L, O, U to avoid
// visual confusion with 1, 1, 0, V on a printed or handwritten sheet.
const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
// The check-symbol alphabet extends the above with 5 more symbols, per
// Crockford's spec, giving a mod-37 check digit.
const _checkAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ*~\$=U';

/// Crockford's look-alike folding, applied before any lookup: a handwritten
/// `O` means `0`, and `I` or `L` means `1`. The whole reason for this alphabet
/// is that a character copied off a sheet by hand cannot be misread as
/// another, so the folding has to reach every position that gets copied --
/// the check symbol included.
String _fold(String char) {
  final upper = char.toUpperCase();
  return switch (upper) {
    'O' => '0',
    'I' || 'L' => '1',
    _ => upper,
  };
}

int _valueOf(String char) => _alphabet.indexOf(_fold(char));

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
    grouped.add(
      joined.substring(i, i + 4 > joined.length ? joined.length : i + 4),
    );
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
  // Folded like every other position. Without this the check symbol is the
  // one character a user can copy the way Crockford's alphabet expects and
  // still be told their correct code is invalid -- and it is the character
  // most often written down alone, after the last dash.
  if (_checkAlphabet.indexOf(_fold(checkChar)) != checkValue) return null;

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

/// The code exactly as [encodeRecoveryCode] printed it, given anything a user
/// might reasonably have typed off the sheet -- lower case, spaces instead of
/// dashes, no separators at all, `O` for `0`, `I`/`L` for `1`. Returns null
/// for input that is not a valid recovery code at all.
///
/// This exists because unlocking hashes the code STRING, not the bytes it
/// decodes to: the KDF that unwraps the master key is fed the code as typed,
/// so `xm4k-...` and `XM4K-...` derive two different wrapping keys even though
/// both decode to the same secret. Every UI that accepts a typed recovery code
/// must put it through here first -- without it a user holding the correct
/// printed sheet is told their correct code is wrong.
String? canonicaliseRecoveryCode(String input) {
  final secretBytes = decodeRecoveryCode(input);
  if (secretBytes == null) return null;
  return encodeRecoveryCode(secretBytes);
}
