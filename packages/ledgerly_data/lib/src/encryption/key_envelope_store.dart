import 'dart:convert';
import 'dart:io';

import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:meta/meta.dart';

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

  static Map<String, dynamic> _wrappedToJson(WrappedKey w) => {
    'nonce': w.nonce,
    'cipher_text': w.cipherText,
    'mac': w.mac,
  };

  static WrappedKey _wrappedFromJson(Map<String, dynamic> j) => WrappedKey(
    nonce: (j['nonce'] as List).cast<int>(),
    cipherText: (j['cipher_text'] as List).cast<int>(),
    mac: (j['mac'] as List).cast<int>(),
  );

  static KeyEnvelope fromJson(Map<String, dynamic> j) => KeyEnvelope(
    byPassphrase: _wrappedFromJson(j['by_passphrase'] as Map<String, dynamic>),
    passphraseSalt: (j['passphrase_salt'] as List).cast<int>(),
    byRecoveryCode: _wrappedFromJson(
      j['by_recovery_code'] as Map<String, dynamic>,
    ),
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

  /// Test-only hook: fires after the backup copy completes and before the
  /// final atomic rename, letting a test observe filesystem state at
  /// exactly the crash boundary during a real write(). No-op in production.
  @visibleForTesting
  Future<void> Function()? afterBackupHook;

  Future<KeyEnvelope?> read() async {
    if (!await path.exists()) return null;
    final text = await path.readAsString();
    try {
      return KeyEnvelope.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (e) {
      throw FormatException('Failed to parse envelope from ${path.path}: $e');
    }
  }

  Future<void> write(KeyEnvelope envelope) async {
    final tmp = File('${path.path}.tmp');
    await tmp.writeAsString(jsonEncode(envelope.toJson()), flush: true);
    if (await path.exists()) {
      await path.copy(_backupPath.path);
    }
    await afterBackupHook?.call();
    await tmp.rename(path.path);
  }

  /// Deletes the superseded envelope [write] left at `.bak`, once the file at
  /// the canonical path has been read back and confirmed to be [justWritten].
  ///
  /// Kept separate from [write] on purpose. `.bak` is crash insurance: for the
  /// length of a write there must be a complete, openable envelope on disk
  /// whatever happens, and deleting it as part of writing would reopen the
  /// window that insurance exists to close.
  ///
  /// After a passphrase change or a recovery-code rotation it stops being
  /// insurance and becomes a hole. A rotation re-wraps the SAME master key
  /// under a new secret; it never re-keys the database. So `.bak` is a
  /// complete, working envelope for the live database under the secret the
  /// user was just told is dead, and anyone who can read the folder -- the
  /// entire threat model encryption-at-rest addresses -- only has to rename
  /// it back. Callers that rotate a secret must call this; callers that write
  /// an envelope for the first time have no `.bak` and need not.
  ///
  /// A readback that does not match leaves `.bak` exactly where it is and
  /// throws: that combination means the new envelope did not land, and the
  /// superseded one is then the only way back into the firm.
  Future<void> retireBackup(KeyEnvelope justWritten) async {
    final onDisk = await read();
    if (onDisk == null ||
        jsonEncode(onDisk.toJson()) != jsonEncode(justWritten.toJson())) {
      throw StateError(
        'Refusing to retire the previous envelope at ${_backupPath.path}: '
        '${path.path} does not read back as the envelope just written, so it '
        'is still the only one that opens this firm.',
      );
    }
    if (await _backupPath.exists()) await _backupPath.delete();
  }

  File get _backupPath => File('${path.path}.bak');
}
