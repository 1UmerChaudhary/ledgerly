# Android Support (Phase 3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the existing Flutter desktop app run as a genuine full-parity Android app — same local drift database, every screen, touch-first layout below a 600dp width breakpoint, plus a Bluetooth ESC/POS thermal-printing path and Downloads-folder export.

**Architecture:** Presentation-layer-only change. A single `kCompactBreakpoint = 600` constant drives width-based branching (not platform checks) inside `AppShell`, the bill form, and the ledger screen; every domain/data/controller class (`packages/ledgerly_core`, `packages/ledgerly_data`, all Riverpod notifiers) is reused completely unchanged. Printing gets a second, parallel renderer (`buildSlipEscPos`, pure Dart) feeding a new `ThermalPrinterService` seam, alongside the existing PDF path — not a replacement of it.

**Tech Stack:** Flutter 3.47.5 / Dart 3.13.4, Riverpod 3.4.3, go_router 18.0.1, drift. New deps: `print_bluetooth_thermal: ^1.2.4` (Bluetooth SPP transport, Android-native), `flutter_file_downloader: ^2.1.1` (writes bytes to the public Downloads folder via a `data:` URI).

**Spec:** `docs/superpowers/specs/2026-09-20-android-support-design.md`

## Global Constraints

- Breakpoint is **600dp**, defined once, never duplicated (Material 3's compact/medium cutoff — see spec "Layout strategy").
- No changes to `packages/ledgerly_core` or `packages/ledgerly_data` domain/controller logic — only new pure-Dart additions (the ESC/POS renderer) and new prefs fields, additive only.
- `CallbackShortcuts` in `AppShell` stay wired in unconditionally at every width (spec: "free bonus... costs nothing to keep").
- Bluetooth transport (`print_bluetooth_thermal`) is faked in every widget test — no real Bluetooth I/O in CI, same convention as `PrintingService`/`FakePrintingService`.
- Every new widget gets a `Key('domain.widget')`-style key for test targeting, matching this repo's existing convention (see `cloud_sync_settings_test.dart`'s `Key('settings.cloudEmail')` etc.).
- TDD throughout: write the failing test, watch it fail, minimal code, watch it pass, commit.

---

## Task 1: Test harness support for phone-sized/Android widget tests

