# Phase 2 Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close out passphrase encryption + recovery code, Google sign-in (Android-only), silent
401 token refresh, and eight smaller items, finishing what Phase 2 of Ledgerly deferred.

**Architecture:** Encryption uses envelope encryption with two independent wraps of one random
master key (passphrase-derived and recovery-code-derived), stored in a plaintext sidecar file next
to each firm's database — never inside it. SQLCipher receives the master key directly as a raw hex
key, never a passphrase. Google sign-in adds one unified backend endpoint mirroring the existing
register/login split, gated to Android on the app side (the plugin has no desktop support). Token
refresh gets a single-flight guard around the existing (already-built) refresh endpoint.

**Tech Stack:** Flutter/Dart (drift, `package:cryptography` — new dependency), FastAPI/SQLAlchemy
(Postgres), `google_sign_in: ^7.2.0` (new app dependency), `google-auth` (already a backend
dependency, unused until now).

**Spec:** `docs/superpowers/specs/2026-09-22-phase2-completion-design.md` — read this first. It
carries the reasoning and the two independent design reviews' findings this plan is built from;
this plan restates only what each task needs, not the full rationale.

## Global Constraints

- Encryption is the highest-stakes work in this codebase — a design or implementation mistake can
  permanently lock the user out of real financial ledger data. Every encryption task's tests must
  include a "fail closed" case (wrong input never partially succeeds) and, where relevant, a
  simulated-crash case (a write interrupted partway never corrupts the only working copy).
- The key envelope lives in a plaintext sidecar file beside each firm's `.db` file — **never** in
  `app_settings`, `GlobalPrefs`, or any table inside the encrypted database itself. This is the
  exact defect two independent reviews found in the first draft of this spec.
- SQLCipher receives `masterKey` only as a raw hex key (`PRAGMA key = "x'<64 hex chars>'"`),
  never a passphrase string. SQLCipher's own built-in passphrase KDF is never used.
- `package:cryptography` is the only new crypto dependency. Use `Argon2id` for the passphrase KDF
  (parameters specified in Task 1); `AesGcm.with256bits()` for wrapping.
- Google sign-in ships Android-only this round (`Platform.isAndroid` gates the UI). No Windows/
  desktop OAuth flow in this round — that's explicitly out of scope, not silently dropped.
- No new Alembic migration is needed anywhere in this plan — `google_sub` already exists on
  `users` with a unique constraint (`migrations/versions/f537e6a2a3d5_...py:60`).
- Every new widget/route follows this codebase's existing `Key('domain.widget')` convention and
  the established `LayoutBuilder`/`kCompactBreakpoint` compact-vs-wide pattern from the Android
  effort, for anything that needs a phone-width treatment.

---

## Task 1: Crypto primitives — KDF and envelope wrap/unwrap (pure Dart, no I/O)

**Files:**
- Create: `packages/ledgerly_core/lib/src/encryption/key_envelope.dart`
- Modify: `packages/ledgerly_core/lib/ledgerly_core.dart` (export the new file)
- Modify: `packages/ledgerly_core/pubspec.yaml` (add `cryptography: ^2.9.0`)
- Test: `packages/ledgerly_core/test/encryption/key_envelope_test.dart`

**Interfaces:**
- Produces: `Future<Uint8List> deriveWrappingKey(String secret, {required List<int> salt})`,
  `Future<WrappedKey> wrapKey(Uint8List keyToWrap, {required Uint8List wrappingKeyBytes})`,
  `Future<Uint8List> unwrapKey(WrappedKey wrapped, {required Uint8List wrappingKeyBytes})`,
  `class WrappedKey { final List<int> nonce; final List<int> cipherText; final List<int> mac; }`
  (a plain data holder, no crypto logic of its own — matches `SecretBox`'s three fields exactly so
  conversion is a one-line mapping in each direction).
- Consumes: nothing from other tasks — this is the foundation everything else builds on.

This task is pure logic with no filesystem, no SQLite, no UI — the correctness of everything else
in the encryption feature rests on this file being right, so it gets the tightest possible test
loop.

- [ ] **Step 1: Write the failing tests**

```dart
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/ledgerly_core && dart test test/encryption/key_envelope_test.dart`
Expected: FAIL — none of `deriveWrappingKey`/`wrapKey`/`unwrapKey`/`WrappedKey` exist yet.

- [ ] **Step 3: Write minimal implementation**

Add `cryptography: ^2.9.0` to `packages/ledgerly_core/pubspec.yaml`'s `dependencies:`, then run
`dart pub get` in that package.

Create `packages/ledgerly_core/lib/src/encryption/key_envelope.dart`:

```dart
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

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
```

Add the export to `packages/ledgerly_core/lib/ledgerly_core.dart` — open it, find the existing
export list, add:

```dart
export 'src/encryption/key_envelope.dart';
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/ledgerly_core && dart test test/encryption/key_envelope_test.dart`
Expected: PASS. Then `dart test` (whole package) to confirm nothing else broke.

- [ ] **Step 5: Commit**

```bash
git add packages/ledgerly_core/lib/src/encryption/key_envelope.dart packages/ledgerly_core/lib/ledgerly_core.dart packages/ledgerly_core/pubspec.yaml packages/ledgerly_core/pubspec.lock packages/ledgerly_core/test/encryption/key_envelope_test.dart
git commit -m "Encryption: KDF + AES-GCM wrap/unwrap primitives (pure Dart, no I/O)"
```

---

## Task 2: Recovery code encoding (Crockford base32 with a check symbol)

**Files:**
- Create: `packages/ledgerly_core/lib/src/encryption/recovery_code.dart`
- Modify: `packages/ledgerly_core/lib/ledgerly_core.dart` (export)
- Test: `packages/ledgerly_core/test/encryption/recovery_code_test.dart`

**Interfaces:**
- Consumes: nothing (independent of Task 1, but part of the same feature).
- Produces: `String encodeRecoveryCode(Uint8List secretBytes)` (formatted, grouped, with a
  trailing check symbol), `Uint8List? decodeRecoveryCode(String input)` (returns `null` — not a
  throw — for anything that fails Crockford's check-symbol validation, since the caller needs to
  show "that code isn't valid" rather than crash).

Crockford base32 folds visually ambiguous characters (`O`→`0`, `I`/`L`→`1`) case-insensitively and
defines a mod-37 check symbol appended to the encoded value — this means a single mistyped
character from a handwritten or printed sheet is detected as "invalid code," not silently accepted
as a different, wrong key.

- [ ] **Step 1: Write the failing tests**

```dart
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/ledgerly_core && dart test test/encryption/recovery_code_test.dart`
Expected: FAIL — `encodeRecoveryCode`/`decodeRecoveryCode` undefined.

- [ ] **Step 3: Write minimal implementation**

Create `packages/ledgerly_core/lib/src/encryption/recovery_code.dart`:

```dart
import 'dart:typed_data';

// Crockford's base32 alphabet -- deliberately excludes I, L, O, U to avoid
// visual confusion with 1, 1, 0, V on a printed or handwritten sheet.
const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
// The check-symbol alphabet extends the above with 7 more symbols, per
// Crockford's spec, giving a mod-37 check digit.
const _checkAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ*~$=U';

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
```

Add the export to `packages/ledgerly_core/lib/ledgerly_core.dart`:

```dart
export 'src/encryption/recovery_code.dart';
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/ledgerly_core && dart test test/encryption/recovery_code_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/ledgerly_core/lib/src/encryption/recovery_code.dart packages/ledgerly_core/lib/ledgerly_core.dart packages/ledgerly_core/test/encryption/recovery_code_test.dart
git commit -m "Encryption: Crockford base32 recovery-code encoding with a check symbol"
```

---

## Task 3: Envelope file format + atomic read/write

