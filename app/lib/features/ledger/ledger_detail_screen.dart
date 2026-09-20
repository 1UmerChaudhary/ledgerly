import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bills/bill_draft.dart' show itemsListProvider;
import 'ledger_screen.dart' show LedgerDetailPanel, ledgerEntriesProvider;

/// Phone-width equivalent of the ledger's side detail panel: the same
/// [LedgerDetailPanel] body, pushed as its own full screen instead of shown
/// inline. Re-derives its [LedgerEntry] from the same provider the list
/// screen already watches — there is no single-bill-by-id provider, and
/// re-fetching a customer's (small) bill list is cheap enough not to need one.
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

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(
      ledgerEntriesProvider((
        customerId: widget.customerId,
        includeDeleted: true,
      )),
    );
    return entriesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (entries) {
        // A concurrent delete between the row tap and this screen's build is
        // rare but real: firstWhere with no orElse throws StateError and
        // crashes the screen instead of showing something sensible, so the
        // lookup goes through `where` and a null check instead.
        final matches = entries.where((e) => e.bill.id == widget.billId);
        if (matches.isEmpty) {
          return const Scaffold(body: Center(child: Text('Bill not found')));
        }
        final entry = matches.first;
        final items = ref.watch(itemsListProvider).value ?? const [];
        final itemNames = {for (final i in items) i.id: i.name};
        return LedgerDetailPanel(
          entry: entry,
          itemNames: itemNames,
          selectedHistoryVersion: _selectedHistoryVersion,
          onSelectHistory: (v) => setState(() => _selectedHistoryVersion = v),
        );
      },
    );
  }
}
