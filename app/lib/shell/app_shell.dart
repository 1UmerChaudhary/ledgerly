import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../bootstrap/providers.dart';
import '../features/settings/settings_providers.dart';
import '../l10n/app_localizations.dart';
import '../theme/ledgerly_theme.dart';
import 'breakpoints.dart';

class KeyHint {
  const KeyHint(this.keys, this.label);
  final String keys;
  final String label;
}

List<KeyHint> hintsFor(String location) {
  if (location == '/settings') {
    return const [
      KeyHint('Tab', 'next field'),
      KeyHint('Ctrl+Enter', 'save'),
      KeyHint('Ctrl+B', 'backup now'),
      KeyHint('Esc', 'back'),
    ];
  }
  if (location == '/customers' ||
      location == '/items' ||
      location == '/cash-sales') {
    return const [
      KeyHint('↑↓', 'move'),
      KeyHint('Enter', 'open'),
      KeyHint('Ctrl+N', 'new'),
      KeyHint('Esc', 'dashboard'),
    ];
  }
  if (location == '/customers/new' ||
      location == '/items/new' ||
      location == '/customers/opening-balances') {
    return const [
      KeyHint('Tab', 'next field'),
      KeyHint('Ctrl+Enter', 'save'),
      KeyHint('Esc', 'back'),
    ];
  }
  if (location.startsWith('/customers/')) {
    return const [
      KeyHint('↑↓', 'move'),
      KeyHint('F2', 'edit'),
      KeyHint('Ctrl+P', 'print slip'),
      KeyHint('Esc', 'dashboard'),
    ];
  }
  if (location.startsWith('/bills/')) {
    return const [
      KeyHint('Tab', 'next cell'),
      KeyHint('Enter', 'pick / next / new line'),
      KeyHint('Ctrl+Enter', 'save'),
      KeyHint('Esc', 'cancel'),
    ];
  }
  return const [
    KeyHint('↑↓', 'move'),
    KeyHint('Enter', 'open ledger'),
    KeyHint('Ctrl+N', 'sale'),
    KeyHint('Ctrl+Shift+N', 'purchase'),
    KeyHint('Ctrl+I', 'cash in'),
    KeyHint('Ctrl+O', 'cash out'),
    KeyHint('Ctrl+F', 'search'),
  ];
}

/// Top-level destinations get the compact bottom nav + FAB; every other
/// route (bill form, ledger, new-customer/item forms, opening balances) is
/// a drill-down screen and gets a back button instead, matching how
/// [hintsFor] already special-cases routes by exact/prefix match.
bool isTopLevelRoute(String location) {
  const topLevel = {'/', '/customers', '/items', '/cash-sales', '/settings'};
  return topLevel.contains(location);
}