**Files:**
- Modify: `app/test/support/pump_app.dart:32-36` (the `pumpLedgerly` signature and its hardcoded `tester.view.physicalSize`), and line 121 (`windowsOnly` definition — add `phoneOnly` alongside it).
- Create: `app/lib/shell/breakpoints.dart`
- Test: `app/test/features/first_launch_and_dashboard_test.dart` (existing file — add one new test to it, do not create a new test file for this task since it's exercising an existing screen).

**Interfaces:**
- Produces: `const double kCompactBreakpoint = 600;` in `app/lib/shell/breakpoints.dart` — every later task imports this constant, never redefines it.
- Produces: `pumpLedgerly(tester, {seed, Size? viewSize})` — `viewSize` defaults to the existing `Size(1280, 800)` so every current test keeps passing unchanged.
- Produces: `final phoneOnly = TargetPlatformVariant.only(TargetPlatform.android);` in `pump_app.dart`, next to `windowsOnly`.

- [ ] **Step 1: Write the failing test**

Add to `app/test/features/first_launch_and_dashboard_test.dart` (open the file first to see its existing `seed`/imports and match them — this step only adds the test below, using the same `seed` helper already defined there):

```dart
  testWidgets('dashboard renders at phone width without the desktop rail', (
    tester,
  ) async {
    await pumpLedgerly(tester, seed: seed, viewSize: const Size(390, 844));

    expect(find.byKey(const Key('shell.bottomNav')), findsOneWidget);
  }, variant: phoneOnly);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd app && flutter test test/features/first_launch_and_dashboard_test.dart`
Expected: FAIL — `pumpLedgerly` has no `viewSize` parameter (compile error), and `phoneOnly` is undefined.

- [ ] **Step 3: Write minimal implementation**

Create `app/lib/shell/breakpoints.dart`:

```dart
/// Material 3's compact/medium width cutoff. Below this, screens switch to
/// touch-first stacked layouts; at or above it, the existing desktop
/// two-pane layout is used unchanged. Defined once here — every width check
/// in the app imports this instead of hardcoding 600.
const double kCompactBreakpoint = 600;
```

In `app/test/support/pump_app.dart`, change the signature (around line 26) and the hardcoded size (around line 32):

```dart
Future<ProviderContainer> pumpLedgerly(
  WidgetTester tester, {
  Future<void> Function(AppDatabase db, DeviceContext ctx)? seed,
  Size viewSize = const Size(1280, 800),
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  tester.view.physicalSize = viewSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
```

And add, next to the existing `windowsOnly` line:

```dart
final windowsOnly = TargetPlatformVariant.only(TargetPlatform.windows);
final phoneOnly = TargetPlatformVariant.only(TargetPlatform.android);
```

This step alone will not make the new test pass yet — `Key('shell.bottomNav')` doesn't exist. That's Task 2. Confirm here only that the harness compiles and the test now fails for the *right* reason.

- [ ] **Step 4: Run test to verify it fails for the right reason**

Run: `cd app && flutter test test/features/first_launch_and_dashboard_test.dart`
Expected: FAIL — compiles fine now, fails on `expect(find.byKey(const Key('shell.bottomNav')), findsOneWidget)` because that widget doesn't exist yet (`findsNothing`). Confirm every other existing test file still compiles and passes: `flutter test`.

- [ ] **Step 5: Commit**

```bash
git add app/lib/shell/breakpoints.dart app/test/support/pump_app.dart app/test/features/first_launch_and_dashboard_test.dart
git commit -m "Test harness: phone-sized pumpLedgerly + phoneOnly variant + kCompactBreakpoint"
```

---

## Task 2: AppShell compact chrome (bottom nav, FAB, back button)

**Files:**
- Modify: `app/lib/shell/app_shell.dart` — the whole file; add compact-width branching inside `AppShell.build()`.
- Test: `app/test/features/first_launch_and_dashboard_test.dart` (finish the test added in Task 1; add two more).

**Interfaces:**
- Consumes: `kCompactBreakpoint` (Task 1), `hintsFor(String location)` (existing, unchanged), `go_router`'s `context.go`/`context.pop`/`GoRouterState.of(context).matchedLocation` (existing usage pattern in this same file).
- Produces: a new top-level function `bool isTopLevelRoute(String location)` in `app_shell.dart`, used only by `AppShell` itself but exported (no leading underscore) so Task 3/4 tests can assert against it directly if needed.
- Produces: `Key('shell.bottomNav')`, `Key('shell.fab.newSale')`, `Key('shell.backButton')`.

- [ ] **Step 1: Write the failing tests**

Finish the Task 1 test (it already asserts `Key('shell.bottomNav')` exists at phone width) and add two more to the same file:

```dart
  testWidgets('desktop width still shows the nav rail, not the bottom nav', (
    tester,
  ) async {
    await pumpLedgerly(tester, seed: seed); // default desktop size

    expect(find.byKey(const Key('shell.bottomNav')), findsNothing);
  }, variant: windowsOnly);

  testWidgets('a drill-down route at phone width shows a back button, not the bottom nav', (
    tester,
  ) async {
    final container = await pumpLedgerly(
      tester,
      seed: seed,
      viewSize: const Size(390, 844),
    );
    container.read(routerProvider).go('/bills/new?type=sale');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shell.backButton')), findsOneWidget);
    expect(find.byKey(const Key('shell.bottomNav')), findsNothing);
  }, variant: phoneOnly);
```

(`routerProvider` is already imported transitively via `package:ledgerly/app.dart` in this test file's existing imports — if not, add `import 'package:ledgerly/bootstrap/router.dart';`.)

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd app && flutter test test/features/first_launch_and_dashboard_test.dart`
Expected: the phone-width test still fails (`findsNothing` where `findsOneWidget` expected) exactly as in Task 1; the desktop test passes already (nothing to find, correctly); the drill-down test fails (`shell.backButton` doesn't exist).

- [ ] **Step 3: Write minimal implementation**

In `app_shell.dart`, add near `hintsFor`:

```dart
/// Top-level destinations get the compact bottom nav + FAB; every other
/// route (bill form, ledger, new-customer/item forms, opening balances) is
/// a drill-down screen and gets a back button instead, matching how
/// [hintsFor] already special-cases routes by exact/prefix match.
bool isTopLevelRoute(String location) {
  const topLevel = {'/', '/customers', '/items', '/cash-sales', '/settings'};
  return topLevel.contains(location);
}
```

Replace the body of `AppShell.build` (currently a fixed `Scaffold` with `_TitleBar` + `Row(_Rail, child)` + `_KeyBar`) with a `LayoutBuilder` that branches on width, keeping the existing expanded path byte-for-byte and adding a new compact path:

```dart
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < kCompactBreakpoint;
            return Scaffold(
              backgroundColor: c.paper,
              body: Column(
                children: [
                  _TitleBar(
                    firmName: settings?.name ?? firm?.firmName ?? l10n.appName,
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
              bottomNavigationBar:
                  compact && isTopLevelRoute(location)
                  ? _CompactNav(location: location)
                  : null,
              floatingActionButton:
                  compact && isTopLevelRoute(location)
                  ? FloatingActionButton(
                      key: const Key('shell.fab.newSale'),
                      onPressed: () => context.go('/bills/new?type=sale'),
                      child: const Icon(Icons.add),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
```

Update `_TitleBar` to take the new `showBackButton` param and render a back button:

```dart
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
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
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
```

Add the new compact nav widget (near `_Rail`):

```dart
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
        NavigationDestination(icon: const Icon(Icons.dashboard), label: l10n.navDashboard),
        NavigationDestination(icon: const Icon(Icons.people), label: l10n.navCustomers),
        NavigationDestination(icon: const Icon(Icons.inventory_2), label: l10n.navItems),
        NavigationDestination(icon: const Icon(Icons.point_of_sale), label: l10n.navCashSales),
        NavigationDestination(icon: const Icon(Icons.settings), label: l10n.navSettings),
      ],
    );
  }
}
```

Add `import '../shell/breakpoints.dart';` (adjust relative path to `breakpoints.dart` if `app_shell.dart` and `breakpoints.dart` are siblings — they are, both under `app/lib/shell/`, so use `import 'breakpoints.dart';`).

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd app && flutter test test/features/first_launch_and_dashboard_test.dart`
Expected: all three new tests PASS. Then run the full suite to confirm nothing desktop-side broke: `flutter test`. Every existing `windowsOnly` test must still pass unchanged — the expanded-width path is untouched logic, only reachable through a new `LayoutBuilder` wrapper.

- [ ] **Step 5: Commit**

```bash
git add app/lib/shell/app_shell.dart app/test/features/first_launch_and_dashboard_test.dart
git commit -m "Shell: compact bottom nav + FAB + back button below 600dp, desktop rail unchanged above it"
```

---

## Task 3: Bill form touch redesign

**Files:**
- Create: `app/lib/features/bills/widgets/line_card.dart`
- Create: `app/lib/features/bills/widgets/item_search_sheet.dart`
- Modify: `app/lib/features/bills/bill_screen.dart` — wrap the `_LinesGrid` vs. new card-list choice in a `LayoutBuilder`. `_Header`'s customer field is untouched: `EntityAutocomplete` is a plain `TextField`-based widget that already works fine with touch, so only the *grid* needs a touch alternative, not every field on the screen.
- Test: `app/test/features/bill_form_test.dart` (existing file — add new tests using `phoneOnly`; do not remove or alter existing `windowsOnly` tests).

**Interfaces:**
- Consumes: `billDraftProvider(BillFormKey)` / `BillDraftController` methods `pickItem(int, Item)`, `editLineField(int, String, String)`, `toggleMode(int)`, `addLine()`, `removeLine(int)` (all existing, unchanged, per spec's finding that the notifier has no focus/keyboard coupling); `LineDraft` fields `id, item, mode, bags, bagKg, totalKg, rate, base, override` (existing, unchanged); `SaleMode` enum (`byBags`, `byWeight`, `byCount`, from `ledgerly_core`); `RateBase.presets` (`List<Weight>`, from `ledgerly_core`); `itemsListProvider` (existing, watched in `bill_draft.dart`, re-watched here the same way `_LinesGrid` already does via its `items` param).
- Produces: `LineCard` widget (public), `ItemSearchSheet` widget (public, returns the picked `Item` via `Navigator.pop(context, item)`), both usable independently of `bill_screen.dart`'s internals.

- [ ] **Step 1: Write the failing test**

Add to `app/test/features/bill_form_test.dart` (match its existing imports/`seed` helper):

```dart
  testWidgets('at phone width, a sale line renders as a touch card, not the grid', (
    tester,
  ) async {
    await pumpLedgerly(tester, seed: seed, viewSize: const Size(390, 844));
    await tester.pumpAndSettle(); // dashboard first at phone width
    // Navigate to a new sale via the FAB added in Task 2.
    await tester.tap(find.byKey(const Key('shell.fab.newSale')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bill.line.0.card')), findsOneWidget);
    expect(find.byKey(const Key('bill.line.0.card.deleteButton')), findsOneWidget);
  }, variant: phoneOnly);

  testWidgets('tapping a card delete button removes that line', (
    tester,
  ) async {
    await pumpLedgerly(tester, seed: seed, viewSize: const Size(390, 844));
    await tester.tap(find.byKey(const Key('shell.fab.newSale')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bill.line.card.addLine')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bill.line.1.card')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bill.line.1.card.deleteButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bill.line.1.card')), findsNothing);
  }, variant: phoneOnly);
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd app && flutter test test/features/bill_form_test.dart`
Expected: FAIL — `Key('bill.line.0.card')` not found; at phone width the screen still renders the desktop `_LinesGrid` (which uses different keys), so `findsNothing` where `findsOneWidget` was expected.

- [ ] **Step 3: Write minimal implementation**

Create `app/lib/features/bills/widgets/item_search_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:ledgerly_core/ledgerly_core.dart';

/// Full-screen item search for touch — the phone equivalent of typing into
/// [EntityAutocomplete] and pressing Enter. Pops with the picked [Item], or
/// null if the user backs out without picking one.
class ItemSearchSheet extends StatefulWidget {
  const ItemSearchSheet({super.key, required this.items});
  final List<Item> items;

  static Future<Item?> show(BuildContext context, List<Item> items) {
    return Navigator.of(context).push<Item>(
      MaterialPageRoute(builder: (_) => ItemSearchSheet(items: items)),
    );
  }

  @override
  State<ItemSearchSheet> createState() => _ItemSearchSheetState();
}

class _ItemSearchSheetState extends State<ItemSearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final matches = widget.items
        .where((i) => i.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('itemSearch.field'),
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search items'),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      body: ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, i) => ListTile(
          key: Key('itemSearch.result.${matches[i].id}'),
          title: Text(matches[i].name),
          onTap: () => Navigator.of(context).pop(matches[i]),
        ),
      ),
    );
  }
}
```

Create `app/lib/features/bills/widgets/line_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:ledgerly_core/ledgerly_core.dart';

import 'item_search_sheet.dart';

/// Touch equivalent of a grid row: one line of a bill as a tappable card
/// instead of Tab/Enter-driven cells. Calls the exact same
/// [BillDraftController] mutation methods the desktop grid calls — this
/// widget owns no state of its own beyond text-field controllers.
class LineCard extends StatelessWidget {
  const LineCard({
    super.key,
    required this.index,
    required this.line,
    required this.items,
    required this.onPickItem,
    required this.onEdit,
    required this.onToggleMode,
    required this.onDelete,
  });

  final int index;
  final LineDraft line;
  final List<Item> items;
  final void Function(Item) onPickItem;
  final void Function(String field, String value) onEdit;
  final VoidCallback onToggleMode;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('bill.line.$index.card'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: Key('bill.line.$index.card.itemButton'),
                    onPressed: () async {
                      final picked = await ItemSearchSheet.show(context, items);
                      if (picked != null) onPickItem(picked);
                    },
                    child: Text(line.item?.name ?? 'Pick item'),
                  ),
                ),
                IconButton(
                  key: Key('bill.line.$index.card.deleteButton'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            SegmentedButton<SaleMode>(
              key: Key('bill.line.$index.card.modeToggle'),
              segments: const [
                ButtonSegment(value: SaleMode.byBags, label: Text('Bags')),
                ButtonSegment(value: SaleMode.byWeight, label: Text('Weight')),
                ButtonSegment(value: SaleMode.byCount, label: Text('Count')),
              ],
              selected: {line.mode},
              onSelectionChanged: (_) => onToggleMode(),
            ),
            if (line.mode == SaleMode.byBags) ...[
              _numberField('bags', 'Bags', line.bags),
              _numberField('bagKg', 'Bag weight (kg)', line.bagKg),
            ] else if (line.mode == SaleMode.byWeight)
              _numberField('totalKg', 'Total weight (kg)', line.totalKg),
            Wrap(
              spacing: 6,
              children: [
                for (final preset in RateBase.presets)
                  ActionChip(
                    key: Key('bill.line.$index.card.basePreset.${preset.grams}'),
                    label: Text('${preset.grams / 1000}kg'),
                    onPressed: () =>
                        onEdit('base', (preset.grams / 1000).toString()),
                  ),
              ],
            ),
            _numberField('rate', 'Rate', line.rate),
          ],
        ),
      ),
    );
  }

  Widget _numberField(String field, String label, String value) {
    return TextFormField(
      key: Key('bill.line.$index.card.$field'),
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) => onEdit(field, v),
    );
  }
}
```

In `bill_screen.dart`, add the import and wrap the existing grid-vs-amount-row choice. Find the line that currently reads (per the spec's mapping) `d.hasLines ? _LinesGrid(...) : _AmountRow(...)` inside `build()`, and change it to:

```dart
import 'package:flutter/material.dart' show LayoutBuilder;
import '../../shell/breakpoints.dart';
import 'widgets/line_card.dart';
```

```dart
            if (d.hasLines)
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < kCompactBreakpoint) {
                    return Column(
                      children: [
                        for (var i = 0; i < d.lines.length; i++)
                          LineCard(
                            index: i,
                            line: d.lines[i],
                            items: items,
                            onPickItem: (item) => _ctl.pickItem(i, item),
                            onEdit: (field, value) =>
                                _ctl.editLineField(i, field, value),
                            onToggleMode: () => _ctl.toggleMode(i),
                            onDelete: () => _ctl.removeLine(i),
                          ),
                        TextButton(
                          key: const Key('bill.line.card.addLine'),
                          onPressed: () => _ctl.addLine(),
                          child: const Text('+ Add line'),
                        ),
                      ],
                    );
                  }
                  return _LinesGrid(
                    d: d,
                    items: items,
                    focusFor: _focusFor,
                    onPickItem: (i, item) => _ctl.pickItem(i, item),
                    onEdit: (i, field, value) => _ctl.editLineField(i, field, value),
                    onToggleMode: (i) => _ctl.toggleMode(i),
                    onEnter: (i, field) => _enterOn(i, field, d),
                  );
                },
              )
            else
              _AmountRow(d: d),
```

(`items` here is whatever variable name `build()` already uses for the item list — it's already passed into `_LinesGrid` today, so reuse that exact existing local variable rather than re-fetching it. `onEnter: (i, field) => _enterOn(i, field, d)` reconstructs the existing wiring: `_enterOn(int index, String field, BillDraft d)` is `_BillScreenState`'s existing Enter-key handler (lines 129–142), and `_LinesGrid.onEnter` is typed `void Function(int, String)` — two params — so the existing call site must already close over `d` this same way. If the real existing line differs in any cosmetic way (e.g. it's already extracted to a tear-off), match whatever's actually there rather than introducing a second name for the same thing.)

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd app && flutter test test/features/bill_form_test.dart`
Expected: both new tests PASS. Run the full suite (`flutter test`) to confirm every existing `windowsOnly` bill-form test still passes — the `_LinesGrid` branch is reached identically to before at desktop width, just now inside a `LayoutBuilder` rather than directly inline.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/bills/widgets/line_card.dart app/lib/features/bills/widgets/item_search_sheet.dart app/lib/features/bills/bill_screen.dart app/test/features/bill_form_test.dart
git commit -m "Bill form: touch line cards + item search sheet below 600dp, grid unchanged above it"
```

---

## Task 4: Ledger touch redesign (stacked routes)

**Files:**
- Modify: `app/lib/features/ledger/ledger_screen.dart` — promote `_DetailPanel` to a public `LedgerDetailPanel` (drop the leading underscore; no behavior change), and make `_LedgerScreenState.build()` branch on width for how a row tap is handled.
- Modify: `app/lib/bootstrap/router.dart` — add one new route.
- Create: `app/lib/features/ledger/ledger_detail_screen.dart`
- Test: `app/test/features/ledger_screen_test.dart` (existing file — add new tests using `phoneOnly`).

**Interfaces:**
- Consumes: `ledgerEntriesProvider(LedgerKey)` (existing, `typedef LedgerKey = ({String customerId, bool includeDeleted})`), `billHistoryProvider(String billId)` (existing, already read inside the detail panel itself), `itemsListProvider` (existing, for `itemNames`).
- Produces: `LedgerDetailScreen` (new, public), taking `customerId` and `billId` as constructor params, re-deriving its `LedgerEntry` by re-watching `ledgerEntriesProvider` and finding the matching bill id (no new provider needed — `_DetailPanel`/`LedgerDetailPanel` needs the full `LedgerEntry`, not just an id, and no single-bill provider exists per the spec's mapping).
- Produces: new route `/customers/:id/bills/:billId` inside the existing `ShellRoute` block in `router.dart`.

- [ ] **Step 1: Write the failing test**

Add to `app/test/features/ledger_screen_test.dart` (match its existing `seed`/customer-with-a-bill setup pattern used by its other tests):

```dart
  testWidgets('at phone width, tapping a ledger row pushes a detail screen instead of showing a side panel', (
    tester,
  ) async {
    // Reuse this file's existing seed-with-one-bill setup here (see the
    // other tests in this file for the exact customer+bill seeding helper
    // already in use) so `entries` is non-empty.
    await pumpLedgerly(tester, seed: seedWithOneBill, viewSize: const Size(390, 844));
    await tester.tap(find.text('Test Customer')); // navigate into the ledger
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ledger.detailPanel')), findsNothing);

    await tester.tap(find.byType(InkWell).first); // first ledger row
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ledger.detailPanel')), findsOneWidget);
    expect(find.byKey(const Key('shell.backButton')), findsOneWidget);
  }, variant: phoneOnly);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd app && flutter test test/features/ledger_screen_test.dart`
Expected: FAIL — at phone width the row tap still sets local `_selected` state and shows the fixed-340px side panel inline (no navigation happens), so `Key('ledger.detailPanel')` is never found via a pushed route.

- [ ] **Step 3: Write minimal implementation**

In `ledger_screen.dart`, rename `_DetailPanel` to `LedgerDetailPanel` (drop the underscore everywhere it's referenced in this file — the class body is unchanged) and add `Key('ledger.detailPanel')` to its outermost widget:

```dart
class LedgerDetailPanel extends ConsumerWidget {
  const LedgerDetailPanel({
    super.key,
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
    return Container(
      key: const Key('ledger.detailPanel'),
      // ... existing body unchanged, just renamed from _DetailPanel ...
    );
  }
}
```

(The real edit here is a rename + one added `key:` — every other line of the existing `_DetailPanel` body stays exactly as it is. Do this with a project-wide rename within this one file only, not a find/replace across the repo, since `_DetailPanel` is file-private and can't be referenced elsewhere yet.)

In `_LedgerScreenState.build()`, find the `Row` with the two panes (`_LedgerTable` + the fixed-340px detail box) and change the row-tap callback passed to `_LedgerTable`'s `onTap` to branch on width:

```dart
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _LedgerTable(
                          entries: entries,
                          selected: _selected,
                          onTap: (i) {
                            final compact =
                                MediaQuery.of(context).size.width < kCompactBreakpoint;
                            if (compact) {
                              context.go(
                                '/customers/${widget.customerId}/bills/${entries[i].bill.id}',
                              );
                            } else {
                              setState(() => _selected = i);
                            }
                          },
                        ),
                      ),
                      if (MediaQuery.of(context).size.width >= kCompactBreakpoint)
                        SizedBox(
                          width: 340,
                          child: selected == null
                              ? const SizedBox.shrink()
                              : LedgerDetailPanel(
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
```

(`entries`, `selected`, `itemNames`, `_selectedHistoryVersion` are the existing local variables already used in this exact spot per the spec's mapping — keep using them as-is; only the `onTap` callback and the `if` guard around the detail pane are new. Add `import 'package:go_router/go_router.dart';` and `import '../../shell/breakpoints.dart';` if not already imported in this file.)

Create `app/lib/features/ledger/ledger_detail_screen.dart`:

```dart
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
      ledgerEntriesProvider((customerId: widget.customerId, includeDeleted: true)),
    );
    return entriesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (entries) {
        final entry = entries.firstWhere((e) => e.bill.id == widget.billId);
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
```

(`itemsListProvider` is declared in `app/lib/features/bills/bill_draft.dart:417`, not `bootstrap/providers.dart` — confirmed by reading the source directly. `ledgerEntriesProvider` is declared in `ledger_screen.dart` itself, already unprivate per its existing `final ledgerEntriesProvider = ...` — only `LedgerKey`, the typedef used to key it, is not needed here since the record literal `(customerId: ..., includeDeleted: true)` is passed positionally and inferred.)

In `router.dart`, add inside the existing `ShellRoute`'s route list, next to the `/customers/:id` route:

```dart
        GoRoute(
          path: '/customers/:id/bills/:billId',
          builder: (_, s) => LedgerDetailScreen(
            customerId: s.pathParameters['id']!,
            billId: s.pathParameters['billId']!,
          ),
        ),
```

(Add `import '../features/ledger/ledger_detail_screen.dart';` at the top of `router.dart`.) This route sits inside the `ShellRoute`, so it gets `AppShell` chrome automatically — at compact width with a non-top-level location, Task 2's `isTopLevelRoute` check already returns `false` for this path (it's not in the `topLevel` set), so the back button appears and the bottom nav/FAB do not, with no further change needed.

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd app && flutter test test/features/ledger_screen_test.dart`
Expected: PASS. Run the full suite to confirm desktop ledger behavior (side panel, `_selected` state) is unchanged at desktop width.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/ledger/ledger_screen.dart app/lib/features/ledger/ledger_detail_screen.dart app/lib/bootstrap/router.dart app/test/features/ledger_screen_test.dart
git commit -m "Ledger: push a detail screen below 600dp instead of the inline side panel"
```

---

## Task 5: ESC/POS slip renderer (pure Dart)

**Files:**
- Create: `packages/ledgerly_data/lib/src/printing/esc_pos_renderer.dart`
- Modify: `packages/ledgerly_data/lib/ledgerly_data.dart` (export the new file, matching how `slip_pdf.dart` is already exported — check this file's existing export list and add the new one alongside it).
- Test: `packages/ledgerly_data/test/printing/esc_pos_renderer_test.dart` (new file, plain `dart test` — this is pure Dart, no Flutter widget involved, matching how `slip_pdf.dart`'s own tests already run, per the spec's testing section).

**Interfaces:**
- Consumes: `SlipModel`, `SlipLineView` (existing, `packages/ledgerly_data/lib/src/printing/print_models.dart`), `Money`, `formatMoney` (existing, `ledgerly_core`).
- Produces: `Uint8List buildSlipEscPos(SlipModel s)` — the ESC/POS-bytes equivalent of the existing `Future<Uint8List> buildSlipPdf(SlipModel s)`, same input type, synchronous (no async I/O needed to build bytes, unlike the PDF renderer which is `async` for the underlying `pdf` package's API).

- [ ] **Step 1: Write the failing test**

Create `packages/ledgerly_data/test/printing/esc_pos_renderer_test.dart`:

```dart
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:test/test.dart';

void main() {
  test('slip renders firm name, customer, and total as plain text between init and cut', () {
    final slip = SlipModel(
      firmName: 'Test Mill',
      firmContact: '0300-1234567',
      firmAddress: null,
      displayNo: 'A3F9-1',
      entryDate: '2026-09-20',
      customerName: 'Ali Traders',
      lines: [
        const SlipLineView(
          itemName: 'Cotton oil',
          quantityDescription: '2 bags x 37.324kg',
          rateDescription: 'Rs 5,000/maund',
          amount: Money(1000000),
        ),
      ],
      total: const Money(1000000),
      previousBalance: const Money(0),
      newBalance: const Money(1000000),
      edited: false,
      printedAt: 1700000000000,
      deviceCode: 'AB12',
    );

    final bytes = buildSlipEscPos(slip);
    final text = String.fromCharCodes(bytes.where((b) => b >= 0x20 && b < 0x7f));

    expect(bytes.first, 0x1B); // ESC
    expect(bytes[1], 0x40); // @ -- init command
    expect(text, contains('Test Mill'));
    expect(text, contains('Ali Traders'));
    expect(text, contains('Cotton oil'));
    expect(bytes.sublist(bytes.length - 4), [0x1D, 0x56, 0x00, 0x00]); // GS V 0 0 -- full cut
  });

  test('a walk-in sale (no customer) prints "Cash Sale" instead of a name', () {
    final slip = SlipModel(
      firmName: 'Test Mill',
      firmContact: '0300-1234567',
      firmAddress: null,
      displayNo: 'A3F9-2',
      entryDate: '2026-09-20',
      customerName: null,
      lines: const [],
      total: const Money(50000),
      previousBalance: null,
      newBalance: null,
      edited: false,
      printedAt: 1700000000000,
      deviceCode: 'AB12',
    );

    final bytes = buildSlipEscPos(slip);
    final text = String.fromCharCodes(bytes.where((b) => b >= 0x20 && b < 0x7f));

    expect(text, contains('Cash Sale'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/ledgerly_data && dart test test/printing/esc_pos_renderer_test.dart`
Expected: FAIL — `buildSlipEscPos` is undefined.

- [ ] **Step 3: Write minimal implementation**

Create `packages/ledgerly_data/lib/src/printing/esc_pos_renderer.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:ledgerly_core/ledgerly_core.dart';

import 'print_models.dart';

// Standard ESC/POS control bytes used by essentially every 58/80mm thermal
// printer's command set (Epson's original spec, near-universally cloned).
const List<int> _init = [0x1B, 0x40]; // ESC @
const List<int> _boldOn = [0x1B, 0x45, 0x01]; // ESC E 1
const List<int> _boldOff = [0x1B, 0x45, 0x00]; // ESC E 0
const List<int> _centerOn = [0x1B, 0x61, 0x01]; // ESC a 1
const List<int> _leftAlign = [0x1B, 0x61, 0x00]; // ESC a 0
const List<int> _fullCut = [0x1D, 0x56, 0x00, 0x00]; // GS V 0 0

List<int> _line(String text) => [...utf8.encode(text), 0x0A];

/// The Bluetooth-thermal-printer equivalent of [buildSlipPdf]: same
/// [SlipModel] input, raw ESC/POS bytes instead of a PDF page. Synchronous
/// -- unlike the PDF path, there is no underlying async rendering library
/// involved in building a plain byte stream.
Uint8List buildSlipEscPos(SlipModel s) {
  final bytes = <int>[..._init, ..._centerOn, ..._boldOn];
  bytes.addAll(_line(s.firmName));
  bytes.addAll([..._boldOff, ..._leftAlign]);
  bytes.addAll(_line(s.firmContact));
  if (s.firmAddress case final address?) bytes.addAll(_line(address));
  bytes.addAll(_line('Slip ${s.displayNo}  ${s.entryDate}'));
  bytes.addAll(_line(s.customerName ?? 'Cash Sale'));
  bytes.addAll(_line('-' * 32));
  for (final line in s.lines) {
    bytes.addAll(_line(line.itemName));
    bytes.addAll(
      _line('${line.quantityDescription}  ${line.rateDescription}  ${formatMoney(line.amount)}'),
    );
  }
  bytes.addAll(_line('-' * 32));
  bytes.addAll([..._boldOn]);
  bytes.addAll(_line('Total: ${formatMoney(s.total)}'));
  bytes.addAll([..._boldOff]);
  if (s.previousBalance != null && s.newBalance != null) {
    bytes.addAll(_line('Previous balance: ${formatMoney(s.previousBalance!)}'));
    bytes.addAll(_line('New balance: ${formatMoney(s.newBalance!)}'));
  }
  if (s.edited) bytes.addAll(_line('(edited)'));
  bytes.addAll(_line('Device ${s.deviceCode}'));
  bytes.addAll([0x0A, 0x0A]);
  bytes.addAll(_fullCut);
  return Uint8List.fromList(bytes);
}
```

Add the export to `packages/ledgerly_data/lib/ledgerly_data.dart` — open it first, find the existing `export 'src/printing/slip_pdf.dart';` line (or equivalent), and add directly beneath it:

```dart
export 'src/printing/esc_pos_renderer.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/ledgerly_data && dart test test/printing/esc_pos_renderer_test.dart`
Expected: PASS. Then `dart test` (whole package) to confirm nothing else broke.

- [ ] **Step 5: Commit**

```bash
git add packages/ledgerly_data/lib/src/printing/esc_pos_renderer.dart packages/ledgerly_data/lib/ledgerly_data.dart packages/ledgerly_data/test/printing/esc_pos_renderer_test.dart
git commit -m "Printing: pure-Dart ESC/POS slip renderer, sharing SlipModel with the PDF path"
```

---

## Task 6: ThermalPrinterService seam + Settings UI + printSlip Bluetooth branch

**Files:**
- Modify: `app/pubspec.yaml` — add `print_bluetooth_thermal: ^1.2.4`.
- Create: `app/lib/printing/thermal_printer_service.dart`
- Modify: `app/lib/bootstrap/global_prefs.dart` — add `thermalPrinterMac`/`thermalPrinterName` fields + `setThermalPrinter`, mirroring the existing `printerName`/`printerUrl`/`setPrinter` pattern exactly, in all three places (`GlobalPrefs`, `SharedPrefsGlobalPrefs`, `InMemoryGlobalPrefs`).
- Modify: `app/lib/printing/print_actions.dart` — modify the body of the existing `printSlip` function to try Bluetooth first when a printer is saved, falling back to the existing PDF path unchanged (no new function, no call-site changes needed in `bill_screen.dart`/`ledger_screen.dart`).
- Modify: `app/test/support/pump_app.dart` — add `FakeThermalPrinterService`, matching `FakePrintingService`'s pattern, and override its provider.
- Modify: `app/lib/features/settings/settings_screen.dart` — add a Bluetooth-printer picker section, mirroring the existing `_choosePrinter`/"Default printer" section exactly (both read below).
- Test: `app/test/features/print_bill_test.dart` and `app/test/features/settings_test.dart` (existing files — add new tests to each).

**Interfaces:**
- Consumes: `buildSlipEscPos` (Task 5), `GlobalPrefs` (existing), the existing `printSlip(WidgetRef, OpenFirm, String)` in `print_actions.dart` (already called from `bill_screen.dart:173` and `ledger_screen.dart:175` — this task modifies its body, not its signature or call sites, so both existing call sites get Bluetooth support for free).
- Produces: `abstract class ThermalPrinterService { Future<List<BluetoothPrinterInfo>> pairedPrinters(); Future<bool> connect(String mac); Future<bool> writeBytes(Uint8List bytes); Future<void> disconnect(); }`, `class BluetoothPrinterInfo { final String name; final String mac; }`, `final thermalPrinterServiceProvider = Provider<ThermalPrinterService>(...)`.

- [ ] **Step 1: Write the failing tests**

Add to the existing `app/test/features/print_bill_test.dart` (reusing its `seedMill` helper and the exact `Ctrl+P` trigger its first test already uses — `CallbackShortcuts` stays wired in at every width per Task 2, so the same key-event trigger works unchanged under `phoneOnly`):

```dart
  testWidgets(
    'on Android with a saved Bluetooth printer, Ctrl+P prints via Bluetooth instead of the OS dialog',
    (tester) async {
      final container = await pumpLedgerly(
        tester,
        seed: seedMill,
        viewSize: const Size(390, 844),
      );
      await container
          .read(globalPrefsProvider)
          .setThermalPrinter(name: 'MPT-II', mac: '00:11:22:33:44:55');
      await pressCtrl(tester, LogicalKeyboardKey.keyI);
      await tester.enterText(find.byKey(const Key('bill.customer')), 'Rashid');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter, platform: 'windows');
      await tester.enterText(find.byKey(const Key('cash.amount')), '1000');
      await pressCtrl(tester, LogicalKeyboardKey.enter);

      await pressCtrl(tester, LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();

      final thermal =
          container.read(thermalPrinterServiceProvider) as FakeThermalPrinterService;
      expect(thermal.connectedMac, '00:11:22:33:44:55');
      expect(thermal.written, hasLength(1));
      expect(thermal.disconnected, isTrue);
      final printing =
          container.read(printingServiceProvider) as FakePrintingService;
      expect(printing.printedJobs, isEmpty); // did not fall through to the PDF path
    },
    variant: phoneOnly,
  );

  testWidgets(
    'a failed Bluetooth connect falls back to the normal PDF print path',
    (tester) async {
      final container = await pumpLedgerly(
        tester,
        seed: seedMill,
        viewSize: const Size(390, 844),
      );
      await container
          .read(globalPrefsProvider)
          .setThermalPrinter(name: 'MPT-II', mac: '00:11:22:33:44:55');
      final thermal =
          container.read(thermalPrinterServiceProvider) as FakeThermalPrinterService;
      thermal.connectSucceeds = false;
      await pressCtrl(tester, LogicalKeyboardKey.keyI);
      await tester.enterText(find.byKey(const Key('bill.customer')), 'Rashid');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter, platform: 'windows');
      await tester.enterText(find.byKey(const Key('cash.amount')), '1000');
      await pressCtrl(tester, LogicalKeyboardKey.enter);

      await pressCtrl(tester, LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();

      expect(thermal.written, isEmpty);
      final printing =
          container.read(printingServiceProvider) as FakePrintingService;
      expect(printing.printedJobs.length, 1); // fell through correctly
    },
    variant: phoneOnly,
  );
```

Add to `app/pubspec.yaml`'s `dependencies:` section (alongside the existing `printing: ^5.15.0` line):

```yaml
  print_bluetooth_thermal: ^1.2.4
```

Run `flutter pub get` in `app/` now (not a test step, but required before anything below compiles).

Add to `app/test/features/settings_test.dart` (match its existing `seed`; this file does not yet import the thermal printer service, so add `import 'package:ledgerly/printing/thermal_printer_service.dart';` to its existing import block for `BluetoothPrinterInfo`):

```dart
  testWidgets('picking a paired Bluetooth printer saves it and shows it as selected', (
    tester,
  ) async {
    final container = await pumpLedgerly(tester, seed: seed);
    final fakeThermal =
        container.read(thermalPrinterServiceProvider) as FakeThermalPrinterService;
    fakeThermal.paired = [const BluetoothPrinterInfo(name: 'MPT-II', mac: '00:11:22:33:44:55')];
    await pressCtrl(tester, LogicalKeyboardKey.comma);

    await tester.tap(find.byKey(const Key('settings.thermalPrinterPicker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MPT-II'));
    await tester.pumpAndSettle();

    expect(find.textContaining('MPT-II'), findsWidgets);
  }, variant: windowsOnly);
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd app && flutter test test/features/print_bill_test.dart test/features/settings_test.dart`
Expected: FAIL — `thermalPrinterServiceProvider`, `FakeThermalPrinterService`, `BluetoothPrinterInfo`, `globalPrefsProvider.setThermalPrinter`, and `Key('settings.thermalPrinterPicker')` don't exist yet (compile errors); once those are stubbed in, the two `print_bill_test.dart` cases still fail because `printSlip` doesn't try Bluetooth yet.

- [ ] **Step 3: Write minimal implementation**

Create `app/lib/printing/thermal_printer_service.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class BluetoothPrinterInfo {
  const BluetoothPrinterInfo({required this.name, required this.mac});
  final String name;
  final String mac;
}

/// The Bluetooth-transport equivalent of [PrintingService]: sends already-
/// rendered bytes ([buildSlipEscPos]'s output) to a paired thermal printer.
/// Real Bluetooth I/O cannot run inside an automated test, exactly like the
/// OS printer dialog it sits alongside -- see [FakeThermalPrinterService].
abstract class ThermalPrinterService {
  Future<List<BluetoothPrinterInfo>> pairedPrinters();
  Future<bool> connect(String mac);
  Future<bool> writeBytes(Uint8List bytes);
  Future<void> disconnect();
}

class RealThermalPrinterService implements ThermalPrinterService {
  @override
  Future<List<BluetoothPrinterInfo>> pairedPrinters() async {
    final paired = await PrintBluetoothThermal.pairedBluetooths;
    return [
      for (final p in paired) BluetoothPrinterInfo(name: p.name, mac: p.macAdress),
    ];
  }

  @override
  Future<bool> connect(String mac) => PrintBluetoothThermal.connect(macPrinterAddress: mac);

  @override
  Future<bool> writeBytes(Uint8List bytes) => PrintBluetoothThermal.writeBytes(bytes);

  @override
  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
  }
}
```

(Verified against the package's actual source, not just its README table: `BluetoothInfo` has fields `name` and `macAdress` — note the real, slightly-misspelled field name, not "macAddress"; `connect` takes a named `macPrinterAddress` param; `writeBytes` takes a positional `List<int>` — a `Uint8List` argument is accepted directly since `Uint8List implements List<int>`; `disconnect` is a **getter** returning `Future<bool>`, hence the `async`/`await`-and-discard wrapper above rather than a direct arrow return, which would be a `Future<bool>`-into-`Future<void>` type mismatch.)

Add to `app/lib/bootstrap/global_prefs.dart`. In `abstract class GlobalPrefs`, next to `printerName`/`printerUrl`:

```dart
  /// The saved Bluetooth thermal printer, same reasoning as [printerName]/
  /// [printerUrl]: name for display, mac for reconnecting.
  String? get thermalPrinterName;
  String? get thermalPrinterMac;
```

and next to `setPrinter`:

```dart
  Future<void> setThermalPrinter({String? name, String? mac});
```

In `SharedPrefsGlobalPrefs`, next to the existing `printerName`/`printerUrl` getters:

```dart
  @override
  String? get thermalPrinterName => _prefs.getString('thermal_printer_name');
  @override
  String? get thermalPrinterMac => _prefs.getString('thermal_printer_mac');
```

and next to `setPrinter`:

```dart
  @override
  Future<void> setThermalPrinter({String? name, String? mac}) async {
    if (name == null) {
      await _prefs.remove('thermal_printer_name');
    } else {
      await _prefs.setString('thermal_printer_name', name);
    }
    if (mac == null) {
      await _prefs.remove('thermal_printer_mac');
    } else {
      await _prefs.setString('thermal_printer_mac', mac);
    }
  }
```

In `InMemoryGlobalPrefs`, next to `printerName`/`printerUrl`:

```dart
  @override
  String? thermalPrinterName;
  @override
  String? thermalPrinterMac;
```

and next to `setPrinter`:

```dart
  @override
  Future<void> setThermalPrinter({String? name, String? mac}) async {
    thermalPrinterName = name;
    thermalPrinterMac = mac;
  }
```

In `app/lib/printing/print_actions.dart`, add the new provider near the top (next to `printingServiceProvider`):

```dart
final thermalPrinterServiceProvider = Provider<ThermalPrinterService>(
  (ref) => RealThermalPrinterService(),
);
```

Then modify the **existing** `printSlip` function itself — this is the one and only place a Bluetooth attempt is inserted, so both of its existing call sites (`bill_screen.dart:173`, `ledger_screen.dart:175`) get it automatically with no changes on their end:

```dart
/// Builds the slip, sends it to the printer, and logs the print — the one
/// path every "print this bill" action goes through, whether triggered from
/// the bill form's Saved state or later from the ledger. A saved Bluetooth
/// printer is tried first; a missing printer, or a failed connect/write (off,
/// out of range, unpaired), falls through to the OS print path below instead
/// of failing silently — the same "ask" degradation the app already uses
/// everywhere else nothing is configured.
Future<void> printSlip(WidgetRef ref, OpenFirm firm, String billId) async {
  final mac = ref.read(globalPrefsProvider).thermalPrinterMac;
  if (mac != null) {
    final service = ref.read(thermalPrinterServiceProvider);
    if (await service.connect(mac)) {
      final slip = await firm.bills.slipFor(billId, printedAt: firm.ctx.stamp());
      final wrote = await service.writeBytes(buildSlipEscPos(slip));
      await service.disconnect();
      if (wrote) {
        await firm.bills.logPrint(
          kind: 'slip',
          transactionId: billId,
          printedAt: slip.printedAt,
          printedBalanceAfter: slip.newBalance,
        );
        return;
      }
    }
  }
  final slip = await firm.bills.slipFor(billId, printedAt: firm.ctx.stamp());
  final bytes = await buildSlipPdf(slip);
  await ref
      .read(printingServiceProvider)
      .print(bytes, jobName: 'Slip ${slip.displayNo}');
  await firm.bills.logPrint(
    kind: 'slip',
    transactionId: billId,
    printedAt: slip.printedAt,
    printedBalanceAfter: slip.newBalance,
  );
}
```

(This replaces the existing `printSlip` body wholesale — the tail half, from `final slip = await firm.bills.slipFor(...)` to the end, is byte-for-byte the function's original, unmodified body; only the new Bluetooth-first block above it is new. Add `import 'thermal_printer_service.dart';` to `print_actions.dart`.)

In `app/test/support/pump_app.dart`, add next to `FakePrinterDiscovery`:

```dart
/// Records connect/write/disconnect calls instead of touching real
/// Bluetooth hardware, which cannot run in an automated test either.
class FakeThermalPrinterService implements ThermalPrinterService {
  List<BluetoothPrinterInfo> paired = const [];
  String? connectedMac;
  final List<Uint8List> written = [];
  bool disconnected = false;

  /// Set to false to simulate a printer that's off/out of range/unpaired.
  bool connectSucceeds = true;

  @override
  Future<List<BluetoothPrinterInfo>> pairedPrinters() async => paired;

  @override
  Future<bool> connect(String mac) async {
    connectedMac = mac;
    return connectSucceeds;
  }

  @override
  Future<bool> writeBytes(Uint8List bytes) async {
    written.add(bytes);
    return true;
  }

  @override
  Future<void> disconnect() async => disconnected = true;
}
```

Add `import 'package:ledgerly/printing/thermal_printer_service.dart';` to `pump_app.dart`, add `final fakeThermal = FakeThermalPrinterService();` next to `final fakePrinterDiscovery = FakePrinterDiscovery();`, and add `thermalPrinterServiceProvider.overrideWithValue(fakeThermal),` to the `overrides:` list.

In `app/lib/features/settings/settings_screen.dart`, add a method next to the existing `_choosePrinter` (around line 93 — mirrors it exactly, swapping the OS printer-discovery list for the Bluetooth-paired list):

```dart
  Future<void> _chooseThermalPrinter() async {
    final printers = await ref.read(thermalPrinterServiceProvider).pairedPrinters();
    if (!mounted) return;
    final picked = await showDialog<BluetoothPrinterInfo>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        key: const Key('settings.thermalPrinterDialog'),
        title: const Text('Choose a Bluetooth printer'),
        children: [
          for (final p in printers)
            SimpleDialogOption(
              key: Key('settings.thermalPrinterOption.${p.name}'),
              onPressed: () => Navigator.of(dialogContext).pop(p),
              child: Text(p.name),
            ),
        ],
      ),
    );
    if (picked == null) return;
    await ref
        .read(globalPrefsProvider)
        .setThermalPrinter(name: picked.name, mac: picked.mac);
    setState(() {});
  }
```

Add `import 'package:ledgerly/printing/thermal_printer_service.dart';` to this file's imports if not already present via `print_actions.dart`'s exports.

Then add a new section next to the existing `_section(context, 'Printer', [...])` block (around line 305), reading the current value from `ref.watch(globalPrefsProvider)` the same way `printer` is watched at the top of `build()`:

```dart
            _section(context, 'Bluetooth printer', [
              _field(
                'Thermal printer',
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ref.watch(globalPrefsProvider).thermalPrinterName ??
                            'None selected',
                        style: TextStyle(color: c.ink2),
                      ),
                    ),
                    const SizedBox(width: 14),
                    OutlinedButton(
                      key: const Key('settings.thermalPrinterPicker'),
                      onPressed: _chooseThermalPrinter,
                      child: const Text('Choose printer…'),
                    ),
                  ],
                ),
              ),
            ]),
```

(`c` and `_field`/`_section` are this file's existing helpers, already in scope inside `build()` — this new block is a sibling of the existing `_section(context, 'Printer', [...])` call, added directly after it.)

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd app && flutter test test/features/print_bill_test.dart test/features/settings_test.dart`
Expected: all PASS. Run the full suite (`flutter test`) to confirm nothing else broke — in particular the existing `windowsOnly` print tests in `print_bill_test.dart` and `print_ledger_test.dart` must still pass unchanged (desktop has no `thermalPrinterMac` saved, so `printSlip` falls straight through to the same PDF path it always used).

- [ ] **Step 5: Commit**

```bash
git add app/pubspec.yaml app/pubspec.lock app/lib/printing/thermal_printer_service.dart app/lib/bootstrap/global_prefs.dart app/lib/printing/print_actions.dart app/test/support/pump_app.dart app/lib/features/settings/settings_screen.dart app/test/features/print_bill_test.dart app/test/features/settings_test.dart
git commit -m "Printing: Bluetooth ThermalPrinterService, tried first by printSlip, falling back to the PDF path unchanged (untested against real hardware -- see spec)"
```

---

## Task 7: Android Downloads-folder export

**Files:**
- Modify: `app/pubspec.yaml` — add `flutter_file_downloader: ^2.1.1`.
- Modify: `app/lib/printing/printing_service.dart` — branch `RealPrintingService.exportPdf`/`exportPng` by platform.
- Test: no widget test needed (this is real-OS-only behavior, exactly like the existing `RealPrintingService` has no direct test today — only `FakePrintingService` is exercised in widget tests, per `pump_app.dart`). Verification for this task is manual, on Task 8's real device.

**Interfaces:**
- Consumes: `PrintingService.exportPdf`/`exportPng` (existing abstract signatures, unchanged).
- Produces: no new public API — same two existing methods, Android now takes a different internal code path.

- [ ] **Step 1: Add the dependency**

Add to `app/pubspec.yaml`'s `dependencies:`:

```yaml
  flutter_file_downloader: ^2.1.1
```

Run `flutter pub get` in `app/`.

There is no automated red/green cycle for this task -- `RealPrintingService` is never exercised by the widget-test suite (it's always swapped for `FakePrintingService`, per `pump_app.dart`), and real file-system/download-manager behavior can only be verified against Android itself. Follow the same TDD spirit by writing the implementation to the exact contract already defined by the existing `PrintingService` interface's docstring-equivalent comments, and defer verification to Task 8's manual device check.

- [ ] **Step 2: Write the implementation**

In `app/lib/printing/printing_service.dart`, add near the top:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_file_downloader/flutter_file_downloader.dart';
```

Change `RealPrintingService.exportPdf` and `exportPng` to branch on `Platform.isAndroid`:

```dart
  @override
  Future<bool> exportPdf(Uint8List pdfBytes, {required String suggestedName}) async {
    if (Platform.isAndroid) {
      final file = await FileDownloader.downloadFile(
        url: 'data:application/pdf;base64,${base64Encode(pdfBytes)}',
        name: suggestedName,
      );
      return file != null;
    }
    return Printing.sharePdf(bytes: pdfBytes, filename: suggestedName);
  }
```

```dart
  @override
  Future<int> exportPng(
    Uint8List pdfBytes, {
    required String suggestedBaseName,
  }) async {
    final pages = await Printing.raster(pdfBytes, dpi: 300).toList();
    var written = 0;
    for (var i = 0; i < pages.length; i++) {
      final png = await pages[i].toPng();
      final suggested = pages.length == 1
          ? '$suggestedBaseName.png'
          : '$suggestedBaseName-${i + 1}.png';
      if (Platform.isAndroid) {
        final file = await FileDownloader.downloadFile(
          url: 'data:image/png;base64,${base64Encode(png)}',
          name: suggested,
        );
        if (file == null) break;
        written++;
        continue;
      }
      final location = await getSaveLocation(
        suggestedName: suggested,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'PNG image', extensions: ['png']),
        ],
      );
      if (location == null) break;
      await File(location.path).writeAsBytes(png);
      written++;
    }
    return written;
  }
```

- [ ] **Step 3: Run the full test suite to confirm nothing else broke**

Run: `cd app && flutter test`
Expected: PASS -- this task touches only `RealPrintingService`, which no widget test exercises directly, so the whole suite should be green with zero behavior change on desktop (the `Platform.isAndroid` branch is simply never taken there).

- [ ] **Step 4: Commit**

```bash
git add app/pubspec.yaml app/pubspec.lock app/lib/printing/printing_service.dart
git commit -m "Printing: export to the public Downloads folder on Android instead of file_selector's save dialog"
```

---

## Task 8: Real Android build and manual smoke verification

**Files:** none (verification task, no code changes).

**Interfaces:** none.

This task has no automated test -- it's the point where the plan's assumptions about the Android toolchain itself (never built against before this phase, per the spec) get checked against reality, and where Task 6's Bluetooth path gets flagged for its known, accepted gap.

- [ ] **Step 1: First real build**

```bash
cd app && flutter build apk --debug
```

Expected: succeeds. If it fails, the error is almost certainly in Gradle/AGP/NDK version alignment (the `android/` scaffold has never been built against, per the spec) rather than in this plan's own code -- fix the Android project files as needed and re-run before continuing.

- [ ] **Step 2: Run on an emulator or real device**

```bash
flutter emulators --launch <any-available-emulator-id>   # or connect a real device
flutter run
```

Manually verify, at phone width:
- Dashboard shows the bottom nav (Task 2) and a "+ " FAB.
- Tapping "+ " opens the bill form as touch cards (Task 3), not the desktop grid.
- Opening a customer's ledger and tapping a row pushes a full-screen detail view with a back button (Task 4).
- Settings shows the Bluetooth-printer section (Task 6) -- picking a printer will show none paired unless a real printer is already paired to the test device; that's expected and fine.
- From a saved bill, tapping Export PDF succeeds and the file appears in the device's Downloads app (Task 7).

- [ ] **Step 3: Record the known gap**

Update `app/README.md` (or wherever this repo tracks "not built yet" -- check `backend/README.md`'s "Not built yet" section for the house style and match it) with one line: *Bluetooth thermal printing (`ThermalPrinterService`) is implemented and unit-tested but not yet verified against a real printer -- do this once a Bluetooth 80mm thermal printer is available, per the design spec's accepted gap.*

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "Android: first real build verified on device/emulator; Bluetooth printing still needs real-hardware testing"
```
