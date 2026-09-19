import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../bootstrap/providers.dart';
import '../features/settings/settings_providers.dart';
import '../l10n/app_localizations.dart';
import '../theme/ledgerly_theme.dart';

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
  if (location == '/customers' || location == '/items') {
    return const [
      KeyHint('↑↓', 'move'),
      KeyHint('Enter', 'open'),
      KeyHint('Ctrl+N', 'new'),
      KeyHint('Esc', 'dashboard'),
    ];
  }
  if (location == '/customers/new' || location == '/items/new') {
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

/// The frame every firm screen sits in: title bar, navigation rail with the
/// shortcut letter on each entry, the content, and the key-hint bar that
/// teaches the shortcuts by always showing what the keyboard can do right now.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.hints});

  final Widget child;
  final List<KeyHint> hints;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = L10n.of(context);
    final firm = ref.watch(openFirmProvider).value;
    final settings = ref.watch(firmSettingsProvider).value;
    final backup = ref.watch(backupRunnerProvider);
    final location = GoRouterState.of(context).matchedLocation;
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
        child: Scaffold(
          backgroundColor: c.paper,
          body: Column(
            children: [
              _TitleBar(
                firmName: settings?.name ?? firm?.firmName ?? l10n.appName,
                deviceCode: firm?.ctx.deviceShortCode,
                backup: backup,
              ),
              Expanded(
                child: Row(
                  children: [
                    _Rail(location: location),
                    Expanded(child: child),
                  ],
                ),
              ),
              _KeyBar(hints: hints),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.firmName,
    this.deviceCode,
    required this.backup,
  });
  final BackupStatus backup;
  final String firmName;
  final String? deviceCode;

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
          Text(
            firmName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const Spacer(),
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
      ('S', l10n.navCashSales, '/'),
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