/// The frame every firm screen sits in: title bar, navigation rail with the
/// shortcut letter on each entry, the content, and the key-hint bar that
/// teaches the shortcuts by always showing what the keyboard can do right now.
class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.hints,
    required this.location,
  });

  final Widget child;
  final List<KeyHint> hints;

  /// Passed down from the ShellRoute builder's own `state`, not read back out
  /// of `GoRouterState.of(context)`: the shell sits in the *root* navigator's
  /// page, and popping a nested route inside the shell navigator leaves that
  /// page's registered state stale -- the back button and bottom nav then
  /// keep showing the drill-down chrome after the app has already returned to
  /// the list (reproduced on device and in a widget test).
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = L10n.of(context);
    final firm = ref.watch(openFirmProvider).value;
    final settings = ref.watch(firmSettingsProvider).value;
    final backup = ref.watch(backupRunnerProvider);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            context.go('/bills/new?type=sale'),
        const SingleActivator(
          LogicalKeyboardKey.keyN,
          control: true,
          shift: true,
        ): () =>
            context.go('/bills/new?type=purchase'),
        const SingleActivator(LogicalKeyboardKey.keyI, control: true): () =>
            context.go('/bills/new?type=cash_in'),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): () =>
            context.go('/bills/new?type=cash_out'),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
            context.go('/'),
        const SingleActivator(LogicalKeyboardKey.comma, control: true): () =>
            context.go('/settings'),
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
            ref.read(backupRunnerProvider.notifier).runNow(),
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (location != '/') context.go('/');
        },
      },
      child: Focus(
        autofocus: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < kCompactBreakpoint;
            return PopScope(
              // At a top-level route there's nowhere sensible to "go back"
              // to, so the system back gesture keeps its normal behaviour
              // (backgrounds/exits the app). At a drill-down route this is
              // the *last* fallback only: go_router tries the shell
              // navigator first, so a nested detail route pops to its list
              // and a screen with its own PopScope (BillScreen) handles its
              // own exit. This fires only for a drill-down that is neither,
              // e.g. the ledger opened straight from the dashboard.
              canPop: isTopLevelRoute(location),
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop && !isTopLevelRoute(location)) {
                  context.go('/');
                }
              },
              child: Scaffold(
                backgroundColor: c.paper,
                body: SafeArea(
                  child: Column(
                    children: [
                      _TitleBar(
                        firmName:
                            settings?.name ?? firm?.firmName ?? l10n.appName,
                        deviceCode: firm?.ctx.deviceShortCode,
                        backup: backup,
                        showBackButton: compact && !isTopLevelRoute(location),
                      ),
                      Expanded(
                        child: compact
                            ? child
                            : Row(
                                children: [
                                  _Rail(location: location),
                                  Expanded(child: child),
                                ],
                              ),
                      ),
                      if (!compact) _KeyBar(hints: hints),
                    ],
                  ),
                ),
                bottomNavigationBar: compact && isTopLevelRoute(location)
                    ? _CompactNav(location: location)
                    : null,
                floatingActionButton: compact
                    ? _fabFor(context, location)
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Builds the compact-width FAB for [location], or null when that route has
/// nothing to "add" (settings) or isn't a top-level destination at all
/// (defensive -- [_fabConfigFor]'s switch only lists top-level routes).
Widget? _fabFor(BuildContext context, String location) {
  final config = _fabConfigFor(location);
  if (config == null) return null;
  return FloatingActionButton(
    key: config.key,
    onPressed: () => config.onPressed(context),
    child: Icon(config.icon),
  );
}

class _FabConfig {
  const _FabConfig({
    required this.key,
    required this.icon,
    required this.onPressed,
  });
  final Key key;
  final IconData icon;
  final void Function(BuildContext) onPressed;
}

_FabConfig? _fabConfigFor(String location) {
  switch (location) {
    case '/':
      return _FabConfig(
        key: const Key('shell.fab.newSale'),
        icon: Icons.add,
        onPressed: (context) => context.go('/bills/new?type=sale'),
      );
    case '/customers':
      return _FabConfig(
        key: const Key('shell.fab.addCustomer'),
        icon: Icons.person_add,
        onPressed: (context) => context.go('/customers/new'),
      );
    case '/items':
      return _FabConfig(
        key: const Key('shell.fab.addItem'),
        icon: Icons.add,
        onPressed: (context) => context.go('/items/new'),
      );
    case '/cash-sales':
      return _FabConfig(
        key: const Key('shell.fab.cashChooser'),
        icon: Icons.add,
        onPressed: _chooseCashDirection,
      );
    default:
      // /settings has nothing to "add"; anything else isn't a top-level
      // route and shouldn't reach here, but no FAB is the safe default.
      return null;
  }
}

/// Desktop has separate Ctrl+I/Ctrl+O shortcuts for cash in vs cash out with
/// no single obvious default, so the touch FAB offers the same choice via a
/// dialog instead of picking one for the user -- same showDialog +
/// SimpleDialog/SimpleDialogOption convention as settings_screen.dart's
/// printer picker.
Future<void> _chooseCashDirection(BuildContext context) async {
  final choice = await showDialog<String>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      key: const Key('shell.cashChooserDialog'),
      title: const Text('Record cash'),
      children: [
        SimpleDialogOption(
          key: const Key('shell.cashChooserDialog.cashIn'),
          onPressed: () => Navigator.of(dialogContext).pop('cash_in'),
          child: const Text('Cash in'),
        ),
        SimpleDialogOption(
          key: const Key('shell.cashChooserDialog.cashOut'),
          onPressed: () => Navigator.of(dialogContext).pop('cash_out'),
          child: const Text('Cash out'),
        ),
      ],
    ),
  );
  if (choice != null && context.mounted) {
    context.go('/bills/new?type=$choice');
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.firmName,
    this.deviceCode,
    required this.backup,
    this.showBackButton = false,
  });
  final BackupStatus backup;
  final String firmName;
  final String? deviceCode;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.ruleSoft)),
      ),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              key: const Key('shell.backButton'),
              icon: const Icon(Icons.arrow_back, size: 18),
              padding: EdgeInsets.zero,
              // Routed through the same pop path the Android system back
              // gesture uses (Router -> routerDelegate.popRoute), rather
              // than a bare context.go('/'), so the two can never disagree:
              // popRoute walks the shell navigator first, which pops a
              // nested detail route or fires the current screen's own
              // PopScope (BillScreen's unsaved-bill guard). Only when
              // nothing at all handled the pop does it fall back to the
              // dashboard.
              onPressed: () async {
                final router = GoRouter.of(context);
                if (!await router.routerDelegate.popRoute()) {
                  if (context.mounted) router.go('/');
                }
              },
            ),
          // Expanded + ellipsis rather than a bare Text and a Spacer: a real
          // firm name ("Al-Madina Oil Mills") plus the backup line and the
          // device code overflow this Row at phone width, which is the same
          // RenderFlex overflow the rest of the branch removed everywhere
          // else. Expanded also does the Spacer's job of pushing the trailing
          // items right.
          Expanded(
            child: Text(
              firmName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          if (backup.lastAt case final t?) ...[
            Text(
              'Backed up ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} ✓',
              style: TextStyle(fontSize: 12.5, color: c.receivable),
            ),
            const SizedBox(width: 18),
          ],
          if (deviceCode != null) ...[
            Text('Device ', style: TextStyle(color: c.ink2, fontSize: 13)),
            Text(
              deviceCode!,
              style: numberStyle.copyWith(fontSize: 13, color: c.ink2),
            ),
          ],
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = L10n.of(context);
    final entries = [
      ('D', l10n.navDashboard, '/'),
      ('C', l10n.navCustomers, '/customers'),
      ('I', l10n.navItems, '/items'),
      ('S', l10n.navCashSales, '/cash-sales'),
      (',', l10n.navSettings, '/settings'),
    ];
    return Container(
      width: 96,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(right: BorderSide(color: c.ruleSoft)),
      ),
      child: Column(
        children: [
          for (final (key, label, route) in entries)
            _RailEntry(
              letter: key,
              label: label,
              selected:
                  route == location ||
                  (route == '/' && key == 'D' && location == '/'),
              onTap: () => context.go(route),
            ),
        ],
      ),
    );
  }
}

