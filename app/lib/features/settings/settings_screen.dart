import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../../bootstrap/providers.dart';
import '../../printing/print_actions.dart';
import '../../printing/printing_service.dart';
import '../../printing/thermal_printer_service.dart';
import '../../shell/breakpoints.dart';
import '../../sync/backend_client.dart';
import '../../theme/ledgerly_theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../encryption/encryption_setup_screen.dart';
import 'cloud_sync_providers.dart';
import 'settings_providers.dart';

/// Sentinel returned by the printer dialog's "Ask each time" option, kept
/// distinct from `null` so dismissing the dialog (also `null`) means
/// "no change" rather than "clear the default".
class _ClearPrinter {
  const _ClearPrinter();
}

const _clearPrinter = _ClearPrinter();

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _address = TextEditingController();
  final _folder = TextEditingController();
  final _backendUrl = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loaded = false;
  String? _message;
  String? _cloudError;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _address.dispose();
    _folder.dispose();
    _backendUrl.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _fill(Firm firm, String? folder) {
    if (_loaded) return;
    _loaded = true;
    _name.text = firm.name;
    _contact.text = firm.contactNumber;
    _address.text = firm.address ?? '';
    _folder.text = folder ?? '';
    _backendUrl.text =
        ref.read(globalPrefsProvider).backendUrl ?? defaultBackendUrl;
  }

  Future<void> _saveFirm() async {
    final firm = ref.read(openFirmProvider).value;
    if (firm == null) return;
    await FirmsRepository(firm.db, firm.ctx).update(
      name: _name.text.trim().isEmpty ? null : _name.text.trim(),
      contactNumber: _contact.text.trim().isEmpty ? null : _contact.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      clearAddress: _address.text.trim().isEmpty,
    );
    await ref.read(backupFolderProvider.notifier).set(_folder.text);
    ref.invalidate(firmSettingsProvider);
    setState(() => _message = 'Saved.');
  }

  Future<void> _toggle({bool? showPaisa, NumberGrouping? grouping}) async {
    final firm = ref.read(openFirmProvider).value;
    if (firm == null) return;
    await FirmsRepository(
      firm.db,
      firm.ctx,
    ).update(showPaisa: showPaisa, grouping: grouping);
    ref.invalidate(firmSettingsProvider);
    ref.invalidate(dashboardRowsProvider);
  }

  Future<void> _choosePrinter() async {
    final printers = await ref.read(printerDiscoveryProvider).list();
    if (!mounted) return;
    final result = await showDialog<Object?>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        key: const Key('settings.printerDialog'),
        title: const Text('Choose a printer'),
        children: [
          SimpleDialogOption(
            key: const Key('settings.printerOption.none'),
            onPressed: () => Navigator.of(dialogContext).pop(_clearPrinter),
            child: const Text('Ask each time (no default)'),
          ),
          for (final p in printers)
            SimpleDialogOption(
              key: Key('settings.printerOption.${p.name}'),
              onPressed: () => Navigator.of(dialogContext).pop(p),
              child: Text(p.name),
            ),
        ],
      ),
    );
    if (result == null) return; // dismissed: leave the current choice as-is
    final chosen = result == _clearPrinter ? null : result as PrinterInfo;
    await ref.read(printerChoiceProvider.notifier).set(chosen);
  }

  Future<void> _chooseThermalPrinter() async {
    final printers = await ref
        .read(thermalPrinterServiceProvider)
        .pairedPrinters();
    if (!mounted) return;
    final picked = await showDialog<BluetoothPrinterInfo>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        key: const Key('settings.thermalPrinterDialog'),
        title: const Text('Choose a Bluetooth printer'),
        children: [
          for (final p in printers)
            SimpleDialogOption(
              key: Key('settings.thermalPrinterOption.${p.name}'),
              onPressed: () => Navigator.of(dialogContext).pop(p),
              child: Text(p.name),
            ),
        ],
      ),
    );
    if (picked == null) return;
    await ref
        .read(globalPrefsProvider)
        .setThermalPrinter(name: picked.name, mac: picked.mac);
    setState(() {});
  }

  Future<void> _browseFolder() async {
    final picked = await ref.read(nativePickersProvider).pickFolder();
    if (picked != null) setState(() => _folder.text = picked);
  }

  Future<bool> _confirmRestore(String path) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('settings.restoreConfirm'),
        title: const Text('Restore from backup?'),
        content: Text(
          'This replaces everything in the current firm with the backup '
          'at $path. This cannot be undone.',
        ),
        actions: [
          TextButton(
            key: const Key('settings.restoreConfirm.cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('settings.restoreConfirm.confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _restore() async {
    try {
      final outcome = await restoreFromPickedFile(
        ref,
        confirm: _confirmRestore,
      );
      if (outcome == RestoreOutcome.success && mounted) {
        setState(() => _message = 'Restored. Reopening the firm…');
      }
    } on RestoreFailure catch (e) {
      if (mounted) setState(() => _message = e.message);
    }
  }

  Future<void> _changePassphrase() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const ChangePassphraseDialog(),
    );
  }

  Future<void> _rotateRecoveryCode() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const RotateRecoveryCodeDialog(),
    );
  }

  Future<void> _saveBackendUrl() async {
    final url = _backendUrl.text.trim();
    await ref.read(globalPrefsProvider).setBackendUrl(url.isEmpty ? null : url);
  }

  Future<void> _register() async {
    setState(() => _cloudError = null);
    await _saveBackendUrl();
    try {
      await ref
          .read(cloudSessionProvider.notifier)
          .register(
            name: _name.text.trim().isEmpty ? 'Owner' : _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          );
      _password.clear();
    } on BackendException catch (e) {
      if (mounted) setState(() => _cloudError = e.message);
    }
  }

  Future<void> _login() async {
    setState(() => _cloudError = null);
    await _saveBackendUrl();
    try {
      await ref
          .read(cloudSessionProvider.notifier)
          .login(email: _email.text.trim(), password: _password.text);
      _password.clear();
    } on BackendException catch (e) {
      if (mounted) setState(() => _cloudError = e.message);
    }
  }

  Future<void> _disconnect() =>
      ref.read(cloudSessionProvider.notifier).logout();

  Future<void> _syncNow() => ref.read(syncRunnerProvider.notifier).syncNow();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final firm = ref.watch(firmSettingsProvider).value;
    final folder = ref.watch(backupFolderProvider);
    final backup = ref.watch(backupRunnerProvider);
    final printer = ref.watch(printerChoiceProvider);
    final cloudSession = ref.watch(cloudSessionProvider);
    final encrypted = ref.watch(firmEncryptedProvider).value ?? false;
    final syncStatus = ref.watch(syncRunnerProvider);
    if (firm != null) _fill(firm, folder);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            _saveFirm,
        const SingleActivator(LogicalKeyboardKey.numpadEnter, control: true):
            _saveFirm,
        const SingleActivator(LogicalKeyboardKey.escape): () => context.go('/'),
      },
      child: Padding(
        key: const Key('settings.screen'),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        // A plain ListView is Sliver-backed and lazily estimates far-off
        // children's extents; on this screen's mix of fixed- and
        // conditionally-sized rows that estimate can undershoot, so the
        // sliver stops building before the last section ever exists in the
        // tree (no error -- it just silently isn't there). A settings
        // screen's content is small and bounded, so build all of it as an
        // ordinary Column and let this scroll instead.
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // _field's 130px label + 520px field Row below is a fixed
              // 650px-wide desktop layout; below kCompactBreakpoint the
              // label stacks above the field instead of beside it, same
              // convention as customer_form_screen.dart/items_screen.dart's
              // form fields. Computed once here and threaded through every
              // row on the screen, so fixing this one flag fixes every
              // _field call site instead of each row re-deriving it.
              final compact = constraints.maxWidth < kCompactBreakpoint;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'SETTINGS',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                      color: c.ink3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _section(context, 'Firm', [
                    _field(
                      'Firm name',
                      TextField(
                        key: const Key('settings.firmName'),
                        controller: _name,
                        autofocus: true,
                      ),
                      compact: compact,
                    ),
                    _field(
                      'Contact',
                      TextField(
                        key: const Key('settings.contact'),
                        controller: _contact,
                        style: numberStyle.copyWith(fontSize: 14),
                      ),
                      compact: compact,
                    ),
                    _field(
                      'Address',
                      TextField(
                        key: const Key('settings.address'),
                        controller: _address,
                      ),
                      compact: compact,
                    ),
                  ]),
                  _section(context, 'Display', [
                    _field(
                      'Show paisa',
                      Row(
                        children: [
                          Switch(
                            key: const Key('settings.showPaisa'),
                            value: firm?.showPaisa ?? false,
                            onChanged: (v) => _toggle(showPaisa: v),
                          ),
                          const SizedBox(width: 8),
                          // Above kCompactBreakpoint this Text is unchanged.
                          // Below it, the field no longer has a fixed 520px
                          // box to sit in -- Expanded stops it forcing extra
                          // Row width there, same compact ? ... : ...
                          // gating as this file's other sites.
                          if (compact)
                            Expanded(
                              child: Text(
                                firm?.showPaisa ?? false
                                    ? 'Rs 6,02,835.72'
                                    : 'Rs 6,02,836 (whole rupees)',
                                style: numberStyle.copyWith(
                                  fontSize: 13,
                                  color: c.ink2,
                                ),
                              ),
                            )
                          else
                            Text(
                              firm?.showPaisa ?? false
                                  ? 'Rs 6,02,835.72'
                                  : 'Rs 6,02,836 (whole rupees)',
                              style: numberStyle.copyWith(
                                fontSize: 13,
                                color: c.ink2,
                              ),
                            ),
                        ],
                      ),
                      compact: compact,
                    ),
                    _field(
                      'Grouping',
                      SegmentedButton<NumberGrouping>(
                        key: const Key('settings.grouping'),
                        segments: const [
                          ButtonSegment(
                            value: NumberGrouping.pakistani,
                            label: Text('12,34,567'),
                          ),
                          ButtonSegment(
                            value: NumberGrouping.western,
                            label: Text('1,234,567'),
                          ),
                        ],
                        selected: {firm?.grouping ?? NumberGrouping.pakistani},
                        onSelectionChanged: (s) => _toggle(grouping: s.first),
                      ),
                      compact: compact,
                    ),
                  ]),
                  _section(context, 'Printer', [
                    _field(
                      'Default printer',
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              printer?.name ?? 'Ask each time',
                              style: TextStyle(color: c.ink2),
                            ),
                          ),
                          const SizedBox(width: 14),
                          OutlinedButton(
                            key: const Key('settings.choosePrinter'),
                            onPressed: _choosePrinter,
                            child: const Text('Choose printer…'),
                          ),
                        ],
                      ),
                      compact: compact,
                    ),
                  ]),
                  // Android-only, matching printSlip's own gate: on desktop
                  // the Bluetooth path is never taken, so offering the
                  // picker there would only let a user reroute their slips
                  // away from the OS printer they configured above.
                  if (defaultTargetPlatform == TargetPlatform.android)
                    _section(context, 'Bluetooth printer', [
                      _field(
                        'Thermal printer',
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ref
                                        .watch(globalPrefsProvider)
                                        .thermalPrinterName ??
                                    'None selected',
                                style: TextStyle(color: c.ink2),
                              ),
                            ),
                            const SizedBox(width: 14),
                            OutlinedButton(
                              key: const Key('settings.thermalPrinterPicker'),
                              onPressed: _chooseThermalPrinter,
                              child: const Text('Choose printer…'),
                            ),
                          ],
                        ),
                        compact: compact,
                      ),
                    ]),
                  _section(context, 'Cloud sync', [
                    _field(
                      'Server',
                      TextField(
                        key: const Key('settings.backendUrl'),
                        controller: _backendUrl,
                        style: numberStyle.copyWith(fontSize: 13),
                        onSubmitted: (_) => _saveBackendUrl(),
                      ),
                      compact: compact,
                    ),
                    if (cloudSession == null) ...[
                      _field(
                        'Email',
                        TextField(
                          key: const Key('settings.cloudEmail'),
                          controller: _email,
                        ),
                        compact: compact,
                      ),
                      _field(
                        'Password',
                        TextField(
                          key: const Key('settings.cloudPassword'),
                          controller: _password,
                          obscureText: true,
                        ),
                        compact: compact,
                      ),
                      _field(
                        '',
                        // The two buttons' combined intrinsic width is close
                        // enough to a phone viewport that a Row overflows --
                        // below kCompactBreakpoint use Wrap instead, which
                        // drops "Log in" to its own line rather than
                        // overflowing (same reasoning as ledger_screen.dart's
                        // header split); above it, the Row is unchanged.
                        compact
                            ? Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton(
                                    key: const Key('settings.cloudRegister'),
                                    onPressed: _register,
                                    child: const Text('Create cloud account'),
                                  ),
                                  OutlinedButton(
                                    key: const Key('settings.cloudLogin'),
                                    onPressed: _login,
                                    child: const Text('Log in'),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  OutlinedButton(
                                    key: const Key('settings.cloudRegister'),
                                    onPressed: _register,
                                    child: const Text('Create cloud account'),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    key: const Key('settings.cloudLogin'),
                                    onPressed: _login,
                                    child: const Text('Log in'),
                                  ),
                                ],
                              ),
                        compact: compact,
                      ),
                      if (_cloudError case final e?)
                        Padding(
                          padding: EdgeInsets.only(left: compact ? 0 : 130),
                          child: Text(
                            e,
                            key: const Key('settings.cloudError'),
                            style: TextStyle(color: c.giveable, fontSize: 12.5),
                          ),
                        ),
                    ] else ...[
                      _field(
                        'Connected',
                        Text(
                          key: const Key('settings.cloudConnected'),
                          '${cloudSession.email} — ${cloudSession.firmName}',
                          style: TextStyle(color: c.ink2),
                        ),
                        compact: compact,
                      ),
                      _field(
                        'Sync',
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                syncStatus.error ??
                                    (syncStatus.running
                                        ? 'Syncing…'
                                        : syncStatus.summary ??
                                              'Not yet in this session'),
                                key: const Key('settings.syncStatus'),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: syncStatus.error != null
                                      ? c.giveable
                                      : c.ink2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            FilledButton(
                              key: const Key('settings.syncNow'),
                              onPressed: syncStatus.running ? null : _syncNow,
                              child: const Text('Sync now'),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              key: const Key('settings.cloudDisconnect'),
                              onPressed: _disconnect,
                              child: const Text('Disconnect'),
                            ),
                          ],
                        ),
                        compact: compact,
                      ),
                    ],
                  ]),
                  _section(context, 'Encryption', [
                    _field(
                      'This firm',
                      Text(
                        encrypted
                            ? 'Encrypted — unlocked for this session'
                            : 'Not encrypted',
                        key: const Key('encryption.state'),
                        style: TextStyle(color: c.ink2),
                      ),
                      compact: compact,
                    ),
                    if (!encrypted)
                      _field(
                        'Passphrase',
                        OutlinedButton(
                          key: const Key('encryption.enableSection'),
                          onPressed: () => context.go('/encryption/setup'),
                          child: const Text('Enable encryption…'),
                        ),
                        compact: compact,
                      )
                    else
                      _field(
                        'Secrets',
                        // Wrap, not Row: three buttons overflow a phone-width
                        // viewport, same reasoning as the cloud-sync pair.
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              key: const Key('encryption.changePassphrase'),
                              onPressed: _changePassphrase,
                              child: const Text('Change passphrase…'),
                            ),
                            OutlinedButton(
                              key: const Key('encryption.rotateRecoveryCode'),
                              onPressed: _rotateRecoveryCode,
                              child: const Text(
                                'Generate a new recovery code…',
                              ),
                            ),
                            OutlinedButton(
                              key: const Key('encryption.lock'),
                              onPressed: () => lockFirm(ref),
                              child: const Text('Lock now'),
                            ),
                          ],
                        ),
                        compact: compact,
                      ),
                  ]),
                  _section(context, 'Backup', [
                    _field(
                      'Backup folder',
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('settings.backupFolder'),
                              controller: _folder,
                              style: numberStyle.copyWith(fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: r'D:\LedgerlyBackups or a Google Drive folder',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            key: const Key('settings.browseBackupFolder'),
                            onPressed: _browseFolder,
                            child: const Text('Browse…'),
                          ),
                        ],
                      ),
                      compact: compact,
                    ),
                    _field(
                      'Restore',
                      OutlinedButton(
                        key: const Key('settings.restore'),
                        onPressed: _restore,
                        child: const Text('Restore from backup…'),
                      ),
                      compact: compact,
                    ),
                    _field(
                      'Last backup',
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              backup.running
                                  ? 'Running…'
                                  : backup.lastAt == null
                                  ? 'Not yet in this session'
                                  : 'Backed up ${_hhmm(backup.lastAt!)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.ink2),
                            ),
                          ),
                          const SizedBox(width: 14),
                          FilledButton(
                            key: const Key('settings.backupNow'),
                            onPressed: backup.running
                                ? null
                                : () async {
                                    await ref
                                        .read(backupFolderProvider.notifier)
                                        .set(_folder.text);
                                    await ref
                                        .read(backupRunnerProvider.notifier)
                                        .runNow();
                                  },
                            child: const Text('Backup now  Ctrl+B'),
                          ),
                        ],
                      ),
                      compact: compact,
                    ),
                    if (backup.error case final e?)
                      Padding(
                        padding: EdgeInsets.only(left: compact ? 0 : 130),
                        child: Text(
                          e,
                          style: TextStyle(color: c.giveable, fontSize: 12.5),
                        ),
                      ),
                  ]),
                  if (_message case final m?)
                    Text(m, style: TextStyle(color: c.receivable)),
                  const SizedBox(height: 8),
                  Text(
                    'Ctrl+Enter saves firm details and the backup folder · Esc back',
                    style: TextStyle(fontSize: 12.5, color: c.ink3),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: .8,
                fontWeight: FontWeight.w600,
                color: context.colors.accent,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      );

  Widget _field(String label, Widget child, {required bool compact}) {
    final labelWidget = Text(
      label,
      style: TextStyle(color: context.colors.ink2),
    );
    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [labelWidget, const SizedBox(height: 4), child],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 130, child: labelWidget),
          SizedBox(width: 520, child: child),
        ],
      ),
    );
  }
}
