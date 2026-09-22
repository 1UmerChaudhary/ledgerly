import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly_core/ledgerly_core.dart';

import '../../bootstrap/providers.dart';
import '../../theme/ledgerly_theme.dart';
import 'encryption_setup_screen.dart';

/// The screen an encrypted firm starts on. Nothing behind it is built until
/// the master key is in memory — the firm's database is not even opened, so
/// a wrong passphrase cannot leak so much as a row count.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _passphrase = TextEditingController();
  final _recoveryCode = TextEditingController();
  bool _recoveryVisible = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _passphrase.dispose();
    _recoveryCode.dispose();
    super.dispose();
  }

  String get _firmId => ref.read(globalPrefsProvider).lastFirmId!;

  Future<void> _unlock() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final masterKey = await ref
        .read(encryptionServiceProvider)
        .unlockWithPassphrase(_firmId, _passphrase.text);
    if (!mounted) return;
    if (masterKey == null) {
      setState(() {
        _busy = false;
        _error = 'That passphrase does not open this firm.';
      });
      return;
    }
    setState(() => _busy = false);
    ref.read(firmMasterKeyProvider.notifier).state = masterKey;
    context.go('/');
  }

  Future<void> _unlockWithRecoveryCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    // The KDF hashes the code as a string, so the code has to be put back
    // into the exact form it was printed in before it is handed over —
    // otherwise a person holding the right sheet is told it is wrong because
    // they typed it in lower case.
    final canonical = canonicaliseRecoveryCode(_recoveryCode.text);
    final masterKey = canonical == null
        ? null
        : await ref
              .read(encryptionServiceProvider)
              .unlockWithRecoveryCode(_firmId, canonical);
    if (!mounted) return;
    if (masterKey == null) {
      setState(() {
        _busy = false;
        _error = 'That recovery code does not open this firm.';
      });
      return;
    }
    setState(() => _busy = false);
    ref.read(firmMasterKeyProvider.notifier).state = masterKey;
    // Whoever needed the recovery path may equally have guessed at the old
    // passphrase; it is presumed compromised and must be replaced before the
    // rest of the app is reachable. The router enforces the "must".
    ref.read(passphraseResetRequiredProvider.notifier).state = true;
    context.go('/unlock/new-passphrase');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final gate = ref.watch(firmGateProvider);
    final unverifiable =
        gate.hasError || gate.value?.gate == FirmGate.unverifiable;
    return Scaffold(
      key: const Key('encryption.unlockScreen'),
      backgroundColor: c.paper,
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: unverifiable
                  ? _unverifiable(context)
                  : _unlockForm(context),
            ),
          ),
        ),
      ),
    );
  }

  /// A firm whose database could be classified neither as plaintext nor as
  /// ciphertext after an interrupted migration. Opening it anyway would
  /// surface much later as an unexplained SQLite error; this says what is
  /// actually wrong, and touches nothing.
  List<Widget> _unverifiable(BuildContext context) {
    final c = context.colors;
    final gate = ref.watch(firmGateProvider);
    final failure = gate.error ?? gate.value?.failure;
    return [
      Text(
        'CANNOT OPEN',
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1,
          fontWeight: FontWeight.w600,
          color: c.ink3,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        "This firm's database could not be verified",
        key: Key('encryption.unverifiable'),
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Text(
        'This firm was not opened, because what is on disk could not be '
        'checked: either turning encryption on was interrupted and the '
        'database file reads as neither encrypted nor unencrypted, or the '
        'checks that run before a firm opens did not pass. Nothing has been '
        'changed or deleted. Restore this firm from its most recent backup, '
        "or send this device's Ledgerly folder to support before using it "
        'again.',
        style: TextStyle(color: c.ink2),
      ),
      if (failure != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            '$failure',
            key: const Key('encryption.unverifiableDetail'),
            style: TextStyle(color: c.giveable, fontSize: 12.5),
          ),
        ),
      const SizedBox(height: 14),
      OutlinedButton(
        key: const Key('encryption.retryGate'),
        onPressed: () => ref.invalidate(firmGateProvider),
        child: const Text('Check again'),
      ),
    ];
  }

  List<Widget> _unlockForm(BuildContext context) {
    final c = context.colors;
    return [
      Text(
        'LOCKED',
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1,
          fontWeight: FontWeight.w600,
          color: c.ink3,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Enter your passphrase',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      Text(
        'This firm is encrypted. Nothing in it can be read until it is '
        'unlocked.',
        style: TextStyle(color: c.ink2),
      ),
      const SizedBox(height: 18),
      CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.enter): _unlock},
        child: TextField(
          key: const Key('encryption.unlockPassphrase'),
          controller: _passphrase,
          obscureText: true,
          autofocus: true,
          onSubmitted: (_) => _unlock(),
        ),
      ),
      const SizedBox(height: 12),
      FilledButton(
        key: const Key('encryption.unlock'),
        onPressed: _busy ? null : _unlock,
        style: FilledButton.styleFrom(backgroundColor: c.accent),
        child: const Text('Unlock'),
      ),
      const SizedBox(height: 6),
      TextButton(
        key: const Key('encryption.forgotPassphrase'),
        onPressed: () => setState(() {
          _recoveryVisible = true;
          _error = null;
        }),
        child: const Text('I lost my passphrase'),
      ),
      if (_recoveryVisible) ...[
        Text(
          'Type the recovery code from the sheet you printed when you turned '
          'encryption on.',
          style: TextStyle(color: c.ink2),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('encryption.recoveryCodeInput'),
          controller: _recoveryCode,
          style: numberStyle.copyWith(fontSize: 14),
          onSubmitted: (_) => _unlockWithRecoveryCode(),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          key: const Key('encryption.recoverySubmit'),
          onPressed: _busy ? null : _unlockWithRecoveryCode,
          child: const Text('Unlock with recovery code'),
        ),
      ],
      if (_error case final e?)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            e,
            key: const Key('encryption.unlockError'),
            style: TextStyle(color: c.giveable),
          ),
        ),
    ];
  }
}

