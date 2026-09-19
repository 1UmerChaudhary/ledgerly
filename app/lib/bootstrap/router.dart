import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/bills/bill_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/ledger/ledger_screen.dart';
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
        builder: (_, _) => const AppShell(hints: [], child: SizedBox.shrink()),
      ),
      GoRoute(path: '/setup', builder: (_, _) => const FirstLaunchScreen()),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(hints: hintsFor(state.matchedLocation), child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
          GoRoute(
            path: '/customers/:id',
            builder: (_, s) =>
                LedgerScreen(customerId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/bills/new',
            builder: (_, s) =>
                BillScreen(type: s.uri.queryParameters['type'] ?? 'sale'),
          ),
        ],
      ),
    ],
  );
});
