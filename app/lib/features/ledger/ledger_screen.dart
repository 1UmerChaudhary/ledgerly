import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../../bootstrap/providers.dart';
import '../../theme/ledgerly_theme.dart';
import '../bills/bill_draft.dart';
import '../dashboard/dashboard_screen.dart';

final customerProvider = FutureProvider.family<Customer?, String>((
  ref,
  id,
) async {
  final firm = await ref.watch(openFirmProvider.future);
  return firm?.customers.byId(id);
});

typedef LedgerKey = ({String customerId, bool includeDeleted});

final ledgerEntriesProvider =
    FutureProvider.family<List<LedgerEntry>, LedgerKey>((ref, key) async {
      final firm = await ref.watch(openFirmProvider.future);
      return firm == null
          ? const []
          : firm.bills.ledgerFor(
              key.customerId,
              includeDeleted: key.includeDeleted,
            );
    });

final billHistoryProvider = FutureProvider.family<List<HistoryEntry>, String>((
  ref,
  billId,
) async {
  final firm = await ref.watch(openFirmProvider.future);
  return firm == null ? const [] : firm.bills.historyFor(billId);
});

String shortDate(String iso) {
  final p = iso.split('-');
  return p.length == 3 ? '${p[2]}/${p[1]}/${p[0].substring(2)}' : iso;
}

