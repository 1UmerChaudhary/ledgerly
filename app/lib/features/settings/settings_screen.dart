import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../../bootstrap/providers.dart';
import '../../printing/print_actions.dart';
import '../../printing/printing_service.dart';
import '../../theme/ledgerly_theme.dart';
import '../dashboard/dashboard_screen.dart';
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
  bool _loaded = false;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _address.dispose();
    _folder.dispose();
    super.dispose();
  }

  void _fill(Firm firm, String? folder) {
    if (_loaded) return;
    _loaded = true;
    _name.text = firm.name;
    _contact.text = firm.contactNumber;
    _address.text = firm.address ?? '';
    _folder.text = folder ?? '';
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final firm = ref.watch(firmSettingsProvider).value;
    final folder = ref.watch(backupFolderProvider);
    final backup = ref.watch(backupRunnerProvider);
    final printer = ref.watch(printerChoiceProvider);
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
        child: ListView(
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
              ),
              _field(
                'Contact',
                TextField(
                  key: const Key('settings.contact'),
                  controller: _contact,
                  style: numberStyle.copyWith(fontSize: 14),
                ),
              ),
              _field(
                'Address',
                TextField(
                  key: const Key('settings.address'),
                  controller: _address,
                ),
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
                    Text(
                      firm?.showPaisa ?? false
                          ? 'Rs 6,02,835.72'
                          : 'Rs 6,02,836 (whole rupees)',
                      style: numberStyle.copyWith(fontSize: 13, color: c.ink2),
                    ),
                  ],
                ),
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
                          hintText:
                              r'D:\LedgerlyBackups or a Google Drive folder',
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
              ),
              _field(
                'Restore',
                OutlinedButton(
                  key: const Key('settings.restore'),
                  onPressed: _restore,
                  child: const Text('Restore from backup…'),
                ),
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
              ),
              if (backup.error case final e?)
                Padding(
                  padding: const EdgeInsets.only(left: 130),
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

  Widget _field(String label, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: TextStyle(color: context.colors.ink2)),
        ),
        SizedBox(width: 520, child: child),
      ],
    ),
  );
}
