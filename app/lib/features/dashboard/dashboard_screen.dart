import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly_core/ledgerly_core.dart';

import '../../bootstrap/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shell/breakpoints.dart';
import '../settings/settings_providers.dart';
import '../../theme/ledgerly_theme.dart';

class DashboardRow {
  const DashboardRow(this.customer, this.balance);
  final Customer customer;
  final Money balance;
}

/// Balances come from the customer_balances view, never from a stored column.
final dashboardRowsProvider = FutureProvider<List<DashboardRow>>((ref) async {
  final firm = await ref.watch(openFirmProvider.future);
  if (firm == null) return const [];
  final balances = await firm.bills.balances();
  final customers = {for (final c in await firm.customers.all()) c.id: c};
  return [
    for (final b in balances)
      if (customers[b.customerId] != null)
        DashboardRow(customers[b.customerId]!, b.balance),
  ];
});

class SearchQuery extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQuery, String>(
  SearchQuery.new,
);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchFocus = FocusNode(debugLabel: 'dashboard.search');
  final _search = TextEditingController();
  int _selected = 0;

  @override
  void dispose() {
    _searchFocus.dispose();
    _search.dispose();
    super.dispose();
  }

  List<DashboardRow> _filter(List<DashboardRow> rows, String query) {
    if (query.trim().isEmpty) return rows;
    final byName = {for (final r in rows) r.customer.name: r};
    final digits = query.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 4 &&
        digits.length == query.replaceAll(RegExp(r'[\s\-+]'), '').length) {
      return rows
          .where((r) => (r.customer.phoneNormalized ?? '').contains(digits))
          .toList();
    }
    return fuzzySearch(
      query,
      byName.keys,
    ).map((h) => byName[h.value]!).toList();
  }

  void _open(List<DashboardRow> visible) {
    if (visible.isEmpty) return;
    final row = visible[_selected.clamp(0, visible.length - 1)];
    context.go('/customers/${row.customer.id}');
  }

  KeyEventResult _onKey(
    FocusNode node,
    KeyEvent event,
    List<DashboardRow> visible,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(
        () => _selected = (_selected + 1).clamp(
          0,
          visible.isEmpty ? 0 : visible.length - 1,
        ),
      );
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(
        () => _selected = (_selected - 1).clamp(
          0,
          visible.isEmpty ? 0 : visible.length - 1,
        ),
      );
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _open(visible);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = L10n.of(context);
    final rows =
        ref.watch(dashboardRowsProvider).value ?? const <DashboardRow>[];
    final query = ref.watch(searchQueryProvider);
    final visible = _filter(rows, query);
    final receivables = visible.where((r) => r.balance.isPositive).toList();
    final giveables = visible.where((r) => r.balance.isNegative).toList();
    // One selection index runs down receivables then giveables.
    final ordered = [...receivables, ...giveables];

    return Focus(
      onKeyEvent: (node, event) => _onKey(node, event, ordered),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('dashboard.search'),
              focusNode: _searchFocus,
              controller: _search,
              autofocus: true,
              onChanged: (v) {
                ref.read(searchQueryProvider.notifier).set(v);
                setState(() => _selected = 0);
              },
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixText: 'Ctrl+F',
                suffixStyle: numberStyle.copyWith(fontSize: 11, color: c.ink3),
              ),
            ),
            const SizedBox(height: 16),
            if (rows.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    l10n.noCustomersYet,
                    style: TextStyle(color: c.ink2),
                  ),
                ),
              )
            else
              Expanded(
                child: _buildBalancePanels(context, receivables, giveables),
              ),
          ],
        ),
      ),
    );
  }

  /// Side by side, each panel gets roughly half the screen width. At phone
  /// width that's ~164px, which a large balance's digits (header total, or
  /// a row's amount) don't fit next to their label — RenderFlex overflow.
  /// Below [kCompactBreakpoint], stack the panels instead: each gets the
  /// full width and its own scrollable half. Above it, the original
  /// side-by-side Row is unchanged.
  Widget _buildBalancePanels(
    BuildContext context,
    List<DashboardRow> receivables,
    List<DashboardRow> giveables,
  ) {
    final l10n = L10n.of(context);
    final c = context.colors;
    final receivablesPanel = _BalancePanel(
      key: const Key('dashboard.receivables'),
      title: l10n.receivable,
      color: c.receivable,
      rows: receivables,
      selectedIndex: _selected,
      onTap: (i) => context.go('/customers/${receivables[i].customer.id}'),
    );
    final giveablesPanel = _BalancePanel(
      key: const Key('dashboard.giveables'),
      title: l10n.giveable,
      color: c.giveable,
      rows: giveables,
      selectedIndex: _selected - receivables.length,
      onTap: (i) => context.go('/customers/${giveables[i].customer.id}'),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < kCompactBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: receivablesPanel),
              const SizedBox(height: 12),
              Expanded(child: giveablesPanel),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: receivablesPanel),
            const SizedBox(width: 18),
            Expanded(child: giveablesPanel),
          ],
        );
      },
    );
  }
}

class _BalancePanel extends ConsumerWidget {
  const _BalancePanel({
    super.key,
    required this.title,
    required this.color,
    required this.rows,
    required this.selectedIndex,
    required this.onTap,
  });

  final String title;
  final Color color;
  final List<DashboardRow> rows;
  final int selectedIndex;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(moneyFormatProvider);
    final c = context.colors;
    final total = rows.fold(Money.zero, (sum, r) => sum + r.balance.abs());
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.rule),
        borderRadius: BorderRadius.circular(4),
        color: c.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.rule)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.9,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  fmt(total),
                  style: numberStyle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, i) {
                final selected = i == selectedIndex;
                return InkWell(
                  onTap: () => onTap(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? c.selection : null,
                      border: Border(
                        left: BorderSide(
                          color: selected ? c.accent : Colors.transparent,
                          width: 3,
                        ),
                        bottom: BorderSide(color: c.ruleSoft),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            rows[i].customer.name,
                            // A long name has little room next to the
                            // balance column -- without this it wraps
                            // across several lines instead of truncating
                            // cleanly (same fix as customers_screen.dart's
                            // list row).
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 13.5),
                          ),
                        ),
                        Text(
                          fmt(rows[i].balance.abs(), symbol: false),
                          style: numberStyle.copyWith(
                            fontSize: 13.5,
                            color: color,
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