class _RailEntry extends StatelessWidget {
  const _RailEntry({
    required this.letter,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String letter;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.accent : c.ink2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.accentSoft : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: selected ? c.accent : c.rule),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                letter,
                style: numberStyle.copyWith(fontSize: 11, color: color),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12.5, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyBar extends StatelessWidget {
  const _KeyBar({required this.hints});
  final List<KeyHint> hints;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 38,
      color: c.keybar,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final h in hints)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    h.keys,
                    style: numberStyle.copyWith(
                      fontSize: 12,
                      color: c.keybarInk,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  h.label,
                  style: TextStyle(fontSize: 12.5, color: c.keybarInk),
                ),
                const SizedBox(width: 22),
              ],
            ),
        ],
      ),
    );
  }
}

class _CompactNav extends StatelessWidget {
  const _CompactNav({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    const routes = ['/', '/customers', '/items', '/cash-sales', '/settings'];
    final index = routes.indexOf(location) == -1 ? 0 : routes.indexOf(location);
    return NavigationBar(
      key: const Key('shell.bottomNav'),
      selectedIndex: index,
      onDestinationSelected: (i) => context.go(routes[i]),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.dashboard),
          label: l10n.navDashboard,
        ),
        NavigationDestination(
          icon: const Icon(Icons.people),
          label: l10n.navCustomers,
        ),
        NavigationDestination(
          icon: const Icon(Icons.inventory_2),
          label: l10n.navItems,
        ),
        NavigationDestination(
          icon: const Icon(Icons.point_of_sale),
          label: l10n.navCashSales,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings),
          label: l10n.navSettings,
        ),
      ],
    );
  }
}
