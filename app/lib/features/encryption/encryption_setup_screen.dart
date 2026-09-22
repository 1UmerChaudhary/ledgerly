import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:path/path.dart' as p;

import '../../bootstrap/providers.dart';
import '../../shell/breakpoints.dart';
import '../../theme/ledgerly_theme.dart';
import '../settings/settings_providers.dart';

/// Said in full, in the wizard, before the button that commits — not in a
/// tooltip and not after the fact. There is no support path behind this.
const kEncryptionWarning =
    'If you forget your passphrase and lose this recovery code, this '
    "firm's ledger cannot be recovered by anyone, including you or us.";

/// Something the person at the keyboard has to read and act on, as opposed to
/// a programming error. Thrown by the enrolment callbacks below so the panel
/// can print the message as written, without a `Bad state:` prefix in front
/// of it.
class EncryptionSetupFailure implements Exception {
  const EncryptionSetupFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The plaintext backups a firm accumulated before it was encrypted. They are
/// complete copies of the ledger with no passphrase on them, so encrypting
/// the live database while they sit in the backup folders protects nothing.
/// Deleting them is offered at the end of a migration and never done for the
/// user: they may be the only copies that exist.
class PlaintextBackupCleaner {
  const PlaintextBackupCleaner({required this.directories});

  final List<Directory> directories;

  /// Same naming rule as [BackupService]'s own scan: `<firmId>-<stamp>.db`.
  List<File> find(String firmId) => [
    for (final dir in directories)
      if (dir.existsSync())
        ...dir.listSync().whereType<File>().where(
          (f) =>
              p.basename(f.path).startsWith('$firmId-') &&
              f.path.endsWith('.db'),
        ),
  ];

  Future<void> delete(List<File> backups) async {
    for (final backup in backups) {
      if (backup.existsSync()) await backup.delete();
    }
  }
}

final plaintextBackupCleanerProvider = Provider<PlaintextBackupCleaner>((ref) {
  final folder = ref.watch(backupFolderProvider);
  return PlaintextBackupCleaner(
    directories: [
      ref.watch(appPathsProvider).backups,
      if (folder != null) Directory(folder),
    ],
  );
});

/// The passphrase pair every screen that sets one shares — initial setup, the
/// forced reset after a recovery-code unlock, the first-launch opt-in.
class PassphraseFields extends StatelessWidget {
  const PassphraseFields({
    super.key,
    required this.passphrase,
    required this.confirm,
    required this.onChanged,
    this.compact = false,
    this.autofocus = false,
  });

  final TextEditingController passphrase;
  final TextEditingController confirm;
  final VoidCallback onChanged;
  final bool compact;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _labelled(
        context,
        'Passphrase',
        TextField(
          key: const Key('encryption.passphrase'),
          controller: passphrase,
          obscureText: true,
          autofocus: autofocus,
          onChanged: (_) => onChanged(),
        ),
        compact: compact,
      ),
      _labelled(
        context,
        'Repeat it',
        TextField(
          key: const Key('encryption.passphraseConfirm'),
          controller: confirm,
          obscureText: true,
          onChanged: (_) => onChanged(),
        ),
        compact: compact,
      ),
    ],
  );
}

Widget _labelled(
  BuildContext context,
  String label,
  Widget child, {
  required bool compact,
}) {
  final text = Text(label, style: TextStyle(color: context.colors.ink2));
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [text, const SizedBox(height: 4), child],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: text,
                ),
              ),
              Expanded(child: child),
            ],
          ),
  );
}

/// Enrolling a firm in encryption, in the order the design spec insists on: a
/// passphrase, then a recovery code shown exactly once, then the code typed
/// back before anything is committed to the session.
///
/// [generate] and [commit] are supplied by the caller because the two callers
/// differ in what those words mean. A brand-new firm writes its envelope and
/// only then creates its database, so the file is ciphertext from birth; an
/// existing firm full of rows has to rewrite that file through
/// `migrateToEncrypted`. Both, though, only hand the session its master key
/// once the printed code has been proved legible.
class EncryptionEnrolmentPanel extends StatefulWidget {
  const EncryptionEnrolmentPanel({
    super.key,
    required this.generate,
    required this.commit,
    required this.commitLabel,
    required this.codeShownMessage,
    this.compact = false,
    this.autofocus = false,
  });

  /// Enrols the firm and returns the recovery code to show. Throwing shows
  /// the message on the panel and leaves the user on step one.
  final Future<String> Function(String passphrase) generate;

  /// Runs once the code has been typed back correctly.
  final Future<void> Function(String passphrase) commit;

  final String commitLabel;