/// Required immediately after a recovery-code unlock, and not skippable: the
/// router holds the app here until [passphraseResetRequiredProvider] clears,
/// which only happens when a replacement passphrase has actually been written
/// into the envelope.
class NewPassphraseScreen extends ConsumerStatefulWidget {
  const NewPassphraseScreen({super.key});

  @override
  ConsumerState<NewPassphraseScreen> createState() =>
      _NewPassphraseScreenState();
}

class _NewPassphraseScreenState extends ConsumerState<NewPassphraseScreen> {
  final _passphrase = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _passphrase.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_passphrase.text.trim().isEmpty) {
      setState(() => _error = 'Choose a passphrase.');
      return;
    }
    if (_passphrase.text != _confirm.text) {
      setState(() => _error = 'The two passphrases do not match.');
      return;
    }
    final masterKey = ref.read(firmMasterKeyProvider);
    if (masterKey == null) {
      setState(() => _error = 'This firm is locked again. Unlock it first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(encryptionServiceProvider)
          .changePassphrase(
            ref.read(globalPrefsProvider).lastFirmId!,
            masterKey: masterKey,
            newPassphrase: _passphrase.text,
          );
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$e';
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ref.read(passphraseResetRequiredProvider.notifier).state = false;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // The router bounces every *navigation* back here, but a pop -- the
    // Android back gesture, Esc, the title bar's back arrow -- does not run
    // redirects in go_router, so without this the one screen the spec calls
    // unskippable is exactly the one a back gesture skips.
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: const Key('encryption.newPassphraseScreen'),
        backgroundColor: c.paper,
        body: Center(
          child: SingleChildScrollView(
            child: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECOVERED',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                      color: c.ink3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Set a new passphrase',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You got in with the recovery code, so the old passphrase '
                    'is treated as compromised. Choose a new one to carry on. '
                    'Your recovery code is unchanged — generate a new one from '
                    'Settings if the sheet may have been seen.',
                    style: TextStyle(color: c.ink2),
                  ),
                  const SizedBox(height: 18),
                  PassphraseFields(
                    passphrase: _passphrase,
                    confirm: _confirm,
                    onChanged: () => setState(() {}),
                    autofocus: true,
                  ),
                  if (_error case final e?)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        e,
                        key: const Key('encryption.newPassphraseError'),
                        style: TextStyle(color: c.giveable),
                      ),
                    ),
                  FilledButton(
                    key: const Key('encryption.setNewPassphrase'),
                    onPressed: _busy ? null : _save,
                    style: FilledButton.styleFrom(backgroundColor: c.accent),
                    child: const Text('Save new passphrase'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
