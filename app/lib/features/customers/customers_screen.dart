import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly_core/ledgerly_core.dart';

import '../../theme/ledgerly_theme.dart';
import '../bills/bill_draft.dart';
import '../dashboard/dashboard_screen.dart';

/// All customers, including those with a zero balance (the dashboard only
/// shows balances). Ctrl+N adds one; Enter opens the ledger.
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _search = TextEditingController();
  String _query = '';
  int _selected = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final all = ref.watch(customersListProvider).value ?? const <Customer>[];
    final balances = {
      for (final r
          in ref.watch(dashboardRowsProvider).value ?? const <DashboardRow>[])
        r.customer.id: r.balance,
    };
    final byName = {for (final x in all) x.name: x};
    final visible = _query.trim().isEmpty
        ? all
        : fuzzySearch(
            _query,
            byName.keys,
          ).map((h) => byName[h.value]!).toList();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            context.go('/customers/new'),
      },
      child: Focus(
        onKeyEvent: (node, e) {
          if (e is! KeyDownEvent || visible.isEmpty) {
            return KeyEventResult.ignored;
          }
          if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
            setState(
              () => _selected = (_selected + 1).clamp(0, visible.length - 1),
            );
            return KeyEventResult.handled;
          }
          if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
            setState(
              () => _selected = (_selected - 1).clamp(0, visible.length - 1),
            );
            return KeyEventResult.handled;
          }
          if (e.logicalKey == LogicalKeyboardKey.enter ||
              e.logicalKey == LogicalKeyboardKey.numpadEnter) {
            context.go(
              '/customers/${visible[_selected.clamp(0, visible.length - 1)].id}',
            );
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Padding(
          key: const Key('customers.screen'),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'CUSTOMERS',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                      color: c.ink3,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${all.length} total · Ctrl+N adds one',
                    style: TextStyle(fontSize: 12.5, color: c.ink3),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('customers.search'),
                controller: _search,
                autofocus: true,
                onChanged: (v) => setState(() {
                  _query = v;
                  _selected = 0;
                }),
                decoration: const InputDecoration(
                  hintText: 'Search by name or phone',
                  prefixIcon: Icon(Icons.search, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: c.rule),
                    borderRadius: BorderRadius.circular(4),
                    color: c.surface,
                  ),
                  child: ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, i) {
                      final cu = visible[i];
                      final b = balances[cu.id] ?? Money.zero;
                      final sel = i == _selected;
                      return InkWell(
                        key: const Key('customers.row'),
                        onTap: () => context.go('/customers/${cu.id}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: sel ? c.selection : null,
                            border: Border(
                              left: BorderSide(
                                color: sel ? c.accent : Colors.transparent,
                                width: 3,
                              ),
                              bottom: BorderSide(color: c.ruleSoft),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  cu.name,
                                  style: const TextStyle(fontSize: 13.5),
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: Text(
                                  cu.phone ?? '',
                                  style: numberStyle.copyWith(
                                    fontSize: 12.5,
                                    color: c.ink2,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 140,
                                child: Text(
                                  b.isZero
                                      ? '—'
                                      : '${b.isNegative ? 'is owed' : 'owes'} ${formatMoney(b.abs(), symbol: false)}',
                                  textAlign: TextAlign.right,
                                  style: numberStyle.copyWith(
                                    fontSize: 13,
                                    color: b.isNegative
                                        ? c.giveable
                                        : (b.isZero ? c.ink3 : c.receivable),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