  /// What the code step says above the code. The two callers need genuinely
  /// different words here: for a brand-new firm nothing exists yet and this
  /// step is still part of setting it up, while a migrated firm is ALREADY
  /// encrypted by the time its code is on screen -- its copy has to say so,
  /// or a user who walks away believes nothing happened and writes nothing
  /// down.
  final String codeShownMessage;

  final bool compact;
  final bool autofocus;

  @override
  State<EncryptionEnrolmentPanel> createState() =>
      _EncryptionEnrolmentPanelState();
}

class _EncryptionEnrolmentPanelState extends State<EncryptionEnrolmentPanel> {
  final _passphrase = TextEditingController();
  final _confirm = TextEditingController();
  final _typedBack = TextEditingController();
  String? _recoveryCode;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _passphrase.dispose();
    _confirm.dispose();
    _typedBack.dispose();
    super.dispose();
  }

  /// A code copied off a printed sheet arrives in whatever case and spacing
  /// the person used; what matters is that it decodes to the same secret.
  bool get _typedBackMatches =>
      _recoveryCode != null &&
      canonicaliseRecoveryCode(_typedBack.text) == _recoveryCode;

  Future<void> _generate() async {
    final passphrase = _passphrase.text;
    if (passphrase.trim().isEmpty) {
      setState(() => _error = 'Choose a passphrase first.');
      return;
    }
    if (passphrase != _confirm.text) {
      setState(() => _error = 'The two passphrases do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = await widget.generate(passphrase);
      if (mounted) setState(() => _recoveryCode = code);
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _commit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.commit(_passphrase.text);
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final code = _recoveryCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (code == null) ...[
          PassphraseFields(
            passphrase: _passphrase,
            confirm: _confirm,
            onChanged: () => setState(() {}),
            compact: widget.compact,
            autofocus: widget.autofocus,
          ),
          Text(
            kEncryptionWarning,
            key: const Key('encryption.warning'),
            style: TextStyle(color: c.giveable, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('encryption.generate'),
            onPressed: _busy ? null : _generate,
            style: FilledButton.styleFrom(backgroundColor: c.accent),
            child: const Text('Generate recovery code'),
          ),
        ] else ...[
          Text(
            widget.codeShownMessage,
            key: const Key('encryption.codeShownMessage'),
            style: TextStyle(color: c.ink2),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.accentSoft,
              borderRadius: BorderRadius.circular(4),
            ),
            child: SelectableText(
              code,
              key: const Key('encryption.recoveryCode'),
              style: numberStyle.copyWith(fontSize: 15, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 12),
          _labelled(
            context,
            'Type it back',
            TextField(
              key: const Key('encryption.recoveryCodeConfirm'),
              controller: _typedBack,
              style: numberStyle.copyWith(fontSize: 14),
              onChanged: (_) => setState(() {}),
            ),
            compact: widget.compact,
          ),
          Text(
            kEncryptionWarning,
            key: const Key('encryption.warning'),
            style: TextStyle(color: c.giveable, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('encryption.confirmEnable'),
            // Disabled, not merely ignored on tap: the button says plainly
            // that the code has not been typed back correctly yet.
            onPressed: _busy || !_typedBackMatches ? null : _commit,
            style: FilledButton.styleFrom(backgroundColor: c.accent),
            child: Text(widget.commitLabel),
          ),
        ],
        if (_error case final e?)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              e,
              key: const Key('encryption.setupError'),
              style: TextStyle(color: c.giveable),
            ),
          ),
      ],
    );
  }
}

/// Turning encryption on for a firm that already exists, and therefore
/// already has a plaintext database file full of rows: the wizard reached
/// from Settings.
class EncryptionSetupScreen extends ConsumerStatefulWidget {
  const EncryptionSetupScreen({super.key});

  @override
  ConsumerState<EncryptionSetupScreen> createState() =>
      _EncryptionSetupScreenState();
}

class _EncryptionSetupScreenState extends ConsumerState<EncryptionSetupScreen> {
  List<File>? _plaintextBackups;
  bool _done = false;
  String? _message;

  Future<String> _migrate(String passphrase) async {
    final firm = ref.read(openFirmProvider).value;
    if (firm == null) {
      throw const EncryptionSetupFailure('No firm is open.');
    }
    final firmId = firm.ctx.firmId;
    // sqlcipher_export rewrites the live file, so SQLite must not have it
    // open. If anything fails after this, reopening is what puts the app
    // back on its feet — the migration itself leaves the plaintext original
    // untouched until it has proved the encrypted copy good.
    await firm.db.close();
    try {
      late String recoveryCode;
      await ref
          .read(encryptionServiceProvider)
          .migrateToEncrypted(
            firmId,
            passphrase: passphrase,
            onRecoveryCodeGenerated: (code) => recoveryCode = code,
          );
      return recoveryCode;
    } on Object {
      ref.invalidate(openFirmProvider);
      rethrow;
    }
  }

