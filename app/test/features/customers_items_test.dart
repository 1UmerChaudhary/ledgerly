import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
