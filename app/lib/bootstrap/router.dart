import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/bills/bill_screen.dart';
import '../features/cash_sales/cash_sales_screen.dart';
import '../features/customers/customer_form_screen.dart';
import '../features/customers/customers_screen.dart';
import '../features/customers/opening_balances_screen.dart';
import '../features/items/items_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/ledger/ledger_detail_screen.dart';
import '../features/ledger/ledger_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/setup/first_launch_screen.dart';
import '../shell/app_shell.dart';
import 'providers.dart';

class _Refresh extends ChangeNotifier {
  void poke() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _Refresh();
  ref.listen(openFirmProvider, (_, _) => refresh.poke());
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final firm = ref.read(openFirmProvider);
      final at = state.matchedLocation;
      if (firm.isLoading) {
        return at == '/loading' ? null : '/loading';
      }
      if (firm.value == null) {
        return at == '/setup' ? null : '/setup';
      }
      if (at == '/setup' || at == '/loading') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, _) => const AppShell(
          hints: [],
          location: '/loading',
          child: SizedBox.shrink(),
        ),
      ),
      GoRoute(path: '/setup', builder: (_, _) => const FirstLaunchScreen()),
      ShellRoute(
        // `state.uri.path`, not `state.matchedLocation`: a ShellRouteMatch
        // stores its matchedLocation once, when the shell was first matched,
        // and popping a route *inside* the shell navigator never updates it
        // (only `uri`/`fullPath` are re-derived from the live match list).
        // Reading matchedLocation here left the shell showing drill-down
        // chrome -- back arrow, no bottom nav -- after back had already
        // returned to the list. Verified on device and by widget test.
        builder: (context, state, child) {
          final location = state.uri.path;
          return AppShell(
            location: location,
            hints: hintsFor(location),
            child: child,
          );
        },
        routes: [
          GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
          GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
          // Drill-downs are declared as nested `routes:` children of the list
          // they were launched from, not as flat siblings. Every navigation
          // in this app uses go() (replace), so a flat sibling route leaves
          // a one-page stack behind: context.canPop() is false and both the
          // title-bar back button and the system back gesture fall through
          // to the dashboard instead of the list. Nesting makes go() build
          // the parent page underneath the child, which is what the spec
          // means by "back returns to the list".
          GoRoute(
            path: '/customers',
            builder: (_, _) => const CustomersScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, _) => const CustomerFormScreen(),
              ),
              GoRoute(
                path: 'opening-balances',
                builder: (_, _) => const OpeningBalancesScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/items',
            builder: (_, _) => const ItemsScreen(),
            routes: [
              GoRoute(path: 'new', builder: (_, _) => const ItemFormScreen()),
            ],
          ),
          GoRoute(
            path: '/cash-sales',
            builder: (_, _) => const CashSalesScreen(),
          ),
          // Kept a top-level route rather than a child of '/customers': the
          // ledger is opened from the dashboard at least as often as from
          // the customers list, so "back" from it means the dashboard --
          // exactly what its own Esc hint already promises.
          GoRoute(
            path: '/customers/:id',
            builder: (_, s) => LedgerScreen(
              customerId: s.pathParameters['id']!,
              selectBillId: s.uri.queryParameters['select'],
            ),
            routes: [
              GoRoute(
                path: 'bills/:billId',
                builder: (_, s) => LedgerDetailScreen(
                  customerId: s.pathParameters['id']!,
                  billId: s.pathParameters['billId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/bills/new',
            builder: (_, s) =>
                BillScreen(type: s.uri.queryParameters['type'] ?? 'sale'),
          ),
          GoRoute(
            path: '/bills/:id/edit',
            builder: (_, s) => BillScreen(
              type: s.uri.queryParameters['type'] ?? 'sale',
              editBillId: s.pathParameters['id'],
            ),
          ),
        ],
      ),
    ],
  );
});