  Future<void> _commit(String passphrase) async {
    final firmId = ref.read(globalPrefsProvider).lastFirmId!;
    final masterKey = await ref
        .read(encryptionServiceProvider)
        .unlockWithPassphrase(firmId, passphrase);
    if (masterKey == null) {
      throw const EncryptionSetupFailure(
        'The new passphrase did not unlock the firm. Use the recovery code '
        'shown above to get back in.',
      );
    }
    // Setting the key re-runs the gate, which reopens the firm keyed.
    ref.read(firmMasterKeyProvider.notifier).state = masterKey;
    final backups = ref.read(plaintextBackupCleanerProvider).find(firmId);
    if (mounted) {
      setState(() {
        _done = true;
        _plaintextBackups = backups;
      });
    }
  }

  Future<void> _deleteOldBackups() async {
    final backups = _plaintextBackups ?? const <File>[];
    await ref.read(plaintextBackupCleanerProvider).delete(backups);
    if (mounted) {
      setState(() {
        _plaintextBackups = const [];
        _message =
            'Deleted ${backups.length} plaintext backup'
            '${backups.length == 1 ? '' : 's'}.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      key: const Key('encryption.setupWizard'),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      child: SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < kCompactBreakpoint;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ENCRYPTION',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                    color: c.ink3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Protect this firm with a passphrase',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  "This firm's database is rewritten as encrypted. It can "
                  'only be opened afterwards with the passphrase you choose '
                  'or the recovery code below.',
                  style: TextStyle(color: c.ink2),
                ),
                const SizedBox(height: 18),
                if (_done)
                  _finished(context)
                else
                  EncryptionEnrolmentPanel(
                    generate: _migrate,
                    commit: _commit,
                    // Both of these are worded for what is already true by
                    // the time this step renders: the database has been
                    // rewritten as ciphertext and the passphrase just entered
                    // is the one that opens it. Calling the button "Enable
                    // encryption" here would tell a user who walks away that
                    // nothing has happened yet -- and they would take the one
                    // thing they can never get again, this code, with them.
                    codeShownMessage:
                        'Encryption is now ON for this firm, and the '
                        'passphrase you just entered is what opens it. This '
                        'recovery code is the only other way in, it is shown '
                        'once, and it is never shown again. Write it down or '
                        'print it now, then type it back below.',
                    commitLabel: "I've written it down — continue",
                    compact: compact,
                    autofocus: true,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _finished(BuildContext context) {
    final c = context.colors;
    final backups = _plaintextBackups ?? const <File>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Encryption is on. This firm now opens with your passphrase.',
          key: const Key('encryption.enabled'),
          style: TextStyle(color: c.receivable),
        ),
        const SizedBox(height: 14),
        if (backups.isNotEmpty) ...[
          Text(
            '${backups.length} plaintext backup'
            '${backups.length == 1 ? '' : 's'} of this firm '
            '${backups.length == 1 ? 'was' : 'were'} taken before encryption '
            'was turned on. They are complete, unprotected copies of the '
            'ledger.',
            key: const Key('encryption.plaintextBackups'),
            style: TextStyle(color: c.giveable),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('encryption.deleteOldBackups'),
            onPressed: _deleteOldBackups,
            child: const Text('Delete these now'),
          ),
        ],
        if (_message case final m?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(m, style: TextStyle(color: c.ink2)),
          ),
        const SizedBox(height: 14),
        FilledButton(
          key: const Key('encryption.setupDone'),
          onPressed: () => context.go('/settings'),
          style: FilledButton.styleFrom(backgroundColor: c.accent),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

/// Changing the passphrase, and generating a new recovery code, both start by
/// asking for the current passphrase again — never by reusing the master key
/// this session already holds. The session key proves someone unlocked the
/// firm at some point; it does not prove the person at the keyboard right now
/// is the one who did.
class ChangePassphraseDialog extends ConsumerStatefulWidget {
  const ChangePassphraseDialog({super.key});

  @override
  ConsumerState<ChangePassphraseDialog> createState() =>
      _ChangePassphraseDialogState();
}

class _ChangePassphraseDialogState
    extends ConsumerState<ChangePassphraseDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_next.text.trim().isEmpty) {
      setState(() => _error = 'Choose a new passphrase.');
      return;
    }
    if (_next.text != _confirm.text) {
      setState(() => _error = 'The two new passphrases do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final firmId = ref.read(globalPrefsProvider).lastFirmId!;
    final encryption = ref.read(encryptionServiceProvider);
    final masterKey = await encryption.unlockWithPassphrase(
      firmId,
      _current.text,
    );
    if (!mounted) return;
    if (masterKey == null) {
      setState(() {
        _busy = false;
        _error = 'That is not the current passphrase.';
      });
      return;
    }
    try {
      await encryption.changePassphrase(
        firmId,
        masterKey: masterKey,
        newPassphrase: _next.text,
      );
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$e';
        });
      }
      return;
    } finally {
      // Not the session key -- a second, transient copy unwrapped a few lines
      // up purely to re-wrap under the new passphrase. Same care lockFirm
      // takes: it does not outlive the job it was unwrapped for.
      masterKey.fillRange(0, masterKey.length, 0);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const Key('encryption.changePassphraseDialog'),
    title: const Text('Change passphrase'),
    content: SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current passphrase'),
          TextField(
            key: const Key('encryption.currentPassphrase'),
            controller: _current,
            obscureText: true,
            autofocus: true,
          ),
          const SizedBox(height: 10),
          const Text('New passphrase'),
          TextField(
            key: const Key('encryption.newPassphrase'),
            controller: _next,
            obscureText: true,
          ),
          const SizedBox(height: 10),
          const Text('Repeat the new passphrase'),
          TextField(
            key: const Key('encryption.newPassphraseConfirm'),
            controller: _confirm,
            obscureText: true,
          ),
          if (_error case final e?)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                e,
                key: const Key('encryption.passphraseError'),
                style: TextStyle(color: context.colors.giveable),
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        key: const Key('encryption.changePassphraseCancel'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('encryption.changePassphraseSubmit'),
        onPressed: _busy ? null : _submit,
        child: const Text('Change passphrase'),
      ),
    ],
  );
}

/// Mints a fresh recovery code and shows it once. The old one stops working
/// the moment this completes, which is the entire point: it is what a user
/// does when the printed sheet may have been seen.
class RotateRecoveryCodeDialog extends ConsumerStatefulWidget {
  const RotateRecoveryCodeDialog({super.key});

  @override
  ConsumerState<RotateRecoveryCodeDialog> createState() =>
      _RotateRecoveryCodeDialogState();
}

class _RotateRecoveryCodeDialogState
    extends ConsumerState<RotateRecoveryCodeDialog> {
  final _current = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _newCode;

  @override
  void dispose() {
    _current.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final firmId = ref.read(globalPrefsProvider).lastFirmId!;
    final encryption = ref.read(encryptionServiceProvider);
    final masterKey = await encryption.unlockWithPassphrase(
      firmId,
      _current.text,
    );
    if (!mounted) return;
    if (masterKey == null) {
      setState(() {
        _busy = false;
        _error = 'That is not the current passphrase.';
      });
      return;
    }
    final String code;
    try {
      code = await encryption.rotateRecoveryCode(firmId, masterKey: masterKey);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$e';
        });
      }
      return;
    } finally {
      // As above: a transient copy, zeroed the moment it has done its job.
      masterKey.fillRange(0, masterKey.length, 0);
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _newCode = code;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final code = _newCode;
    return AlertDialog(
      key: const Key('encryption.rotateRecoveryCodeDialog'),
      title: const Text('Generate a new recovery code'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: code == null
              ? [
                  Text(
                    'The current recovery code stops working as soon as the '
                    'new one is generated.',
                    style: TextStyle(color: c.ink2),
                  ),
                  const SizedBox(height: 10),
                  const Text('Current passphrase'),
                  TextField(
                    key: const Key('encryption.currentPassphrase'),
                    controller: _current,
                    obscureText: true,
                    autofocus: true,
                  ),
                  if (_error case final e?)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        e,
                        key: const Key('encryption.passphraseError'),
                        style: TextStyle(color: c.giveable),
                      ),
                    ),
                ]
              : [
                  Text(
                    'Write this down or print it. It is shown once, and the '
                    'old code no longer opens this firm.',
                    style: TextStyle(color: c.ink2),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.accentSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      code,
                      key: const Key('encryption.recoveryCode'),
                      style: numberStyle.copyWith(
                        fontSize: 15,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
        ),
      ),
      actions: code == null
          ? [
              TextButton(
                key: const Key('encryption.rotateRecoveryCodeCancel'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const Key('encryption.rotateRecoveryCodeSubmit'),
                onPressed: _busy ? null : _submit,
                child: const Text('Generate'),
              ),
            ]
          : [
              FilledButton(
                key: const Key('encryption.rotateRecoveryCodeDone'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('I have written it down'),
              ),
            ],
    );
  }
}
