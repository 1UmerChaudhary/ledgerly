import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../../bootstrap/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shell/breakpoints.dart';
import '../../theme/ledgerly_theme.dart';
import '../encryption/encryption_setup_screen.dart';

class FirstLaunchScreen extends ConsumerStatefulWidget {
  const FirstLaunchScreen({super.key});

  @override
  ConsumerState<FirstLaunchScreen> createState() => _FirstLaunchScreenState();
}

class _FirstLaunchScreenState extends ConsumerState<FirstLaunchScreen> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _address = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _encrypt = false;

  /// Minted here rather than inside [createFirstFirm] because the envelope
  /// has to exist, and its master key has to be in this session, BEFORE the
  /// database file is created — that is what makes a firm encrypted from its
  /// first byte instead of migrated afterwards.
  String? _enrolledFirmId;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _address.dispose();
    super.dispose();
  }

  bool _detailsMissing() {
    final l10n = L10n.of(context);
    if (_name.text.trim().isNotEmpty && _contact.text.trim().isNotEmpty) {
      return false;
    }
    setState(
      () => _error = '${l10n.firmName} and ${l10n.contactNumber} are required.',
    );
    return true;
  }

  Future<void> _create() async {
    // With encryption chosen, the enrolment panel owns creation: the firm
    // must not exist until its key does. Ctrl+Enter falls through to nothing
    // here rather than creating a plaintext firm behind the panel's back.
    if (_encrypt) return;
    if (_detailsMissing()) return;
    setState(() => _busy = true);
    await ref
        .read(firmCreatorProvider)
        .create(
          name: _name.text.trim(),
          contactNumber: _contact.text.trim(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        );
  }

  /// Writes the envelope for a firm that does not exist yet. If the user
  /// abandons the wizard here, all that is left behind is an orphan
  /// `<id>.key.json` for an id nothing ever references.
  Future<String> _enrol(String passphrase) async {
    if (_detailsMissing()) {
      throw const EncryptionSetupFailure(
        'Fill in the firm name and contact number first.',
      );
    }
    final firmId = _enrolledFirmId ?? newId();
    _enrolledFirmId = firmId;
    late String recoveryCode;
    await ref
        .read(encryptionServiceProvider)
        .enableEncryption(
          firmId,
          passphrase: passphrase,
          onRecoveryCodeGenerated: (code) => recoveryCode = code,
        );
    return recoveryCode;
  }

  Future<void> _createEncrypted(String passphrase) async {
    final firmId = _enrolledFirmId!;
    final masterKey = await ref
        .read(encryptionServiceProvider)
        .unlockWithPassphrase(firmId, passphrase);
    if (masterKey == null) {
      throw const EncryptionSetupFailure(
        'The passphrase did not open the new key.',
      );
    }
    // Before create: the database opener reads this to key the connection,
    // and that connection is the one that creates the file.
    ref.read(firmMasterKeyProvider.notifier).state = masterKey;
    await ref
        .read(firmCreatorProvider)
        .create(
          name: _name.text.trim(),
          contactNumber: _contact.text.trim(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          firmId: firmId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = L10n.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _create,
      },
      child: Scaffold(
        backgroundColor: c.paper,
        // Same responsive shape as every other form screen: below
        // kCompactBreakpoint the fixed 560px column would be wider than the
        // viewport, and this screen's content now grows by a whole enrolment
        // panel when encryption is switched on -- with a keyboard up on a
        // phone the irreversibility warning and the recovery code itself are
        // exactly what a non-scrolling Column clips off the bottom.
        body: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < kCompactBreakpoint;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: SizedBox(
                  width: compact ? constraints.maxWidth - 32 : 560,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WELCOME',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                          color: c.ink3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.setupTitle,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.setupSubtitle, style: TextStyle(color: c.ink2)),
                      const SizedBox(height: 22),
                      _Field(
                        label: l10n.firmName,
                        compact: compact,
                        child: TextField(
                          key: const Key('setup.firmName'),
                          controller: _name,
                          autofocus: true,
                        ),
                      ),
                      _Field(
                        label: l10n.contactNumber,
                        compact: compact,
                        child: TextField(
                          key: const Key('setup.contact'),
                          controller: _contact,
                        ),
                      ),
                      _Field(
                        label: l10n.address,
                        compact: compact,
                        child: TextField(
                          key: const Key('setup.address'),
                          controller: _address,
                          decoration: InputDecoration(hintText: l10n.optional),
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _error!,
                            style: TextStyle(color: c.giveable),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Switch(
                            key: const Key('setup.enableEncryption'),
                            value: _encrypt,
                            onChanged: (on) => setState(() => _encrypt = on),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Protect this firm with a passphrase',
                              style: TextStyle(color: c.ink2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_encrypt)
                        EncryptionEnrolmentPanel(
                          generate: _enrol,
                          commit: _createEncrypted,
                          // Nothing is on disk at this step but an envelope
                          // for an id nothing references yet, so this one
                          // really is still "before": the firm itself is
                          // created by the button below.
                          codeShownMessage:
                              "This is the recovery code for the firm you're "
                              'about to create. It is shown once and never '
                              'again: write it down or print it, then type it '
                              'back below.',
                          commitLabel: l10n.createFirm,
                          compact: compact,
                        )
                      else
                        FilledButton(
                          onPressed: _busy ? null : _create,
                          style: FilledButton.styleFrom(
                            backgroundColor: c.accent,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l10n.createFirm),
                              const SizedBox(width: 10),
                              Text(
                                'Ctrl+Enter',
                                style: numberStyle.copyWith(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.child,
    required this.compact,
  });
  final String label;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      label,
      style: TextStyle(color: context.colors.ink2),
    );
    // Below the breakpoint the label stacks above its field instead of
    // sitting in a fixed 130px gutter beside it, same as every other form.
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelWidget, const SizedBox(height: 4), child],
            )
          : Row(
              children: [
                SizedBox(width: 130, child: labelWidget),
                Expanded(child: child),
              ],
            ),
    );
  }
}
