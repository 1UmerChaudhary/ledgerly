import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly_core/ledgerly_core.dart';

import '../../bootstrap/providers.dart';
import '../../theme/ledgerly_theme.dart';

final customerProvider = FutureProvider.family<Customer?, String>((
  ref,
  id,
) async {
  final firm = await ref.watch(openFirmProvider.future);
  return firm?.customers.byId(id);
});

/// Milestone 5 fills this in (two-pane ledger with history). For now: the
/// customer's name and balance, so navigation from the dashboard is real.
class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key, required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(customerProvider(customerId)).value;
    return Padding(
      key: const Key('ledger.screen'),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CUSTOMER',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
              color: context.colors.ink3,
            ),
          ),
          Text(
            customer?.name ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