/// Two panes: the ledger (chronological, running balance) and the selected
/// bill with its history. Debit = what the customer owes more (sale, cash paid
/// to them, opening balance), Credit = owes less (purchase, cash received).
class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key, required this.customerId, this.selectBillId});
  final String customerId;

  /// Preselect this bill (the one just saved) until the user moves.
  final String? selectBillId;

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  final _focus = FocusNode(debugLabel: 'ledger');
  int? _selected; // null = not moved yet → follow selectBillId, else 0
  int? _selectedHistoryVersion;
  bool _showDeleted = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _refresh() {
    // Both variants may be cached (the toggle can flip either way), so both
    // are invalidated rather than just the one currently showing.
    ref.invalidate(
      ledgerEntriesProvider((
        customerId: widget.customerId,
        includeDeleted: false,
      )),
    );
    ref.invalidate(
      ledgerEntriesProvider((
        customerId: widget.customerId,
        includeDeleted: true,
      )),
    );
    ref.invalidate(customerBalanceProvider(widget.customerId));
    ref.invalidate(dashboardRowsProvider);
  }

  Future<void> _delete(LedgerEntry entry) async {
    final firm = ref.read(openFirmProvider).value;
    if (firm == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('ledger.deleteDialog'),
        title: Text('Delete bill ${entry.bill.displayNo}?'),
        content: const Text(
          'It leaves the ledger but stays in history and can be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await firm.bills.delete(entry.bill.id);
    ref.invalidate(billHistoryProvider(entry.bill.id));
    _refresh();
    setState(() => _selected = 0);
  }

  Future<void> _restore(LedgerEntry entry) async {
    final firm = ref.read(openFirmProvider).value;
    final version = _selectedHistoryVersion;
    if (firm == null || version == null) return;
    await firm.bills.restoreVersion(entry.bill.id, version: version);
    ref.invalidate(billHistoryProvider(entry.bill.id));
    _refresh();
    setState(() => _selectedHistoryVersion = null);
  }

  int _effective(List<LedgerEntry> entries) {
    if (_selected != null) return _selected!.clamp(0, entries.length - 1);
    final i = widget.selectBillId == null
        ? -1
        : entries.indexWhere((e) => e.bill.id == widget.selectBillId);
    return i < 0 ? 0 : i;
  }

  KeyEventResult _onKey(
    FocusNode node,
    KeyEvent event,
    List<LedgerEntry> entries,
  ) {
    if (event is! KeyDownEvent || entries.isEmpty) {
      return KeyEventResult.ignored;
    }
    final k = event.logicalKey;
    final current = _effective(entries);
    final entry = entries[current];
    if (k == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selected = (current + 1).clamp(0, entries.length - 1);
        _selectedHistoryVersion = null;
      });
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selected = (current - 1).clamp(0, entries.length - 1);
        _selectedHistoryVersion = null;
      });
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.keyD &&
        HardwareKeyboard.instance.isControlPressed) {
      setState(() {
        _showDeleted = !_showDeleted;
        _selected = null;
        _selectedHistoryVersion = null;
      });
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.delete && !entry.bill.deleted) {
      _delete(entry);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.keyR && _selectedHistoryVersion != null) {
      _restore(entry);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.f2 && !entry.bill.deleted) {
      context.go('/bills/${entry.bill.id}/edit');
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final customer = ref.watch(customerProvider(widget.customerId)).value;
    final entries =
        ref
            .watch(
              ledgerEntriesProvider((
                customerId: widget.customerId,
                includeDeleted: _showDeleted,
              )),
            )
            .value ??
        const <LedgerEntry>[];
    final items = ref.watch(itemsListProvider).value ?? const <Item>[];
    final itemNames = {for (final i in items) i.id: i.name};
    // Never derived from the visible list: a deleted row shown via the
    // toggle carries no running balance, and the real balance must not
    // depend on whether that toggle happens to be on.
    final balance =
        ref.watch(customerBalanceProvider(widget.customerId)).value ??
        Money.zero;
    final selectedIndex = entries.isEmpty ? 0 : _effective(entries);
    final selected = entries.isEmpty ? null : entries[selectedIndex];

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: (n, e) => _onKey(n, e, entries),
      child: Padding(
        key: const Key('ledger.screen'),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CUSTOMER',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                          color: c.ink3,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            customer?.name ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (customer?.phone case final p?) ...[
                            const SizedBox(width: 10),
                            Text(
                              p,
                              style: numberStyle.copyWith(
                                fontSize: 13,
                                color: c.ink3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      key: const Key('ledger.showDeleted'),
                      value: _showDeleted,
                      onChanged: (v) => setState(() {
                        _showDeleted = v ?? false;
                        _selected = null;
                        _selectedHistoryVersion = null;
                      }),
                    ),
                    Text(
                      'Show deleted',
                      style: TextStyle(fontSize: 12.5, color: c.ink2),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      balance.isNegative ? 'IS OWED' : 'OWES',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                        color: balance.isNegative ? c.giveable : c.receivable,
                      ),
                    ),
                    Text(
                      formatMoney(balance.abs()),
                      style: numberStyle.copyWith(
                        fontSize: 22,
                        color: balance.isNegative ? c.giveable : c.receivable,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _LedgerTable(
                      entries: entries,
                      selected: selectedIndex,
                      onTap: (i) => setState(() => _selected = i),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 340,
                    child: selected == null
                        ? const SizedBox.shrink()
                        : _DetailPanel(
                            entry: selected,
                            itemNames: itemNames,
                            selectedHistoryVersion: _selectedHistoryVersion,
                            onSelectHistory: (v) =>
                                setState(() => _selectedHistoryVersion = v),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerTable extends StatelessWidget {
  const _LedgerTable({
    required this.entries,
    required this.selected,
    required this.onTap,
  });
  final List<LedgerEntry> entries;
  final int selected;
  final void Function(int) onTap;

  static const _cols = <(String, int, bool)>[
    ('Date', 80, false),
    ('No', 90, false),
    ('Type', 170, false),
    ('Description', 0, false),
    ('Debit', 110, true),
    ('Credit', 110, true),
    ('Balance', 120, true),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget cellBox(int w, Widget child) => w == 0
        ? Expanded(child: child)
        : SizedBox(width: w.toDouble(), child: child);
    return Container(
      key: const Key('ledger.table'),
      decoration: BoxDecoration(
        border: Border.all(color: c.rule),
        borderRadius: BorderRadius.circular(4),
        color: c.surface,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.rule)),
            ),
            child: Row(
              children: [
                for (final (label, w, num) in _cols)
                  cellBox(
                    w,
                    Text(
                      label.toUpperCase(),
                      textAlign: num ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: .6,
                        fontWeight: FontWeight.w600,
                        color: c.ink3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final e = entries[i];
                final deleted = e.bill.deleted;
                final signed = e.bill.signedAmount;
                final isSel = i == selected;
                final rowColor = deleted ? c.ink3 : c.ink;
                return InkWell(
                  onTap: () => onTap(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSel ? c.selection : null,
                      border: Border(
                        left: BorderSide(
                          color: isSel ? c.accent : Colors.transparent,
                          width: 3,
                        ),
                        bottom: BorderSide(color: c.ruleSoft),
                      ),
                    ),
                    child: Row(
                      children: [
                        cellBox(
                          80,
                          Text(
                            shortDate(e.bill.entryDate),
                            style: numberStyle.copyWith(
                              fontSize: 13,
                              color: rowColor,
                            ),
                          ),
                        ),
                        cellBox(
                          90,
                          Text(
                            e.bill.displayNo ?? '',
                            style: numberStyle.copyWith(
                              fontSize: 12.5,
                              color: c.ink2,
                            ),
                          ),
                        ),
                        cellBox(
                          170,
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  transactionTypeLabel(e.bill.type),
                                  key: const Key('ledger.row.type'),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: rowColor,
                                    decoration: deleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              if (deleted) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.giveableSoft,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    'deleted',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: c.giveable,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ] else if (e.bill.version > 1) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.accentSoft,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    'edited',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: c.accent,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        cellBox(
                          0,
                          Text(
                            e.bill.description ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: c.ink2),
                          ),
                        ),
                        cellBox(
                          110,
                          Text(
                            signed.isPositive
                                ? formatMoney(signed, symbol: false)
                                : '',
                            textAlign: TextAlign.right,
                            style: numberStyle.copyWith(
                              fontSize: 13.5,
                              color: rowColor,
                            ),
                          ),
                        ),
                        cellBox(
                          110,
                          Text(
                            signed.isNegative
                                ? formatMoney(-signed, symbol: false)
                                : '',
                            textAlign: TextAlign.right,
                            style: numberStyle.copyWith(
                              fontSize: 13.5,
                              color: rowColor,
                            ),
                          ),
                        ),
                        cellBox(
                          120,
                          Text(
                            e.runningBalance == null
                                ? '—'
                                : formatMoney(
                                    e.runningBalance!.abs(),
                                    symbol: false,
                                  ),
                            textAlign: TextAlign.right,
                            style: numberStyle.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: e.runningBalance == null
                                  ? c.ink3
                                  : (e.runningBalance!.isNegative
                                        ? c.giveable
                                        : c.ink),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPanel extends ConsumerWidget {
  const _DetailPanel({
    required this.entry,
    required this.itemNames,
    required this.selectedHistoryVersion,
    required this.onSelectHistory,
  });
  final LedgerEntry entry;
  final Map<String, String> itemNames;
  final int? selectedHistoryVersion;
  final void Function(int) onSelectHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final bill = entry.bill;
    final history =
        ref.watch(billHistoryProvider(bill.id)).value ?? const <HistoryEntry>[];
    // Each history row is the bill BEFORE a change; the version after it is the
    // next-newer snapshot, or the live bill for the most recent change.
    Bill after(int index) => index == 0 ? bill : history[index - 1].bill;

    return Container(
      key: const Key('ledger.detail'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: c.rule),
        borderRadius: BorderRadius.circular(4),
        color: c.surface,
      ),
      child: ListView(
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Text(
                'Bill ${bill.displayNo ?? ''}',
                style: numberStyle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _Badge('v${bill.version}', c.accentSoft, c.accent),
              if (bill.overrideIsStale)
                _Badge('total overridden', c.giveableSoft, c.giveable),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${transactionTypeLabel(bill.type)} · ${shortDate(bill.entryDate)}${bill.description == null ? '' : ' · ${bill.description}'}',
            style: TextStyle(fontSize: 12.5, color: c.ink2),
          ),
          const SizedBox(height: 10),
          for (final l in bill.lines)
            _kv(
              context,
              '${itemNames[l.itemId] ?? 'Item'} · ${l.bagCount != null ? '${l.bagCount} bags · ' : ''}${l.totalWeight == null ? '' : '${formatKg(l.totalWeight!, trim: true)} kg'}',
              formatMoney(l.finalTotal, symbol: false),
            ),
          if (bill.lines.isNotEmpty)
            _kv(
              context,
              'Calculated',
              formatMoney(bill.calculatedTotal, symbol: false),
            ),
          if (bill.overriddenTotal case final o?)
            _kv(
              context,
              'Override',
              formatMoney(o, symbol: false),
              strong: true,
            ),
          _kv(
            context,
            bill.lines.isEmpty ? 'Amount' : 'Final',
            formatMoney(bill.finalAmount, symbol: false),
            strong: true,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.rule)),
            ),
            child: Text(
              'HISTORY',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
                color: c.ink3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < history.length; i++)
            _HistoryRow(
              key: Key('history.version.${history[i].version}'),
              entry: history[i],
              changes: diffBills(
                history[i].bill,
                after(i),
                itemNames: itemNames,
              ),
              toVersion: after(i).version,
              selected: selectedHistoryVersion == history[i].version,
              onTap: () => onSelectHistory(history[i].version),
            ),
          if (history.isEmpty)
            Text(
              'v1 · created',
              style: TextStyle(fontSize: 12.5, color: c.ink2),
            ),
          if (history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Select a version and press R to restore it as a new version.',
                style: TextStyle(fontSize: 12, color: c.ink3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kv(
    BuildContext context,
    String label,
    String value, {
    bool strong = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: strong ? context.colors.ink : context.colors.ink2,
              fontWeight: strong ? FontWeight.w600 : null,
            ),
          ),
        ),
        Text(
          value,
          style: numberStyle.copyWith(
            fontSize: 13,
            fontWeight: strong ? FontWeight.w600 : null,
          ),
        ),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.bg, this.fg);
  final String text;
  final Color bg;
  final Color fg;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500),
    ),
  );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    super.key,
    required this.entry,
    required this.changes,
    required this.toVersion,
    required this.selected,
    required this.onTap,
  });
  final HistoryEntry entry;
  final List<FieldChange> changes;
  final int toVersion;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final when = DateTime.fromMillisecondsSinceEpoch(entry.changedAt);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? c.selection : null,
          border: Border.all(color: selected ? c.accent : c.ruleSoft),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    'v${entry.version} → v$toVersion · ${entry.reason}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${when.day.toString().padLeft(2, '0')}/${when.month.toString().padLeft(2, '0')} ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}',
                  style: numberStyle.copyWith(fontSize: 11, color: c.ink3),
                ),
              ],
            ),
            for (final ch in changes)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ch.label,
                        style: TextStyle(fontSize: 12, color: c.ink2),
                      ),
                    ),
                    Text(
                      ch.from,
                      style: numberStyle.copyWith(
                        fontSize: 12,
                        color: c.ink3,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(' → ', style: TextStyle(fontSize: 12, color: c.ink3)),
                    Text(
                      ch.to,
                      style: numberStyle.copyWith(
                        fontSize: 12,
                        color: c.giveable,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
