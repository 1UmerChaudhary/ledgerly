import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly_core/ledgerly_core.dart';

import '../../bootstrap/providers.dart';
import '../../theme/ledgerly_theme.dart';
import '../ledger/ledger_screen.dart' show shortDate;

/// Counter sales with no customer. Never appears in any customer ledger.
typedef _Sales = List<Bill>;

final walkInSalesProvider = FutureProvider<_Sales>((ref) async {
  final firm = await ref.watch(openFirmProvider.future);
  return firm == null ? const [] : firm.bills.walkInSales();
});

class CashSalesScreen extends ConsumerWidget {
  const CashSalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final sales = ref.watch(walkInSalesProvider).value ?? const <Bill>[];
    final total = sales.fold(Money.zero, (sum, b) => sum + b.finalAmount);
    return Padding(
      key: const Key('cashSales.screen'),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'CASH SALES',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                  color: c.ink3,
                ),
              ),
              const Spacer(),
              Text(
                '${sales.length} sales · ${formatMoney(total)}',
                style: numberStyle.copyWith(fontSize: 13, color: c.ink2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sales.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No walk-in sales yet. Check "Walk-in" on a sale with no customer.',
                  style: TextStyle(color: c.ink2),
                ),
              ),
            )
          else
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: c.rule),
                  borderRadius: BorderRadius.circular(4),
                  color: c.surface,
                ),
                child: ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (context, i) {
                    final b = sales[i];
                    return Container(
                      key: const Key('cashSales.row'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: c.ruleSoft)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 90,
                            child: Text(
                              shortDate(b.entryDate),
                              style: numberStyle.copyWith(fontSize: 13),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              b.displayNo ?? '',
                              style: numberStyle.copyWith(
                                fontSize: 12.5,
                                color: c.ink2,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              b.description ?? '',
                              style: TextStyle(fontSize: 13, color: c.ink2),
                            ),
                          ),
                          Text(
                            formatMoney(b.finalAmount, symbol: false),
                            style: numberStyle.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
