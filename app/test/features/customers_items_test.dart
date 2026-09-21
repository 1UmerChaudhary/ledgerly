import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/bootstrap/router.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../support/pump_app.dart';

Future<void> seed(AppDatabase db, DeviceContext ctx) async {
  await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
  final customers = CustomersRepository(db, ctx);
  await customers.create(name: 'Rashid Traders', phone: '0300-9876543');
  await customers.create(name: 'Muhammad Ali Traders');
  await ItemsRepository(db, ctx).create(
    name: 'Oil',
    defaultBagWeight: Weight.kg(16),
    defaultRateBase: RateBase.maund,
  );
}

/// A customer whose name is long enough to force a fixed-width row to wrap
/// or overflow if it isn't handled -- used by the phone-width regression
/// tests below (Bugs B/C/F).
const _longName = 'Muhammad Abdul Rahman Extremely Long Trading Company Name';

Future<void> seedWithLongName(AppDatabase db, DeviceContext ctx) async {
  await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
  final customer = await CustomersRepository(db, ctx).create(name: _longName);
  await BillsRepository(db, ctx).saveNew(
    Bill(
      id: newId(),
      customerId: customer.id,
      type: TransactionType.openingBalance,
      entryDate: '2026-09-01',
      typedAmount: Money.rupees(10000),
    ),
  );
  await ItemsRepository(db, ctx).create(name: 'Wheat');
}