**Files:**
- Create: `packages/ledgerly_data/lib/src/encryption/key_envelope_store.dart`
- Modify: `packages/ledgerly_data/lib/ledgerly_data.dart` (export)
- Modify: `packages/ledgerly_data/pubspec.yaml` (add `cryptography: ^2.9.0` — needed here too,
  since this file constructs `WrappedKey`/calls the Task 1 functions, and `ledgerly_data` doesn't
  transitively re-export `ledgerly_core`'s third-party dependencies)
- Test: `packages/ledgerly_data/test/encryption/key_envelope_store_test.dart`

**Interfaces:**
- Consumes: `WrappedKey`, `wrapKey`, `unwrapKey`, `deriveWrappingKey` (Task 1, from
  `ledgerly_core`).
- Produces: `class KeyEnvelope { final WrappedKey byPassphrase; final List<int> passphraseSalt; final WrappedKey byRecoveryCode; final List<int> recoveryCodeSalt; }`,
  `class KeyEnvelopeStore { KeyEnvelopeStore(File path); Future<KeyEnvelope?> read(); Future<void> write(KeyEnvelope envelope); }`.
  `KeyEnvelope`/`KeyEnvelopeStore` handle JSON (de)serialization and the atomic-write dance;
  callers never touch file paths or JSON directly.

- [ ] **Step 1: Write the failing tests**

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('envelope_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  KeyEnvelope makeEnvelope() => KeyEnvelope(
    byPassphrase: const WrappedKey(nonce: [1, 2, 3], cipherText: [4, 5, 6], mac: [7, 8, 9]),
    passphraseSalt: [10, 11, 12],
    byRecoveryCode: const WrappedKey(nonce: [13, 14], cipherText: [15, 16], mac: [17, 18]),
    recoveryCodeSalt: [19, 20],
  );

  test('a written envelope reads back with identical field values', () async {
    final store = KeyEnvelopeStore(File('${tmp.path}/firm.key.json'));
    final envelope = makeEnvelope();

    await store.write(envelope);
    final readBack = await store.read();

    expect(readBack, isNotNull);
    expect(readBack!.byPassphrase.nonce, envelope.byPassphrase.nonce);
    expect(readBack.byPassphrase.cipherText, envelope.byPassphrase.cipherText);
    expect(readBack.byPassphrase.mac, envelope.byPassphrase.mac);
    expect(readBack.passphraseSalt, envelope.passphraseSalt);
    expect(readBack.byRecoveryCode.nonce, envelope.byRecoveryCode.nonce);
    expect(readBack.recoveryCodeSalt, envelope.recoveryCodeSalt);
  });

  test('reading a path with no envelope file returns null, not an exception', () async {
    final store = KeyEnvelopeStore(File('${tmp.path}/nothing-here.key.json'));
    expect(await store.read(), isNull);
  });

  test('writing twice replaces the file cleanly (no leftover .tmp)', () async {
    final store = KeyEnvelopeStore(File('${tmp.path}/firm.key.json'));
    await store.write(makeEnvelope());
    await store.write(makeEnvelope());
    final leftovers = tmp.listSync().where((f) => f.path.endsWith('.tmp'));
    expect(leftovers, isEmpty);
  });

  test('a previous envelope is preserved as a .bak file after a second write', () async {
    final store = KeyEnvelopeStore(File('${tmp.path}/firm.key.json'));
    await store.write(makeEnvelope());
    await store.write(makeEnvelope());
    expect(File('${tmp.path}/firm.key.json.bak').existsSync(), isTrue);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/ledgerly_data && dart test test/encryption/key_envelope_store_test.dart`
Expected: FAIL — `KeyEnvelope`/`KeyEnvelopeStore` undefined.

- [ ] **Step 3: Write minimal implementation**

Add `cryptography: ^2.9.0` to `packages/ledgerly_data/pubspec.yaml`'s `dependencies:`, run
`dart pub get`.

Create `packages/ledgerly_data/lib/src/encryption/key_envelope_store.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:ledgerly_core/ledgerly_core.dart';

/// Both wrapped copies of a firm's master key, plus the salts needed to
/// re-derive each wrapping key at unlock time. This is the entire content of
/// a `<firmId>.key.json` sidecar file -- plaintext on disk by design (its
/// contents are useless without the passphrase or recovery code, and it must
/// be readable *before* the encrypted database can be opened).
class KeyEnvelope {
  const KeyEnvelope({
    required this.byPassphrase,
    required this.passphraseSalt,
    required this.byRecoveryCode,
    required this.recoveryCodeSalt,
  });

  final WrappedKey byPassphrase;
  final List<int> passphraseSalt;
  final WrappedKey byRecoveryCode;
  final List<int> recoveryCodeSalt;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'by_passphrase': _wrappedToJson(byPassphrase),
    'passphrase_salt': passphraseSalt,
    'by_recovery_code': _wrappedToJson(byRecoveryCode),
    'recovery_code_salt': recoveryCodeSalt,
  };

  static Map<String, dynamic> _wrappedToJson(WrappedKey w) =>
      {'nonce': w.nonce, 'cipher_text': w.cipherText, 'mac': w.mac};

  static WrappedKey _wrappedFromJson(Map<String, dynamic> j) => WrappedKey(
    nonce: (j['nonce'] as List).cast<int>(),
    cipherText: (j['cipher_text'] as List).cast<int>(),
    mac: (j['mac'] as List).cast<int>(),
  );

  static KeyEnvelope fromJson(Map<String, dynamic> j) => KeyEnvelope(
    byPassphrase: _wrappedFromJson(j['by_passphrase'] as Map<String, dynamic>),
    passphraseSalt: (j['passphrase_salt'] as List).cast<int>(),
    byRecoveryCode: _wrappedFromJson(j['by_recovery_code'] as Map<String, dynamic>),
    recoveryCodeSalt: (j['recovery_code_salt'] as List).cast<int>(),
  );
}

/// Reads/writes a [KeyEnvelope] to a plaintext sidecar file, atomically.
/// Every write goes to a `.tmp` file first, then the *previous* file (if any)
/// is preserved as `.bak` before the new one is renamed into place -- a crash
/// mid-write leaves either the old envelope (still openable with the old
/// passphrase/recovery code) or the fully-written new one, never a half
/// -written file that opens with neither.
class KeyEnvelopeStore {
  KeyEnvelopeStore(this.path);
  final File path;

  Future<KeyEnvelope?> read() async {
    if (!await path.exists()) return null;
    final text = await path.readAsString();
    return KeyEnvelope.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  Future<void> write(KeyEnvelope envelope) async {
    final tmp = File('${path.path}.tmp');
    await tmp.writeAsString(jsonEncode(envelope.toJson()), flush: true);
    final backup = File('${path.path}.bak');
    if (await path.exists()) {
      if (await backup.exists()) await backup.delete();
      await path.rename(backup.path);
    }
    await tmp.rename(path.path);
  }
}
```

Add the export to `packages/ledgerly_data/lib/ledgerly_data.dart`:

```dart
export 'src/encryption/key_envelope_store.dart';
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/ledgerly_data && dart test test/encryption/key_envelope_store_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/ledgerly_data/lib/src/encryption/key_envelope_store.dart packages/ledgerly_data/lib/ledgerly_data.dart packages/ledgerly_data/pubspec.yaml packages/ledgerly_data/pubspec.lock packages/ledgerly_data/test/encryption/key_envelope_store_test.dart
git commit -m "Encryption: atomic envelope sidecar file read/write"
```

---

## Task 4: Keyed database opening + AppPaths sidecar path

**Files:**
- Modify: `app/lib/bootstrap/app_paths.dart` — add `firmKeyEnvelope(firmId)`.
- Modify: `app/lib/bootstrap/providers.dart` — key-aware `databaseOpenerProvider`, plus a new
  in-memory-only provider holding the currently-open firm's `masterKey`.
- Test: `app/test/bootstrap/encrypted_database_test.dart` (new file — this needs `dart test`-style
  real file I/O, which this project's own docs note hangs inside `flutter test`'s sandboxed widget
  tester; write this one as a plain Dart test using `NativeDatabase` directly, not through
  `pumpLedgerly`).

**Interfaces:**
- Consumes: `KeyEnvelope`, `KeyEnvelopeStore` (Task 3), `deriveWrappingKey`/`unwrapKey` (Task 1).
- Produces: `AppPaths.firmKeyEnvelope(String firmId) -> File`, and
  `final firmMasterKeyProvider = StateProvider<Uint8List?>((ref) => null);` (holds the current
  session's master key in memory only — set at unlock time by Task 8's screen, read by the
  database opener and by `BackupService`'s provider in Task 6; never persisted anywhere itself).

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('encrypted_db_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('a database keyed at creation can only be reopened with the same raw key', () async {
    final dbFile = File('${tmp.path}/test.db');
    final key = Uint8List.fromList(List.generate(32, (i) => i));
    final keyHex = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    // Create + key it.
    var db = raw.sqlite3.open(dbFile.path);
    db.execute("PRAGMA key = \"x'$keyHex'\";");
    db.execute('CREATE TABLE t (id INTEGER)');
    db.execute('INSERT INTO t VALUES (1)');
    db.dispose();

    // Reopening with the SAME key and reading must succeed.
    final reopened = raw.sqlite3.open(dbFile.path);
    reopened.execute("PRAGMA key = \"x'$keyHex'\";");
    final rows = reopened.select('SELECT * FROM t');
    expect(rows.length, 1);
    reopened.dispose();

    // Reopening with a WRONG key must fail on the first real read, not
    // silently succeed -- PRAGMA key never rejects a wrong key by itself.
    final wrongKeyHex = List.generate(32, (i) => 255 - i)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final wrongOpen = raw.sqlite3.open(dbFile.path);
    wrongOpen.execute("PRAGMA key = \"x'$wrongKeyHex'\";");
    expect(() => wrongOpen.select('SELECT * FROM t'), throwsA(anything));
    wrongOpen.dispose();
  });
}
```

- [ ] **Step 2: Run test to verify it fails or passes for the wrong reason**

Run: `cd app && dart test test/bootstrap/encrypted_database_test.dart` (plain `dart test`, not
`flutter test` — this file has no Flutter/widget dependency).
Expected: this test doesn't depend on any new code you're about to write — it's exercising
`sqlite3`'s own SQLCipher build directly, to prove **empirically, before building anything on top
of it**, that this Ledgerly build's SQLite really is SQLCipher-capable and behaves as the spec
assumes (raw hex key accepted, wrong key fails on read not on `PRAGMA key` itself). If this test
doesn't pass immediately, stop and report it — every later task in this plan assumes this works.

- [ ] **Step 3: Confirm it passes, then wire up `AppPaths` and the providers**

Modify `app/lib/bootstrap/app_paths.dart`, add next to `firmDatabase`:

```dart
  File firmKeyEnvelope(String firmId) => File(p.join(firms.path, '$firmId.key.json'));
```

Modify `app/lib/bootstrap/providers.dart`. The real current code (lines 23-30) is:

```dart
typedef DatabaseOpener = Future<AppDatabase> Function(String firmId);

final databaseOpenerProvider = Provider<DatabaseOpener>((ref) {
  final paths = ref.watch(appPathsProvider);
  return (firmId) async => AppDatabase(
    NativeDatabase.createInBackground(paths.firmDatabase(firmId)),
  );
});
```

Replace it with (add `import 'dart:typed_data';` to the file's existing import block):

```dart
final firmMasterKeyProvider = StateProvider<Uint8List?>((ref) => null);

typedef DatabaseOpener = Future<AppDatabase> Function(String firmId);

final databaseOpenerProvider = Provider<DatabaseOpener>((ref) {
  final paths = ref.watch(appPathsProvider);
  return (firmId) async {
    final masterKey = ref.read(firmMasterKeyProvider);
    return AppDatabase(
      NativeDatabase.createInBackground(
        paths.firmDatabase(firmId),
        setup: masterKey == null
            ? null
            : (rawDb) {
                final hex = masterKey
                    .map((b) => b.toRadixString(16).padLeft(2, '0'))
                    .join();
                rawDb.execute("PRAGMA key = \"x'$hex'\";");
              },
      ),
    );
  };
});
```

`setup:` runs `PRAGMA key` before drift touches anything else, only when a key is actually set for
this session; an unencrypted firm — `firmMasterKeyProvider` still `null` — opens exactly as it does
today, with zero behavior change. Every other provider/class in this file (`OpenFirm`,
`openFirmProvider`, `_openFirm`, `firmCreatorProvider`, `createFirstFirm`) is unchanged.

- [ ] **Step 4: Run the full existing suite to confirm zero regressions on unencrypted firms**

Run: `cd app && flutter test`
Expected: every existing test still passes unchanged — `firmMasterKeyProvider` defaults to `null`,
so `setup` is `null` and every unencrypted firm opens exactly as before.

- [ ] **Step 5: Commit**

```bash
git add app/lib/bootstrap/app_paths.dart app/lib/bootstrap/providers.dart app/test/bootstrap/encrypted_database_test.dart
git commit -m "Encryption: keyed database opening via a raw SQLCipher key, verified against the real sqlite3 build"
```

---

## Task 5: Unlock, setup, passphrase change, and recovery-code rotation (app logic layer)

**Files:**
- Create: `app/lib/features/encryption/encryption_service.dart` — the logic layer; the UI screens
  in Task 7 call into this, not into Tasks 1-4 directly.
- Test: `app/test/features/encryption/encryption_service_test.dart` (plain `dart test` again, real
  file I/O against a real keyed SQLite database — this is the highest-value test file in the whole
  plan and should cover every scenario the spec's Testing section calls out).

**Interfaces:**
- Consumes: everything from Tasks 1-4.
- Produces:
  `class EncryptionService { EncryptionService({required AppPaths paths}); Future<void> enableEncryption(String firmId, {required String passphrase, required void Function(String recoveryCode) onRecoveryCodeGenerated}); Future<Uint8List?> unlockWithPassphrase(String firmId, String passphrase); Future<Uint8List?> unlockWithRecoveryCode(String firmId, String recoveryCode); Future<void> changePassphrase(String firmId, {required Uint8List masterKey, required String newPassphrase}); Future<String> rotateRecoveryCode(String firmId, {required Uint8List masterKey}); Future<bool> isEncrypted(String firmId); }`
  — `unlockWithPassphrase`/`unlockWithRecoveryCode` return `null` on a wrong input (fail closed, no
  exception for the expected "wrong passphrase" case — only for genuine I/O errors).

- [ ] **Step 1: Write the failing tests**

```dart
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

    final unlocked = await service.unlockWithPassphrase(firmId, 'correct horse battery staple');
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

  test('the recovery code unlocks to the exact same master key as the passphrase', () async {
    final service = EncryptionService(paths: paths);
    String? recoveryCode;
    await service.enableEncryption(
      firmId,
      passphrase: 'a passphrase',
      onRecoveryCodeGenerated: (code) => recoveryCode = code,
    );

    final viaPassphrase = await service.unlockWithPassphrase(firmId, 'a passphrase');
    final viaRecovery = await service.unlockWithRecoveryCode(firmId, recoveryCode!);
    expect(viaRecovery, equals(viaPassphrase));
  });

  test('a wrong recovery code fails closed', () async {
    final service = EncryptionService(paths: paths);
    await service.enableEncryption(firmId, passphrase: 'x', onRecoveryCodeGenerated: (_) {});
    expect(await service.unlockWithRecoveryCode(firmId, 'XXXX-XXXX-XXXX-XXXX-X'), isNull);
  });

  test('changing the passphrase: old passphrase stops working, new one works, recovery code unchanged', () async {
    final service = EncryptionService(paths: paths);
    String? recoveryCode;
    await service.enableEncryption(
      firmId,
      passphrase: 'old passphrase',
      onRecoveryCodeGenerated: (code) => recoveryCode = code,
    );
    final masterKey = (await service.unlockWithPassphrase(firmId, 'old passphrase'))!;

    await service.changePassphrase(firmId, masterKey: masterKey, newPassphrase: 'new passphrase');

    expect(await service.unlockWithPassphrase(firmId, 'old passphrase'), isNull);
    final viaNew = await service.unlockWithPassphrase(firmId, 'new passphrase');
    expect(viaNew, equals(masterKey));
    final viaRecovery = await service.unlockWithRecoveryCode(firmId, recoveryCode!);
    expect(viaRecovery, equals(masterKey), reason: 'recovery code must survive a passphrase change');
  });

  test('rotating the recovery code invalidates the old one and the new one works', () async {
    final service = EncryptionService(paths: paths);
    String? oldCode;
    await service.enableEncryption(
      firmId,
      passphrase: 'p',
      onRecoveryCodeGenerated: (code) => oldCode = code,
    );
    final masterKey = (await service.unlockWithPassphrase(firmId, 'p'))!;

    final newCode = await service.rotateRecoveryCode(firmId, masterKey: masterKey);

    expect(await service.unlockWithRecoveryCode(firmId, oldCode!), isNull);
    expect(await service.unlockWithRecoveryCode(firmId, newCode), equals(masterKey));
    expect(await service.unlockWithPassphrase(firmId, 'p'), equals(masterKey),
        reason: 'passphrase must survive a recovery-code rotation');
  });

  test('a firm with no envelope file is reported as not encrypted', () async {
    final service = EncryptionService(paths: paths);
    expect(await service.isEncrypted(firmId), isFalse);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd app && dart test test/features/encryption/encryption_service_test.dart`
Expected: FAIL — `EncryptionService` undefined.

- [ ] **Step 3: Write minimal implementation**

Create `app/lib/features/encryption/encryption_service.dart`:

```dart
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

  KeyEnvelopeStore _storeFor(String firmId) => KeyEnvelopeStore(paths.firmKeyEnvelope(firmId));

  Future<bool> isEncrypted(String firmId) async => await _storeFor(firmId).read() != null;

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
    final passphraseWrappingKey = await deriveWrappingKey(passphrase, salt: passphraseSalt);
    final recoveryWrappingKey = await deriveWrappingKey(
      encodeRecoveryCode(recoverySecret), // the code itself is the "secret" for its own KDF
      salt: recoveryCodeSalt,
    );

    final envelope = KeyEnvelope(
      byPassphrase: await wrapKey(masterKey, wrappingKeyBytes: passphraseWrappingKey),
      passphraseSalt: passphraseSalt,
      byRecoveryCode: await wrapKey(masterKey, wrappingKeyBytes: recoveryWrappingKey),
      recoveryCodeSalt: recoveryCodeSalt,
    );
    await _storeFor(firmId).write(envelope);
    onRecoveryCodeGenerated(recoveryCode);
  }

  Future<Uint8List?> unlockWithPassphrase(String firmId, String passphrase) async {
    final envelope = await _storeFor(firmId).read();
    if (envelope == null) return null;
    final wrappingKey = await deriveWrappingKey(passphrase, salt: envelope.passphraseSalt);
    try {
      return await unwrapKey(envelope.byPassphrase, wrappingKeyBytes: wrappingKey);
    } catch (_) {
      return null; // wrong passphrase -- fail closed, not an exception the caller must catch
    }
  }

  Future<Uint8List?> unlockWithRecoveryCode(String firmId, String recoveryCode) async {
    final envelope = await _storeFor(firmId).read();
    if (envelope == null) return null;
    if (decodeRecoveryCode(recoveryCode) == null) return null; // invalid check symbol
    final wrappingKey = await deriveWrappingKey(recoveryCode, salt: envelope.recoveryCodeSalt);
    try {
      return await unwrapKey(envelope.byRecoveryCode, wrappingKeyBytes: wrappingKey);
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
    if (existing == null) throw StateError('No envelope exists for firm $firmId');
    final newSalt = _randomBytes(16);
    final newWrappingKey = await deriveWrappingKey(newPassphrase, salt: newSalt);
    await store.write(
      KeyEnvelope(
        byPassphrase: await wrapKey(masterKey, wrappingKeyBytes: newWrappingKey),
        passphraseSalt: newSalt,
        byRecoveryCode: existing.byRecoveryCode,
        recoveryCodeSalt: existing.recoveryCodeSalt,
      ),
    );
  }

  Future<String> rotateRecoveryCode(String firmId, {required Uint8List masterKey}) async {
    final store = _storeFor(firmId);
    final existing = await store.read();
    if (existing == null) throw StateError('No envelope exists for firm $firmId');
    final newRecoverySecret = _randomBytes(32);
    final newCode = encodeRecoveryCode(newRecoverySecret);
    final newSalt = _randomBytes(16);
    final newWrappingKey = await deriveWrappingKey(newCode, salt: newSalt);
    await store.write(
      KeyEnvelope(
        byPassphrase: existing.byPassphrase,
        passphraseSalt: existing.passphraseSalt,
        byRecoveryCode: await wrapKey(masterKey, wrappingKeyBytes: newWrappingKey),
        recoveryCodeSalt: newSalt,
      ),
    );
    return newCode;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd app && dart test test/features/encryption/encryption_service_test.dart`
Expected: PASS — all 8 cases, including the two "survives the other secret changing" cases and
both fail-closed cases.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/encryption/encryption_service.dart app/test/features/encryption/encryption_service_test.dart
git commit -m "Encryption: EncryptionService -- setup, unlock, passphrase change, recovery-code rotation"
```

---

## Task 6: Plaintext-to-encrypted migration + key-aware BackupService

**Files:**
- Modify: `packages/ledgerly_data/lib/src/backup_service.dart` — key-aware probes.
- Modify: `app/lib/features/settings/settings_providers.dart` — thread `firmMasterKeyProvider`
  into `backupServiceProvider`/`restoreServiceProvider`.
- Add to: `app/lib/features/encryption/encryption_service.dart` — the migration method.
- Test: `packages/ledgerly_data/test/backup_service_encrypted_test.dart`,
  `app/test/features/encryption/encryption_migration_test.dart` (both plain `dart test`).

**Interfaces:**
- Consumes: `EncryptionService` (Task 5), `KeyEnvelopeStore`/`KeyEnvelope` (Task 3).
- Produces: `BackupService`'s constructor gains `Uint8List? masterKey` (nullable — `null` means
  "this firm isn't encrypted," identical behavior to today); adds to `EncryptionService`:
  `Future<void> migrateToEncrypted(String firmId, {required String passphrase, required void Function(String recoveryCode) onRecoveryCodeGenerated, required Directory localBackupDir, Directory? userBackupDir})`.

- [ ] **Step 1: Write the failing tests — BackupService with a key**

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:ledgerly_data/src/db/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('backup_encrypted_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  String keyHex(List<int> key) => key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  test('backing up an encrypted firm produces a backup that is genuinely ciphertext', () async {
    final key = List.generate(32, (i) => i);
    final dbFile = File('${tmp.path}/firm.db');
    // Open + key the raw connection, then hand that SAME connection to
    // drift via NativeDatabase.opened -- this is how the real app's
    // databaseOpenerProvider (Task 4) also gets a keyed AppDatabase, so the
    // test exercises the identical wiring path, not a shortcut around it.
    final raw.Database seed = raw.sqlite3.open(dbFile.path);
    seed.execute("PRAGMA key = \"x'${keyHex(key)}'\";");
    seed.execute('CREATE TABLE firms (id TEXT)');
    seed.execute('CREATE TABLE customers (id TEXT)');
    seed.execute('CREATE TABLE transactions (id TEXT)');
    seed.execute("INSERT INTO firms VALUES ('f1')");
    final db = AppDatabase(NativeDatabase.opened(seed));

    final localBackupDir = Directory('${tmp.path}/backups')..createSync();
    final service = BackupService(
      db: db,
      databaseFile: dbFile,
      localBackupDir: localBackupDir,
      masterKey: key,
    );

    final result = await service.backupNow();
    await db.close();

    // The backup file must NOT open with an unkeyed probe -- proving it's
    // genuinely encrypted on disk, not accidentally plaintext.
    final unkeyed = raw.sqlite3.open(result.localFile.path, mode: raw.OpenMode.readOnly);
    expect(() => unkeyed.select('PRAGMA quick_check'), throwsA(anything));
    unkeyed.dispose();

    // ...but it DOES open and validate correctly with the right key.
    service.validateBackup(result.localFile); // must not throw
  });
}
```

(Confirmed against the real source: `packages/ledgerly_data/lib/src/db/app_database.dart:15` reads
`AppDatabase(super.executor);` — the constructor form above is exact, not a guess.)

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/ledgerly_data && dart test test/backup_service_encrypted_test.dart`
Expected: FAIL — `BackupService` doesn't accept `masterKey` yet.

- [ ] **Step 3: Make `BackupService` key-aware**

Modify `packages/ledgerly_data/lib/src/backup_service.dart`. Add `masterKey` to the constructor:

```dart
  BackupService({
    required this.db,
    required this.databaseFile,
    required this.localBackupDir,
    this.userBackupDir,
    this.keep = 30,
    this.masterKey,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final List<int>? masterKey;
```

Add a helper and use it everywhere a probe connection is opened:

```dart
  String get _keyPragma {
    final key = masterKey;
    if (key == null) return '';
    final hex = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return "PRAGMA key = \"x'$hex'\";";
  }
```

In `_verify` (currently `static`, opens `copy.path` read-only) — it needs `masterKey`, so it can no
longer be `static`; make it an instance method, and execute `_keyPragma` (if non-empty) immediately
after `raw.sqlite3.open(...)`, before `PRAGMA quick_check`. Do the same in `validateBackup`'s probe
open. Both call sites: `probe.execute(_keyPragma)` right after `open(...)`, only when `masterKey`
is not null (an empty string statement is harmless, but skip it cleanly rather than execute a
no-op).

Update `backupNow()`'s call to `_verify(tmp, ...)` (now an instance method, drop `_verify(` ->
`this._verify(` implicitly by removing `static` — no call-site syntax change needed for an
instance method called from within the same class).

- [ ] **Step 4: Write the plaintext-to-encrypted migration**

Add to `app/lib/features/encryption/encryption_service.dart` (same file as Task 5's class):

```dart
  /// Turns an existing PLAINTEXT firm database into an encrypted one. The
  /// live connection must already be closed by the caller before this runs
  /// (SQLite cannot have the file open elsewhere while sqlcipher_export
  /// rewrites it) -- same precondition BackupService.restoreFrom already
  /// documents for the same reason.
  Future<void> migrateToEncrypted(
    String firmId, {
    required String passphrase,
    required void Function(String recoveryCode) onRecoveryCodeGenerated,
  }) async {
    final liveFile = paths.firmDatabase(firmId);
    final tmpEncrypted = File('${liveFile.path}.encrypting.tmp');
    if (await tmpEncrypted.exists()) await tmpEncrypted.delete();

    final masterKey = _randomBytes(32);
    final hex = masterKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    final plain = raw.sqlite3.open(liveFile.path);
    try {
      plain.execute("ATTACH DATABASE '${tmpEncrypted.path.replaceAll("'", "''")}' AS enc KEY \"x'$hex'\";");
      plain.execute("SELECT sqlcipher_export('enc');");
      plain.execute('DETACH DATABASE enc;');
    } finally {
      plain.dispose();
    }

    // Verify before touching the live file: open the new encrypted copy,
    // integrity-check it, and compare row counts against the still-untouched
    // plaintext original.
    final encryptedProbe = raw.sqlite3.open(tmpEncrypted.path, mode: raw.OpenMode.readOnly);
    encryptedProbe.execute("PRAGMA key = \"x'$hex'\";");
    final check = encryptedProbe.select('PRAGMA cipher_integrity_check');
    if (check.isNotEmpty) {
      encryptedProbe.dispose();
      await tmpEncrypted.delete();
      throw StateError('Encrypted copy failed integrity check: $check');
    }
    final plainProbe = raw.sqlite3.open(liveFile.path, mode: raw.OpenMode.readOnly);
    for (final table in ['firms', 'customers', 'transactions']) {
      final plainCount = plainProbe.select('SELECT count(*) AS c FROM $table').first['c'];
      final encCount = encryptedProbe.select('SELECT count(*) AS c FROM $table').first['c'];
      if (plainCount != encCount) {
        encryptedProbe.dispose();
        plainProbe.dispose();
        await tmpEncrypted.delete();
        throw StateError('Row count mismatch on $table after encryption: $plainCount vs $encCount');
      }
    }
    encryptedProbe.dispose();
    plainProbe.dispose();

    // Verified -- write the envelope, then swap the file in. The plaintext
    // original is kept as a `.pre-encryption` sidecar (not deleted) until the
    // caller confirms the swapped-in file has been reopened and read from at
    // least once.
    final plaintextKept = File('${liveFile.path}.pre-encryption');
    await liveFile.copy(plaintextKept.path);
    await enableEncryptionEnvelopeOnly(
      firmId,
      masterKey: masterKey,
      passphrase: passphrase,
      onRecoveryCodeGenerated: onRecoveryCodeGenerated,
    );
    await tmpEncrypted.rename(liveFile.path);
  }

  /// Writes the envelope for an already-chosen [masterKey] -- used by
  /// [migrateToEncrypted], which generates the key itself as part of the
  /// export step above, rather than [enableEncryption]'s own random-key path.
  Future<void> enableEncryptionEnvelopeOnly(
    String firmId, {
    required Uint8List masterKey,
    required String passphrase,
    required void Function(String recoveryCode) onRecoveryCodeGenerated,
  }) async {
    final recoverySecret = _randomBytes(32);
    final recoveryCode = encodeRecoveryCode(recoverySecret);
    final passphraseSalt = _randomBytes(16);
    final recoveryCodeSalt = _randomBytes(16);
    final envelope = KeyEnvelope(
      byPassphrase: await wrapKey(
        masterKey,
        wrappingKeyBytes: await deriveWrappingKey(passphrase, salt: passphraseSalt),
      ),
      passphraseSalt: passphraseSalt,
      byRecoveryCode: await wrapKey(
        masterKey,
        wrappingKeyBytes: await deriveWrappingKey(recoveryCode, salt: recoveryCodeSalt),
      ),
      recoveryCodeSalt: recoveryCodeSalt,
    );
    await _storeFor(firmId).write(envelope);
    onRecoveryCodeGenerated(recoveryCode);
  }
```

(Refactor `enableEncryption` from Task 5 to call `enableEncryptionEnvelopeOnly` internally with a
freshly-generated `masterKey`, rather than duplicating the wrap logic -- both paths need it, only
`migrateToEncrypted` needs the key chosen *before* the envelope step, since it's already baked into
the exported file by the time the envelope is written.)

Add `import 'dart:io'; import 'package:sqlite3/sqlite3.dart' as raw;` to the top of
`encryption_service.dart`.

- [ ] **Step 5: Wire the master key into `backupServiceProvider`/`restoreServiceProvider`**

In `app/lib/features/settings/settings_providers.dart`, both providers construct `BackupService` —
add `masterKey: ref.watch(firmMasterKeyProvider)` to both constructor calls.

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd packages/ledgerly_data && dart test` (whole package), then
`cd app && dart test test/features/encryption/` and `flutter test` (full suite, confirm
unencrypted-firm behavior is completely unchanged).
Expected: PASS across all of it.

- [ ] **Step 7: Commit**

```bash
git add packages/ledgerly_data/lib/src/backup_service.dart packages/ledgerly_data/test/backup_service_encrypted_test.dart app/lib/features/encryption/encryption_service.dart app/lib/features/settings/settings_providers.dart app/test/features/encryption/encryption_migration_test.dart
git commit -m "Encryption: key-aware BackupService + plaintext-to-encrypted migration via sqlcipher_export"
```

---

## Task 7: Encryption UI — setup wizard, unlock screen, Settings actions

**Files:**
- Create: `app/lib/features/encryption/encryption_setup_screen.dart`
- Create: `app/lib/features/encryption/unlock_screen.dart`
- Modify: `app/lib/features/settings/settings_screen.dart` — "Enable encryption" / "Change
  passphrase" / "Generate a new recovery code" section.
- Modify: `app/lib/bootstrap/router.dart` — route to the unlock screen before the dashboard when
  `EncryptionService.isEncrypted(firmId)` is true and `firmMasterKeyProvider` is still `null`.
- Modify: `app/lib/features/setup/first_launch_screen.dart` — offer encryption as part of first
  launch, calling `EncryptionService.enableEncryption` (a brand-new firm, so no migration needed).
- Test: `app/test/features/encryption/encryption_screens_test.dart`

**Interfaces:**
- Consumes: `EncryptionService` (Tasks 5-6), `firmMasterKeyProvider` (Task 4).

This task is UI wiring over already-tested logic (Tasks 5-6) — the correctness bar here is "does
the right method get called with the right arguments and does the result reach
`firmMasterKeyProvider`," not re-testing the crypto. Build each piece to this exact behavior,
keyed for testing per this codebase's `Key('domain.widget')` convention:

- **Setup wizard** (`Key('encryption.setupWizard')`): a passphrase field
  (`Key('encryption.passphrase')`) + confirm field, a "Generate recovery code" button
  (`Key('encryption.generate')`) that calls `enableEncryption`/`migrateToEncrypted` (a brand-new
  firm uses the former, an existing plaintext firm the latter — the caller knows which, based on
  whether the firm already has data), shows the code once with a **type-it-back** confirmation
  field (`Key('encryption.recoveryCodeConfirm')`) that must exactly match before an "Enable
  encryption" button (`Key('encryption.confirmEnable')`) becomes tappable, and states plainly
  before that button: *"If you forget your passphrase and lose this recovery code, this firm's
  ledger cannot be recovered by anyone, including you or us."* If migrating an existing firm with
  plaintext backups already in `localBackupDir`/`userBackupDir`, show a summary count and a
  "Delete these now" button (`Key('encryption.deleteOldBackups')`) — offered, not automatic.
- **Unlock screen** (`Key('encryption.unlockScreen')`): a passphrase field
  (`Key('encryption.unlockPassphrase')`) and an "Unlock" button (`Key('encryption.unlock')`)
  calling `unlockWithPassphrase`; on success, set `firmMasterKeyProvider` to the returned key and
  navigate to `/`. On failure (`null` returned), show an error, never navigate. An "I lost my
  passphrase" link (`Key('encryption.forgotPassphrase')`) reveals a recovery-code field
  (`Key('encryption.recoveryCodeInput')`) calling `unlockWithRecoveryCode`; on success, immediately
  route to a **required** "set a new passphrase" screen (reusing the setup wizard's passphrase
  fields) before the dashboard is reachable — this is not skippable, per the spec.
- **Router change**: in `router.dart`'s `redirect`, add a check — after the existing `/setup`/
  `/loading` handling, if the firm's `EncryptionService.isEncrypted(firm.id)` is true and
  `firmMasterKeyProvider` is still `null`, redirect to a new `/unlock` route (outside the
  `ShellRoute`, same pattern as `/setup`).
- **Settings additions**: a "Bluetooth printer"-section-style block (mirroring the existing
  pattern in `settings_screen.dart`) with: current encryption state, "Enable encryption" (routes to
  the setup wizard) when off, or "Change passphrase" (`Key('encryption.changePassphrase')`) +
  "Generate a new recovery code" (`Key('encryption.rotateRecoveryCode')`) when on — both requiring
  the current passphrase re-entered first (call `unlockWithPassphrase` to get `masterKey` before
  calling `changePassphrase`/`rotateRecoveryCode`, never reuse a stale in-memory key for these
  sensitive actions).

- [ ] **Step 1: Write the failing tests**

```dart
  testWidgets('setting up encryption requires typing the recovery code back before enabling', (
    tester,
  ) async {
    final container = await pumpLedgerly(tester, seed: seed);
    await container.read(firmMasterKeyProvider.notifier).state; // no-op read to confirm provider exists
    // Navigate to Settings -> Enable encryption
    await pressCtrl(tester, LogicalKeyboardKey.comma);
    await tester.tap(find.byKey(const Key('encryption.enableSection')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('encryption.passphrase')), 'a good passphrase');
    await tester.tap(find.byKey(const Key('encryption.generate')));
    await tester.pumpAndSettle();

    // The confirm button must not be tappable-and-effective until the code is typed back correctly.
    await tester.tap(find.byKey(const Key('encryption.confirmEnable')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('encryption.unlockScreen')), findsNothing); // still not enabled

    final shownCode = /* read the displayed code from the widget tree */ '';
    await tester.enterText(find.byKey(const Key('encryption.recoveryCodeConfirm')), shownCode);
    await tester.tap(find.byKey(const Key('encryption.confirmEnable')));
    await tester.pumpAndSettle();

    expect(await container.read(encryptionServiceProvider).isEncrypted(container.read(openFirmProvider).value!.ctx.firmId), isTrue);
  });

  testWidgets('a wrong passphrase on the unlock screen shows an error and does not navigate away', (
    tester,
  ) async {
    // Set up an encrypted firm first (reuse the service directly, not through the wizard,
    // to keep this test focused on the unlock screen alone), then simulate app start with
    // firmMasterKeyProvider still null and assert the unlock screen renders, a wrong
    // passphrase keeps it on screen with an error, and the right one navigates to '/'.
  });
```

(The exact "read the displayed code from the widget tree" mechanic and the second test's full body
depend on the concrete widget structure chosen in Step 3 — write these once that structure exists,
following the shape above; the important behavioral assertions are: recovery code must be typed
back correctly before enabling completes, and a wrong passphrase never navigates past the unlock
screen.)

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd app && flutter test test/features/encryption/encryption_screens_test.dart`
Expected: FAIL — none of the screens/keys exist yet.

- [ ] **Step 3: Build the screens** per the exact behavior specified above.

- [ ] **Step 4: Run tests to verify they pass, then the full suite**

Run: `cd app && flutter test test/features/encryption/encryption_screens_test.dart && flutter test`

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/encryption/ app/lib/features/settings/settings_screen.dart app/lib/bootstrap/router.dart app/lib/features/setup/first_launch_screen.dart app/test/features/encryption/encryption_screens_test.dart
git commit -m "Encryption: setup wizard, unlock screen, Settings passphrase/recovery-code actions"
```

---

## Task 8: Google sign-in — backend

**Files:**
- Modify: `backend/app/routers/auth.py` — `POST /auth/google`, `POST /auth/google/link`.
- Test: `backend/tests/test_auth_google.py`

**Interfaces:**
- Consumes: `_issue_tokens`, `_store_refresh_token`, `hash_password`/`verify_password` (all
  existing, unchanged), `create_access_token` (existing, from `app.security` — needed by
  `/auth/google/link`'s auth dependency).
- Produces: `POST /auth/google` (`GoogleAuthRequest{id_token, firm: FirmInfo, device: DeviceInfo}`
  -> `TokenResponse` on success, `409 {"detail": "email_exists_unlinked"}` when a matching
  unverified-or-unlinked email exists), `POST /auth/google/link` (bearer-token-protected,
  `GoogleLinkRequest{id_token}` -> `204`).

- [ ] **Step 1: Write the failing tests**

This file follows `backend/tests/test_auth.py`'s existing convention exactly: the `client:
AsyncClient` fixture from `conftest.py` (already wired to a rolled-back-per-test transaction —
never `async_db_session` directly, and never a manually constructed `ASGITransport`), module-level
`_register_body`/`_register` helpers, no `@pytest.mark.anyio` marker (this repo's `client` fixture
handles the event loop itself, matching `test_auth.py`'s existing tests which carry no such
marker).

```python
import uuid
from unittest.mock import patch

from httpx import AsyncClient

DEVICE_ID = "22222222-2222-4222-8222-222222222222"


def _register_body(email: str = "rashid@example.com", **overrides: object) -> dict:
    body: dict = {
        "name": "Rashid",
        "email": email,
        "password": "correct-password",
        "firm": {
            "id": str(uuid.uuid4()),
            "name": "Al-Madina Oil Mills",
            "contact_number": "0300-1234567",
        },
        "device": {
            "id": DEVICE_ID,
            "name": "Rashid's Laptop",
            "platform": "windows",
            "short_code": "A3F9",
        },
    }
    body.update(overrides)
    return body


async def _register(client: AsyncClient, email: str = "rashid@example.com") -> dict:
    response = await client.post("/auth/register", json=_register_body(email))
    assert response.status_code == 201, response.text
    return response.json()


def _google_body(sub: str, email: str = "new@example.com", **overrides: object) -> dict:
    body: dict = {
        "id_token": "fake",
        "firm": {
            "id": str(uuid.uuid4()),
            "name": "Test Mill",
            "contact_number": "0300-1234567",
        },
        "device": {
            "id": str(uuid.uuid4()),
            "name": "Phone",
            "platform": "android",
            "short_code": "AB12",
        },
    }
    body.update(overrides)
    return body


def _fake_verified_payload(sub: str, email: str, email_verified: bool = True) -> dict:
    return {"sub": sub, "email": email, "email_verified": email_verified, "name": "Google User"}


async def test_google_sign_in_creates_a_new_user_and_firm(client: AsyncClient) -> None:
    with patch(
        "app.routers.auth.verify_google_id_token",
        return_value=_fake_verified_payload("g-sub-1", "new@example.com"),
    ):
        response = await client.post("/auth/google", json=_google_body("g-sub-1"))

    assert response.status_code == 201, response.text
    body = response.json()
    assert body["user"]["email"] == "new@example.com"
    assert body["token_type"] == "bearer"


async def test_google_sign_in_logs_in_an_existing_google_user(client: AsyncClient) -> None:
    payload = _fake_verified_payload("g-sub-2", "returning@example.com")
    request_body = _google_body("g-sub-2", "returning@example.com")
    with patch("app.routers.auth.verify_google_id_token", return_value=payload):
        first = await client.post("/auth/google", json=request_body)
        assert first.status_code == 201, first.text
        firm_id = first.json()["firm"]["id"]

        # Sign in again with the SAME google sub but a DIFFERENT client-supplied
        # firm/device (a second phone, or a reinstalled app) -- must log into
        # the same existing firm, never create a second one.
        second = await client.post(
            "/auth/google",
            json=_google_body("g-sub-2", "returning@example.com"),
        )

    assert second.status_code == 201, second.text
    assert second.json()["firm"]["id"] == firm_id
    assert second.json()["user"]["email"] == "returning@example.com"


async def test_google_sign_in_does_not_auto_link_an_existing_password_account(
    client: AsyncClient,
) -> None:
    registered = await _register(client, email="passwordonly@example.com")

    with patch(
        "app.routers.auth.verify_google_id_token",
        return_value=_fake_verified_payload("g-sub-3", "passwordonly@example.com"),
    ):
        response = await client.post(
            "/auth/google", json=_google_body("g-sub-3", "passwordonly@example.com")
        )

    assert response.status_code == 409
    assert response.json()["detail"] == "email_exists_unlinked"

    # The password account must not have been silently linked -- logging in
    # with the ORIGINAL password must still work and return the same user.
    login = await client.post(
        "/auth/login",
        json={
            "email": "passwordonly@example.com",
            "password": "correct-password",
            "device_id": DEVICE_ID,
        },
    )
    assert login.status_code == 200
    assert login.json()["user"]["id"] == registered["user"]["id"]


async def test_google_sign_in_rejects_an_unverified_email_even_on_a_match(
    client: AsyncClient,
) -> None:
    await _register(client, email="unverified@example.com")

    payload = _fake_verified_payload(
        "g-sub-4", "unverified@example.com", email_verified=False
    )
    with patch("app.routers.auth.verify_google_id_token", return_value=payload):
        response = await client.post(
            "/auth/google", json=_google_body("g-sub-4", "unverified@example.com")
        )

    # Unverified email must never be treated as a match -- it falls through
    # to first-time registration, creating a SEPARATE account/firm rather
    # than either linking to or rejecting against the existing one.
    assert response.status_code == 201, response.text
    assert response.json()["user"]["email"] == "unverified@example.com"


async def test_google_link_requires_an_authenticated_session(client: AsyncClient) -> None:
    response = await client.post("/auth/google/link", json={"id_token": "fake"})
    assert response.status_code == 401


async def test_google_link_sets_google_sub_on_the_authenticated_users_account(
    client: AsyncClient,
) -> None:
    registered = await _register(client, email="linkme@example.com")
    access_token = registered["access_token"]

    with patch(
        "app.routers.auth.verify_google_id_token",
        return_value=_fake_verified_payload("g-sub-5", "linkme@example.com"),
    ):
        link_response = await client.post(
            "/auth/google/link",
            json={"id_token": "fake"},
            headers={"Authorization": f"Bearer {access_token}"},
        )
    assert link_response.status_code == 204

    # A subsequent Google sign-in with that sub must now log into the SAME
    # account this token belonged to, not create a new one.
    with patch(
        "app.routers.auth.verify_google_id_token",
        return_value=_fake_verified_payload("g-sub-5", "linkme@example.com"),
    ):
        signed_in = await client.post("/auth/google", json=_google_body("g-sub-5", "linkme@example.com"))
    assert signed_in.status_code == 201
    assert signed_in.json()["user"]["id"] == registered["user"]["id"]
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend && pytest tests/test_auth_google.py -v`
Expected: FAIL — `/auth/google` doesn't exist.

- [ ] **Step 3: Write minimal implementation**

Add to `backend/app/routers/auth.py`. Add this import alongside the file's existing imports (it
already imports `from app.db import get_db` and `from app.security import ...` — add a third
first-party import line for the auth dependency, which already exists at
`backend/app/deps.py:15`, built for exactly this bearer-token case):

```python
from app.deps import get_current_user_id
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token

# Extend as desktop OAuth support is added later -- write this as a list from
# the start rather than a single string, per the design spec.
GOOGLE_AUDIENCE_ALLOWLIST = [
    "REPLACE-WITH-THE-WEB-CLIENT-ID.apps.googleusercontent.com",
]


def verify_google_id_token(token: str) -> dict:
    # A thin wrapper so tests can patch this one call rather than mocking
    # Google's actual verification internals.
    payload = google_id_token.verify_oauth2_token(token, google_requests.Request())
    if payload.get("aud") not in GOOGLE_AUDIENCE_ALLOWLIST:
        raise HTTPException(status_code=401, detail="Invalid token audience.")
    if payload.get("iss") not in ("accounts.google.com", "https://accounts.google.com"):
        raise HTTPException(status_code=401, detail="Invalid token issuer.")
    return payload


class GoogleAuthRequest(BaseModel):
    id_token: str
    firm: FirmInfo
    device: DeviceInfo


class GoogleLinkRequest(BaseModel):
    id_token: str


@router.post("/google", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def google_sign_in(
    body: GoogleAuthRequest,
    db: AsyncSession = Depends(get_db),  # noqa: B008 -- FastAPI Depends()
) -> TokenResponse:
    payload = verify_google_id_token(body.id_token)
    sub = payload["sub"]
    email = payload.get("email")
    email_verified = payload.get("email_verified", False)

    row = (
        await db.execute(
            text(
                """
                SELECT u.id, u.name, u.email, f.id AS firm_id, f.name AS firm_name
                FROM users u
                JOIN firm_members fm ON fm.user_id = u.id AND fm.deleted_at IS NULL
                JOIN firms f ON f.id = fm.firm_id
                WHERE u.google_sub = :sub AND u.deleted_at IS NULL
                """
            ),
            {"sub": sub},
        )
    ).one_or_none()
    if row is not None:
        return await _issue_tokens(
            db,
            user_id=str(row.id),
            name=row.name,
            email=row.email,
            device_id=body.device.id,
            firm=FirmOut(id=str(row.firm_id), name=row.firm_name),
        )

    if email and email_verified:
        existing = (
            await db.execute(
                text("SELECT id FROM users WHERE email = :email AND deleted_at IS NULL"),
                {"email": email},
            )
        ).one_or_none()
        if existing is not None:
            # A password account with this email already exists. Do NOT
            # auto-link -- that would let anyone who can present a Google
            # token for this email take over an account they never proved
            # ownership of via its actual password. The app must send the
            # user to log in normally, then call /auth/google/link once
            # authenticated.
            raise HTTPException(status_code=409, detail="email_exists_unlinked")

    # No google_sub match, no email match (or email unverified) -- first-time
    # registration, identical shape to /auth/register except no password.
    now = int(time.time())
    try:
        await db.execute(
            text(
                """
                INSERT INTO firms (id, name, contact_number, number_grouping, created_at,
                                    updated_at, updated_by_device_id)
                VALUES (:id, :name, :contact_number, :number_grouping, :now, :now, :device_id)
                """
            ),
            {
                "id": body.firm.id,
                "name": body.firm.name,
                "contact_number": body.firm.contact_number,
                "number_grouping": DEFAULT_NUMBER_GROUPING,
                "now": now,
                "device_id": body.device.id,
            },
        )
        user_row = (
            await db.execute(
                text(
                    """
                    INSERT INTO users (name, email, google_sub, created_at, updated_at,
                                        updated_by_device_id)
                    VALUES (:name, :email, :sub, :now, :now, :device_id)
                    RETURNING id
                    """
                ),
                {
                    "name": payload.get("name", email or "Google user"),
                    "email": email,
                    "sub": sub,
                    "now": now,
                    "device_id": body.device.id,
                },
            )
        ).one()
        user_id = str(user_row.id)
        await db.execute(
            text(
                """
                INSERT INTO firm_members (firm_id, user_id, role, created_at, updated_at,
                                           updated_by_device_id)
                VALUES (:firm_id, :user_id, 'owner', :now, :now, :device_id)
                """
            ),
            {"firm_id": body.firm.id, "user_id": user_id, "now": now, "device_id": body.device.id},
        )
        await db.execute(
            text(
                """
                INSERT INTO devices (id, firm_id, name, platform, short_code, created_at,
                                      updated_at, updated_by_device_id)
                VALUES (:id, :firm_id, :name, :platform, :short_code, :now, :now, :id)
                """
            ),
            {
                "id": body.device.id,
                "firm_id": body.firm.id,
                "name": body.device.name,
                "platform": body.device.platform,
                "short_code": body.device.short_code,
                "now": now,
            },
        )
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(status_code=409, detail="That account already exists.") from e

    return await _issue_tokens(
        db,
        user_id=user_id,
        name=payload.get("name", email or "Google user"),
        email=email or "",
        device_id=body.device.id,
        firm=FirmOut(id=body.firm.id, name=body.firm.name),
    )


@router.post("/google/link", status_code=status.HTTP_204_NO_CONTENT)
async def google_link(
    body: GoogleLinkRequest,
    current_user_id: str = Depends(get_current_user_id),  # see note below
    db: AsyncSession = Depends(get_db),  # noqa: B008 -- FastAPI Depends()
) -> None:
    payload = verify_google_id_token(body.id_token)
    if not payload.get("email_verified", False):
        raise HTTPException(status_code=400, detail="Google account email is not verified.")
    await db.execute(
        text("UPDATE users SET google_sub = :sub WHERE id = :id AND deleted_at IS NULL"),
        {"sub": payload["sub"], "id": current_user_id},
    )
    await db.commit()
```

Replace `GOOGLE_AUDIENCE_ALLOWLIST`'s placeholder value with the real web client ID once Task 9
generates it in the Cloud Console — leave a clear `# TODO(you): paste the web client ID from Task 9`
comment at that exact line so it's impossible to miss before deploying.

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd backend && pytest tests/test_auth_google.py -v`
Expected: PASS. Then `pytest` (whole backend suite) to confirm nothing else broke.

- [ ] **Step 5: Commit**

```bash
git add backend/app/routers/auth.py backend/tests/test_auth_google.py
git commit -m "Auth: Google sign-in (new/existing/unlinked-by-email cases), email_verified-gated linking"
```

---

## Task 9: Google sign-in — app side (Android only)

**Files:**
- Modify: `app/pubspec.yaml` — add `google_sign_in: ^7.2.0`.
- Modify: `app/lib/features/settings/cloud_sync_providers.dart` — a `signInWithGoogle()` method
  alongside the existing `register`/`login`.
- Modify: `app/lib/features/settings/settings_screen.dart` — "Sign in with Google" button, gated
  on `Platform.isAndroid`.
- Test: `app/test/features/cloud_sync_settings_test.dart` (existing file — add to it).

**Interfaces:**
- Consumes: `POST /auth/google` (Task 8), `BackendClient` (existing).

- [ ] **Step 1: Write the failing test**

```dart
  testWidgets('Sign in with Google is only shown on Android', (tester) async {
    await pumpLedgerly(tester, seed: seed);
    await pressCtrl(tester, LogicalKeyboardKey.comma);
    expect(find.byKey(const Key('settings.signInWithGoogle')), findsNothing);
  }, variant: windowsOnly);
```

(A second test on `phoneOnly` asserting the button *does* render, and a third exercising the
sign-in flow with a fake Google auth result reaching `signInWithGoogle`, follow the same file's
existing register/login test patterns for tapping through the Cloud sync section.)

- [ ] **Step 2: Run test to verify it fails**

Run: `cd app && flutter test test/features/cloud_sync_settings_test.dart`
Expected: FAIL — the button doesn't exist yet, so `findsNothing` trivially passes; add the
`phoneOnly` "does render" test first if you want a genuine RED here, or note in the report that
the `windowsOnly` "absent" case is a vacuous pass until the button exists and needs the render
case alongside it to actually prove the gating.

- [ ] **Step 3: Implement**

Add `google_sign_in: ^7.2.0` to `app/pubspec.yaml`, run `flutter pub get`.

In `cloud_sync_providers.dart`, add (mirroring the existing `register`/`login` methods' shape):

```dart
  Future<void> signInWithGoogle(FirmInfo firm, DeviceInfo device) async {
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize(serverClientId: googleWebClientId); // no `clientId` on Android
    final account = await googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) throw StateError('Google sign-in did not return an ID token.');

    final result = await ref.read(backendClientProvider).signInWithGoogle(
      idToken: idToken,
      firm: firm,
      device: device,
    );
    // ...persist the returned token pair exactly like register()/login() already do.
  }
```

(`googleWebClientId` is the same web client ID pasted into the backend's
`GOOGLE_AUDIENCE_ALLOWLIST` in Task 8 — define it as one constant, e.g. in
`app/lib/bootstrap/config.dart` if that file exists, or alongside `BackendClient`, with the same
`# TODO(you): paste from Task 9's Cloud Console setup` marker.) Add the matching
`Future<AuthResult> signInWithGoogle({required String idToken, required FirmInfo firm, required DeviceInfo device})`
method to `BackendClient`, calling `POST /auth/google` — mirror the existing `register`/`login`
methods' request/response handling exactly, including their existing 401/409 error mapping (add a
case for this endpoint's `409 email_exists_unlinked` body, surfaced as a distinct exception the
Settings UI can show a specific message for).

In `settings_screen.dart`, add the button gated on `Platform.isAndroid`, `Key('settings.signInWithGoogle')`.

**Setup dependency — stop here and walk the user through this before continuing:** creating the
OAuth consent screen, the Android OAuth client (needs the app's release signing SHA-1 — get it via
`cd app/android && ./gradlew signingReport` or from the debug keystore for local testing), and the
Web OAuth client (its ID goes into both `GOOGLE_AUDIENCE_ALLOWLIST` in Task 8 and
`googleWebClientId` here) all happen in the Google Cloud Console for project
`ledgerly-1umerchaudhary` and cannot be scripted from here.

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd app && flutter test test/features/cloud_sync_settings_test.dart && flutter test`

- [ ] **Step 5: Commit**

```bash
git add app/pubspec.yaml app/pubspec.lock app/lib/features/settings/cloud_sync_providers.dart app/lib/sync/backend_client.dart app/lib/features/settings/settings_screen.dart app/test/features/cloud_sync_settings_test.dart
git commit -m "Auth: Google sign-in on Android, gated on Platform.isAndroid (no desktop support in google_sign_in)"
```

---

## Task 10: Silent 401 token refresh with a single-flight guard

**Files:**
- Modify: `app/lib/features/settings/cloud_sync_providers.dart` — `SyncRunner.syncNow()`.
- Test: `app/test/features/cloud_sync_settings_test.dart` (existing file — add to it).

**Interfaces:**
- Consumes: `BackendClient.refresh` (existing), `BackendAuthException` (existing).

- [ ] **Step 1: Write the failing tests**

```dart
  testWidgets('a 401 during sync refreshes the token and retries once, succeeding', (tester) async {
    final container = await pumpLedgerly(tester, seed: seed);
    final fakeHttp = container.read(httpClientProvider) as FakeHttpClient;
    var pushCalls = 0;
    fakeHttp.handler = (request) async {
      if (request.url.path == '/sync/push') {
        pushCalls++;
        if (pushCalls == 1) {
          return http.Response(jsonEncode({'detail': 'Invalid or expired token'}), 401);
        }
        return http.Response(jsonEncode({'accepted': [], 'rejected': [], 'rewrites': [], 'server_time': 1000}), 200);
      }
      if (request.url.path == '/auth/refresh') {
        return http.Response(jsonEncode({'access_token': 'new-a', 'refresh_token': 'new-r'}), 200);
      }
      return http.Response(jsonEncode({'rows': [], 'next_cursor': 0, 'has_more': false}), 200);
    };
    // ... register/log in first via the existing pattern in this file ...

    await ref.read(syncRunnerProvider.notifier).syncNow();

    expect(pushCalls, 2); // one 401, one successful retry
    expect(container.read(syncRunnerProvider).error, isNull);
  });

  testWidgets('two concurrent syncs against an expired token only refresh once', (tester) async {
    // Fire syncNow() twice without awaiting the first; assert the fake /auth/refresh
    // handler is invoked exactly once, and neither call results in a logout.
  });

  testWidgets('a refresh that itself 401s still logs the user out', (tester) async {
    // Unchanged existing behavior -- confirm it still holds after this change.
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd app && flutter test test/features/cloud_sync_settings_test.dart`
Expected: FAIL — `syncNow()` doesn't retry yet.

- [ ] **Step 3: Implement**

Modify `SyncRunner` in `cloud_sync_providers.dart`:

```dart
class SyncRunner extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => const SyncStatus();

  Future<void>? _inFlightRefresh;

  Future<void> syncNow() async {
    final session = ref.read(cloudSessionProvider);
    final firm = ref.read(openFirmProvider).value;
    if (session == null || firm == null) return;
    state = SyncStatus(running: true, lastAt: state.lastAt);
    try {
      await _attemptSync(firm, session);
    } on BackendAuthException {
      final refreshed = await _refreshOnce(session);
      if (!refreshed) {
        state = SyncStatus(
          lastAt: state.lastAt,
          error: 'Signed out of cloud sync — please log in again.',
        );
        await ref.read(cloudSessionProvider.notifier).logout();
        return;
      }
      try {
        final newSession = ref.read(cloudSessionProvider)!;
        await _attemptSync(firm, newSession);
      } on BackendAuthException {
        state = SyncStatus(
          lastAt: state.lastAt,
          error: 'Signed out of cloud sync — please log in again.',
        );
        await ref.read(cloudSessionProvider.notifier).logout();
      }
    } on Exception catch (e) {
      state = SyncStatus(lastAt: state.lastAt, error: 'Sync failed: $e');
    }
  }

  Future<void> _attemptSync(OpenFirm firm, CloudSession session) async {
    final service = SyncService(
      db: firm.db,
      ctx: firm.ctx,
      client: ref.read(backendClientProvider),
      accessToken: session.accessToken,
    );
    final pushed = await service.pushPending();
    final pulled = await service.pullAll();
    final rejectedNote = pushed.rejected.isEmpty ? '' : ', ${pushed.rejected.length} rejected';
    state = SyncStatus(
      lastAt: DateTime.now(),
      summary: 'Pushed ${pushed.accepted}, pulled $pulled$rejectedNote',
    );
  }

  /// Single-flight: if a refresh is already in progress (a second concurrent
  /// syncNow() call also hit a 401), await the SAME refresh instead of
  /// independently calling /auth/refresh with an already-about-to-be-stale
  /// refresh token -- POST /auth/refresh rotates the token on every call, so
  /// a second independent refresh call would use a token the first call is
  /// about to invalidate, and itself 401, wrongly triggering a logout.
  Future<bool> _refreshOnce(CloudSession session) {
    return (_inFlightRefresh ??= _doRefresh(session)).then((_) => true).catchError((_) => false);
  }

  Future<void> _doRefresh(CloudSession session) async {
    try {
      final pair = await ref.read(backendClientProvider).refresh(session.refreshToken);
      await ref.read(cloudSessionProvider.notifier).updateTokens(
        accessToken: pair.accessToken,
        refreshToken: pair.refreshToken,
      );
    } finally {
      _inFlightRefresh = null;
    }
  }
}
```

`CloudSessionNotifier` (`app/lib/features/settings/cloud_sync_providers.dart`) currently has only
`register`/`login`/`logout` — no method updates just the token pair on an existing session, so add
one. `CloudSession` (`app/lib/bootstrap/global_prefs.dart`) is an immutable record with
`accessToken, refreshToken, email, firmId, firmName`, so a refresh needs to rebuild it from the
current session's other fields:

```dart
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final current = state;
    if (current == null) return;
    final updated = CloudSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      email: current.email,
      firmId: current.firmId,
      firmName: current.firmName,
    );
    await ref.read(globalPrefsProvider).setCloudSession(updated);
    state = updated;
  }
```

Add this method to `CloudSessionNotifier` in the same file, alongside `register`/`login`/`logout`.

`pushPending()`'s idempotency under a retry: add a one-line comment at the retry call site noting
it's outbox-driven and only clears server-accepted entries, so re-running it after a 401 is safe —
this was verified true by reading the existing code during spec review, not re-derived here.

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd app && flutter test test/features/cloud_sync_settings_test.dart && flutter test`

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/settings/cloud_sync_providers.dart app/test/features/cloud_sync_settings_test.dart
git commit -m "Sync: silent 401 token refresh with a single-flight guard against concurrent syncs"
```

---

## Task 11: PNG export wiring, keyboard-hint cleanup, and the 5 parked Android minors

**Files:**
- Modify: `app/lib/features/ledger/ledger_detail_screen.dart` — add "Export PNG" next to the
  existing "Export PDF" action.
- Modify: `app/lib/features/dashboard/dashboard_screen.dart`,
  `app/lib/features/customers/customers_screen.dart`, `app/lib/features/items/items_screen.dart`,
  `app/lib/features/customers/customer_form_screen.dart` — gate the five keyboard-hint strings
  behind `compact` (each file already threads a `compact` bool through, from the Android effort).
- Modify: `app/lib/shell/app_shell.dart` — the 600–695dp back-affordance gap (shell's `compact`
  check uses full window `MediaQuery` width; make it consistent with the screens' own
  `LayoutBuilder`-based `compact`, per the Android final review's Minor finding).
- Modify: `app/lib/features/bills/bill_screen.dart` — Edit-then-cancel-cleanly landing on the
  dashboard instead of the ledger it came from (prefer `d.editing?.customerId`'s ledger route when
  present, in `_escape`'s "not dirty" branch).
- Modify: `app/lib/printing/print_actions.dart` — the narrow duplicate-print risk if `disconnect()`
  itself throws after a successful write (guard the `logPrint` call so it only fires once even if
  `disconnect()` in the `finally` throws), and widen `on Exception` to `on Object` (or add a second
  `catch` clause) so a bare `Error` from the plugin's channel decoding also falls through to the
  PDF path instead of escaping unhandled.
- Modify: `app/test/features/print_bill_test.dart` — the one stale comment referencing an overflow
  already fixed.
- Test: extend the existing test files for each item above (not new files — these are small,
  targeted additions to files already covered by suites from the Android effort).

**Interfaces:** none new — every fix here calls existing functions/providers.

- [ ] **Step 1: PNG export — write the failing test, then wire it**

Add a test to `app/test/features/ledger_screen_test.dart` (or wherever Task 1 of the Android
effort's final fix wave added the "Export PDF" test — mirror it exactly for PNG), asserting
tapping `Key('ledger.detail.exportPng')` calls `exportedPngBaseNames` on the fake printing service.
Add the button next to the existing Export PDF one in `ledger_detail_screen.dart`, calling
`exportSlipPng` (already exists, unused until now) the same way the PDF button calls
`exportSlipPdf`.

- [ ] **Step 2: Keyboard-hint cleanup — one `if (!compact)` per site**

For each of the five strings (`"Ctrl+N adds one"` in `customers_screen.dart`/`items_screen.dart`,
`"Ctrl+Enter save · Esc back"` in `customer_form_screen.dart`/`items_screen.dart`'s item form,
`"Press Ctrl+N…"` on the dashboard), wrap the `Text` (or its containing row) in
`if (!compact) ...` — matching how this file already branches other content on `compact`. Add one
assertion per site to that file's existing test suite: at phone width, the hint text is absent
(`find.text(...)`, `findsNothing`); at desktop width, unchanged (`findsOneWidget`).

- [ ] **Step 3: The 600–695dp shell/screen breakpoint mismatch**

In `app_shell.dart`, find where `compact` is computed for the shell's own chrome decisions
(bottom nav/FAB visibility, back button) — if it reads `MediaQuery.of(context).size.width`, change
it to read from the same `LayoutBuilder` the shell's `Scaffold` is already built inside (the shell
itself is the outermost `LayoutBuilder` in the app, so its own `constraints.maxWidth` already *is*
the full window width at that level — the mismatch is between the shell's full-window
measurement and the *screens'* post-rail measurement, both of which should agree at the same
breakpoint since a screen's `LayoutBuilder` reports post-rail width. Confirm which side actually
needs adjusting by testing at `Size(640, 800)`: the shell should show the desktop rail exactly
when the *screen* would also render its desktop layout, so the two `compact` computations must
agree at every width, not just at 390 and 1280.) Add a widget test at `Size(640, 800)` asserting
the ledger detail screen's back button is reachable (this is the concrete symptom the Android
review found).

- [ ] **Step 4: Edit-then-cancel-cleanly navigation target**

In `bill_screen.dart`'s `_escape(d)`, the `!d.dirty` branch currently does `context.go('/')`
unconditionally. Change it to prefer the bill's own customer's ledger when editing an existing
bill: `context.go(d.editing?.customerId != null ? '/customers/${d.editing!.customerId}' : '/')`.
Add a test: open an existing bill for editing via the ledger, make no changes, cancel, assert the
route is the customer's ledger, not `/`.

- [ ] **Step 5: printSlip's duplicate-print risk and bare-Error handling**

In `print_actions.dart`'s `printSlip`, the Bluetooth branch's `finally { await service.disconnect(); }`
can itself throw after a successful `writeBytes`+`logPrint`. Restructure so the success path's
`return` isn't lost to a throwing `finally` — wrap the `disconnect()` call in its own
try/catch-and-ignore inside the `finally` block (a disconnect failure after a successful print is
not actionable and must never cause a second print), and change the outer `on Exception` to also
catch `Error` (either `on Object catch (_)` replacing it, or an additional `on Error catch (_)`
clause before it) so a malformed plugin response doesn't escape unhandled. Add a test simulating
`disconnect()` throwing after a successful write (extend `FakeThermalPrinterService` with a
`throwOnDisconnect` flag) and assert exactly one `printedJobs`/`logPrint` entry results, not two.

- [ ] **Step 6: The stale test comment**

In `print_bill_test.dart`, delete or update the comment referencing the `app_shell.dart` title-bar
overflow — that overflow was fixed in the Android effort's final review fix wave; the comment
should either be removed (if `seedMillPhone`'s short firm name is no longer needed for any other
reason) or corrected to state why the short name is still used, if it still is for an unrelated
reason.

- [ ] **Step 7: Run the full suite**

Run: `cd app && flutter test`
Expected: PASS, including all new assertions from steps 1-6.

- [ ] **Step 8: Commit**

```bash
git add -A app/
git commit -m "Close out 5 parked Android review items + PNG export wiring + keyboard-hint cleanup"
```

---

## Task 12: Final verification pass

This task has no code changes — it's the point where every prior task's assumptions get checked
together, matching the Android effort's own final-verification precedent.

- [ ] **Step 1: Full test suite, every package**

```bash
cd packages/ledgerly_core && dart test
cd packages/ledgerly_data && dart test
cd app && flutter test
cd backend && pytest
```

All green.

- [ ] **Step 2: Manual encryption walkthrough on a real build**

Using a real (or emulator) Android build: enable encryption on a firm with existing data, confirm
the app still opens it correctly after a full restart (not just within the same session), confirm
a backup taken after enabling encryption is present and the app can restore from it, confirm the
recovery-code path works by deliberately "forgetting" the passphrase.

- [ ] **Step 3: Manual Google sign-in walkthrough**

Once the Cloud Console setup from Task 9 is complete: sign in with a fresh Google account (new
firm created), sign out, sign in again (logs into the same firm), and test the
existing-password-account case (confirm the `409` message appears and that logging in normally
then using "Link Google account" from Settings completes the link).

- [ ] **Step 4: Commit any fixes found during manual verification, then stop — this task exists to
  surface problems, not to silently absorb new scope. Report anything found back to the
  controller/user rather than expanding this plan unilaterally.**
