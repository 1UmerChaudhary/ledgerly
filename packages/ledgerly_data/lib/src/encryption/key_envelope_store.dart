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