Future<void> type(WidgetTester tester, Key key, String text) async {
  await tester.tap(find.byKey(key));
  await tester.pump();
  await tester.enterText(find.byKey(key), text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'C opens Customers; the list shows names and phones; Ctrl+N opens the create form',
    (tester) async {
      await pumpLedgerly(tester, seed: seed);
      await tester.sendKeyEvent(
        LogicalKeyboardKey.escape,
        platform: 'windows',
      ); // leave the search box
      await tester.tap(find.text('Customers'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('customers.screen')), findsOneWidget);
      expect(find.text('Rashid Traders'), findsOneWidget);
      expect(find.text('0300-9876543'), findsOneWidget);
      await pressCtrl(tester, LogicalKeyboardKey.keyN);
      expect(find.byKey(const Key('customer.form')), findsOneWidget);
    },
    variant: windowsOnly,
  );

  testWidgets('a duplicate phone is blocked and names the existing customer', (
    tester,
  ) async {
    await pumpLedgerly(tester, seed: seed);
    await tester.tap(find.text('Customers'));
    await tester.pumpAndSettle();
    await pressCtrl(tester, LogicalKeyboardKey.keyN);
    await type(tester, const Key('customer.name'), 'Rashid Trader');
    await type(tester, const Key('customer.phone'), '+92 300 9876543');
    await pressCtrl(tester, LogicalKeyboardKey.enter);
    expect(find.textContaining('belongs to Rashid Traders'), findsOneWidget);
    expect(
      find.byKey(const Key('customer.form')),
      findsOneWidget,
    ); // still on the form
  }, variant: windowsOnly);

  testWidgets(
    'a similar name shows a warning but saves on Ctrl+Enter; the list then has three',
    (tester) async {
      await pumpLedgerly(tester, seed: seed);
      await tester.tap(find.text('Customers'));
      await tester.pumpAndSettle();
      await pressCtrl(tester, LogicalKeyboardKey.keyN);
      await type(tester, const Key('customer.name'), 'Mohammad Ali Trader');
      expect(
        find.textContaining('Similar: Muhammad Ali Traders'),
        findsOneWidget,
      );
      await pressCtrl(tester, LogicalKeyboardKey.enter);
      expect(find.byKey(const Key('customer.form')), findsNothing);
      expect(find.text('Mohammad Ali Trader'), findsOneWidget);
      expect(find.byKey(const Key('customers.row')), findsNWidgets(3));
    },
    variant: windowsOnly,
  );

  testWidgets(
    'Items: I opens the list with defaults; Ctrl+N creates one with bag weight and base',
    (tester) async {
      await pumpLedgerly(tester, seed: seed);
      await tester.tap(find.text('Items'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('items.screen')), findsOneWidget);
      expect(find.text('Oil'), findsOneWidget);
      expect(find.text('16.000'), findsOneWidget);
      expect(find.text('37.324'), findsOneWidget);
      await pressCtrl(tester, LogicalKeyboardKey.keyN);
      await type(tester, const Key('item.name'), 'Oilcake');
      await type(tester, const Key('item.bagKg'), '50');
      await type(tester, const Key('item.base'), '40');
      await pressCtrl(tester, LogicalKeyboardKey.enter);
      expect(find.byKey(const Key('item.form')), findsNothing);
      expect(find.text('Oilcake'), findsOneWidget);
      expect(find.text('50.000'), findsOneWidget);
    },
    variant: windowsOnly,
  );

  testWidgets(
    'at phone width, the customers header renders without overflow and '
    '"Import opening balances" stays reachable',
    (tester) async {
      final container = await pumpLedgerly(
        tester,
        seed: seed,
        viewSize: const Size(390, 844),
      );
      container.read(routerProvider).go('/customers');
      await tester.pumpAndSettle();

      // Root cause: the title + "Import opening balances" button + summary
      // text all sat in one fixed Row, which is wider than a phone
      // viewport.
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Import opening balances'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('openingBalances.screen')), findsOneWidget);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'at phone width, a long customer name is ellipsized in the customers '
    'list instead of wrapping character-by-character',
    (tester) async {
      final container = await pumpLedgerly(
        tester,
        seed: seedWithLongName,
        viewSize: const Size(390, 844),
      );
      container.read(routerProvider).go('/customers');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Before the fix this Text had no overflow/maxLines handling, so a
      // ~316px-wide Expanded slice squeezed to a few pixels wrapped the
      // name into dozens of one/two-character lines (measured ~950px
      // tall in the unfixed code). A single ellipsized line is well under
      // 30px.
      final nameFinder = find.text(_longName);
      expect(nameFinder, findsOneWidget);
      expect(tester.getSize(nameFinder).height, lessThan(30));
    },
    variant: phoneOnly,
  );

  testWidgets(
    'at phone width, the items list header shows "NAME" on one line, not '
    'wrapped mid-word',
    (tester) async {
      final container = await pumpLedgerly(
        tester,
        seed: seed,
        viewSize: const Size(390, 844),
      );
      container.read(routerProvider).go('/items');
      await tester.pumpAndSettle();

      // Root cause: the NAME column was an Expanded sharing a Row with
      // three fixed 120/120/80px columns that alone exceed a phone
      // viewport's width, squeezing NAME's share to nothing and forcing
      // the 4-letter label to break mid-word ("NA"/"ME") across two lines.
      expect(tester.takeException(), isNull);
      final header = find.text('NAME');
      expect(header, findsOneWidget);
      expect(tester.getSize(header).height, lessThan(20));
    },
    variant: phoneOnly,
  );

  testWidgets(
    'at phone width, tapping the on-screen Save button creates a customer '
    '(no keyboard involved)',
    (tester) async {
      final container = await pumpLedgerly(
        tester,
        seed: seed,
        viewSize: const Size(390, 844),
      );
      container.read(routerProvider).go('/customers');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shell.fab.addCustomer')));
      await tester.pumpAndSettle();

      await type(tester, const Key('customer.name'), 'Touch Only Customer');

      // Root cause of the real bug this guards against: this form has no
      // on-screen Save at all below kCompactBreakpoint, only a
      // Ctrl+Enter/numpad-Enter CallbackShortcuts binding, which a
      // touch-only device can never send.
      expect(find.byKey(const Key('customer.compactSave')), findsOneWidget);
      await tester.tap(find.byKey(const Key('customer.compactSave')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('customer.form')), findsNothing);
      expect(find.text('Touch Only Customer'), findsOneWidget);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'at phone width, tapping the on-screen Save button creates an item '
    '(no keyboard involved)',
    (tester) async {
      final container = await pumpLedgerly(
        tester,
        seed: seed,
        viewSize: const Size(390, 844),
      );
      container.read(routerProvider).go('/items');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shell.fab.addItem')));
      await tester.pumpAndSettle();

      await type(tester, const Key('item.name'), 'Touch Only Item');

      // Same root cause as the customer form above: no on-screen Save
      // below kCompactBreakpoint, only Ctrl+Enter/numpad-Enter.
      expect(find.byKey(const Key('item.compactSave')), findsOneWidget);
      await tester.tap(find.byKey(const Key('item.compactSave')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('item.form')), findsNothing);
      expect(find.text('Touch Only Item'), findsOneWidget);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'at phone width, the system back gesture from the new-customer form '
    'returns to the customers list, not the dashboard',
    (tester) async {
      final container = await pumpLedgerly(
        tester,
        seed: seed,
        viewSize: const Size(390, 844),
      );
      container.read(routerProvider).go('/customers');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shell.fab.addCustomer')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('customer.form')), findsOneWidget);

      await systemBack(tester);

      expect(find.byKey(const Key('customer.form')), findsNothing);
      expect(find.byKey(const Key('customers.screen')), findsOneWidget);
      expect(find.byKey(const Key('dashboard.search')), findsNothing);
      // The shell chrome has to follow the pop too: a ShellRouteMatch's
      // matchedLocation is frozen at match time, so reading it left the
      // back arrow up and the bottom nav missing on a top-level tab.
      expect(find.byKey(const Key('shell.bottomNav')), findsOneWidget);
      expect(find.byKey(const Key('shell.backButton')), findsNothing);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'at phone width, the system back gesture from the new-item form returns '
    'to the items list, not the dashboard',
    (tester) async {
      final container = await pumpLedgerly(
        tester,
        seed: seed,
        viewSize: const Size(390, 844),
      );
      container.read(routerProvider).go('/items');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shell.fab.addItem')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('item.form')), findsOneWidget);

      await systemBack(tester);

      expect(find.byKey(const Key('item.form')), findsNothing);
      expect(find.byKey(const Key('items.screen')), findsOneWidget);
      expect(find.byKey(const Key('dashboard.search')), findsNothing);
      expect(find.byKey(const Key('shell.bottomNav')), findsOneWidget);
      expect(find.byKey(const Key('shell.backButton')), findsNothing);
    },
    variant: phoneOnly,
  );
}
