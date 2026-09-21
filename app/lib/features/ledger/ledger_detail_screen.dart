import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../../bootstrap/providers.dart';
import '../../printing/print_actions.dart';
import '../../theme/ledgerly_theme.dart';
import '../bills/bill_draft.dart' show itemsListProvider;
import 'ledger_screen.dart'
    show
        LedgerDetailPanel,
        confirmDeleteBill,
        ledgerEntriesProvider,
        restoreBillVersion;

/// Phone-width equivalent of the ledger's side detail panel: the same
/// [LedgerDetailPanel] body, pushed as its own full screen instead of shown
/// inline, plus the action row that replaces the desktop keyboard shortcuts
/// (F2 edit, Delete, R restore, Ctrl+P reprint). Re-derives its [LedgerEntry]
/// from the same provider the list screen already watches — there is no
/// single-bill-by-id provider, and re-fetching a customer's (small) bill list
/// is cheap enough not to need one.
class LedgerDetailScreen extends ConsumerStatefulWidget {
  const LedgerDetailScreen({
    super.key,
    required this.customerId,
    required this.billId,
  });
  final String customerId;
  final String billId;

  @override
  ConsumerState<LedgerDetailScreen> createState() => _LedgerDetailScreenState();
}

class _LedgerDetailScreenState extends ConsumerState<LedgerDetailScreen> {
  int? _selectedHistoryVersion;

  /// The list this screen was pushed from. Falls back to a go() for the rare
  /// case of a deep link straight to a bill, where there is nothing to pop.
  void _backToLedger() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/customers/${widget.customerId}');
    }
  }

  Future<void> _delete(LedgerEntry entry) async {
    final deleted = await confirmDeleteBill(
      context,
      ref,
      entry,
      widget.customerId,
    );
    // A deleted bill still exists (soft delete) but this screen no longer
    // describes anything the user asked to look at, so it steps back to the
    // list the way the desktop selection does.
    if (deleted && mounted) _backToLedger();
  }

  Future<void> _restore(LedgerEntry entry) async {
    final version = _selectedHistoryVersion;
    if (version == null) return;
    await restoreBillVersion(ref, entry, widget.customerId, version: version);
    if (mounted) setState(() => _selectedHistoryVersion = null);
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(
      ledgerEntriesProvider((
        customerId: widget.customerId,
        includeDeleted: true,
      )),
    );
    return entriesAsync.when(
      // Plain widgets, not Scaffolds: AppShell already provides the Scaffold
      // this route renders inside.
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (entries) {
        // A concurrent delete between the row tap and this screen's build is
        // rare but real: firstWhere with no orElse throws StateError and
        // crashes the screen instead of showing something sensible, so the
        // lookup goes through `where` and a null check instead.
        final matches = entries.where((e) => e.bill.id == widget.billId);
        if (matches.isEmpty) {
          return const Center(child: Text('Bill not found'));
        }
        final entry = matches.first;
        final items = ref.watch(itemsListProvider).value ?? const [];
        final itemNames = {for (final i in items) i.id: i.name};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LedgerDetailPanel(
                entry: entry,
                itemNames: itemNames,
                selectedHistoryVersion: _selectedHistoryVersion,
                onSelectHistory: (v) =>
                    setState(() => _selectedHistoryVersion = v),
                // No R key on a phone — the Restore button below is the
                // equivalent, and it says so by being enabled or not.
                showRestoreKeyHint: false,
              ),
            ),
            _Actions(
              entry: entry,
              selectedHistoryVersion: _selectedHistoryVersion,
              onEdit: () => context.go('/bills/${entry.bill.id}/edit'),
              onDelete: () => _delete(entry),
              onRestore: () => _restore(entry),
              onPrint: () {
                final firm = ref.read(openFirmProvider).value;
                if (firm != null) printSlip(ref, firm, entry.bill.id);
              },
              onExportPdf: () {
                final firm = ref.read(openFirmProvider).value;
                if (firm != null) exportSlipPdf(ref, firm, entry.bill.id);
              },
            ),
          ],
        );
      },
    );
  }
}

/// Every bill action the desktop ledger offers by keyboard only, as buttons.
/// Pinned below the (scrolling) detail panel rather than inside it, so a long
/// history can't push them off screen — the same reasoning as the bill form's
/// compact Save/Cancel row.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.entry,
    required this.selectedHistoryVersion,
    required this.onEdit,
    required this.onDelete,
    required this.onRestore,
    required this.onPrint,
    required this.onExportPdf,
  });

  final LedgerEntry entry;
  final int? selectedHistoryVersion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRestore;
  final VoidCallback onPrint;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final deleted = entry.bill.deleted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.rule)),
      ),
      // Wrap, not Row: five actions never fit one phone-width line, and this
      // is exactly the RenderFlex overflow the rest of the branch removed.
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          // Disabled on a deleted bill, mirroring the desktop F2 and Delete
          // shortcuts, which both check `!entry.bill.deleted`.
          FilledButton.tonal(
            key: const Key('ledger.detail.edit'),
            onPressed: deleted ? null : onEdit,
            child: const Text('Edit'),
          ),
          OutlinedButton(
            key: const Key('ledger.detail.delete'),
            onPressed: deleted ? null : onDelete,
            child: const Text('Delete'),
          ),
          // Mirrors the R shortcut's own condition: a version has to be
          // picked in the history list above first.
          OutlinedButton(
            key: const Key('ledger.detail.restore'),
            onPressed: selectedHistoryVersion == null ? null : onRestore,
            child: const Text('Restore'),
          ),
          OutlinedButton(
            key: const Key('ledger.detail.print'),
            onPressed: onPrint,
            child: const Text('Print'),
          ),
          OutlinedButton(
            key: const Key('ledger.detail.exportPdf'),
            onPressed: onExportPdf,
            child: const Text('Export PDF'),
          ),
        ],
      ),
    );
  }
}
