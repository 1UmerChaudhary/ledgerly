import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../support/pump_app.dart';

Future<void> seedMill(AppDatabase db, DeviceContext ctx) async {
  await FirmSetup(
    db,
    ctx,
  ).createFirm(name: 'Al-Madina Oil Mills', contactNumber: '0300');
  final customers = CustomersRepository(db, ctx);
  final items = ItemsRepository(db, ctx);
  final bills = BillsRepository(db, ctx);
  final rashid = await customers.create(
    name: 'Rashid Traders',
    phone: '0300-9876543',
  );
  await customers.create(name: 'Rasheed Bros');
  await items.create(
    name: 'Oil',
    defaultBagWeight: Weight.kg(16),
    defaultRateBase: RateBase.maund,
  );
  await items.create(
    name: 'Oilcake',
    defaultBagWeight: Weight.kg(50),
    defaultRateBase: RateBase.forty,
  );
  await bills.saveNew(
    Bill(
      id: newId(),
      customerId: rashid.id,
      type: TransactionType.openingBalance,
      entryDate: '2026-09-01',
      typedAmount: Money.rupees(620000),
    ),
  );
}

Future<void> typeInto(WidgetTester tester, Key key, String text) async {
  await tester.tap(find.byKey(key));
  await tester.pump();
  await tester.enterText(find.byKey(key), text);
  await tester.pumpAndSettle();
}

Future<void> key(WidgetTester tester, LogicalKeyboardKey k) async {
  await tester.sendKeyEvent(k, platform: 'windows');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a two-line sale: pick customer, fill lines by keyboard, see live totals, save, land in Saved state',
    (tester) async {
      await pumpLedgerly(tester, seed: seedMill);
      await pressCtrl(tester, LogicalKeyboardKey.keyN);
      expect(find.byKey(const Key('bill.screen')), findsOneWidget);
      expect(find.text('NEW SALE'), findsOneWidget);

      // Customer autocomplete: Enter picks the highlighted match, never creates.
      await typeInto(tester, const Key('bill.customer'), 'Rash');
      expect(find.text('Rasheed Bros'), findsOneWidget); // in the dropdown
      await key(tester, LogicalKeyboardKey.enter);
      expect(
        find.text('owes Rs 6,20,000'),
        findsWidgets,
      ); // current balance shown

      // Line 1: Oil, 20 bags. Bag weight and base come from the item's defaults.
      await typeInto(tester, const Key('bill.line.0.item'), 'Oi');
      await key(tester, LogicalKeyboardKey.enter);
      await typeInto(tester, const Key('bill.line.0.bags'), '20');
      expect(find.text('16.000'), findsOneWidget); // bag kg prefilled
      expect(find.text('320.000'), findsOneWidget); // total kg computed
      await typeInto(tester, const Key('bill.line.0.rate'), '9000');
      expect(find.text('37.324'), findsOneWidget); // base from item default
      expect(find.text('77,162'), findsWidgets); // line total, whole rupees

      // Enter on the last cell of the last line adds a line.
      await tester.tap(find.byKey(const Key('bill.line.0.rate')));
      await key(tester, LogicalKeyboardKey.enter);
      expect(find.byKey(const Key('bill.line.1.item')), findsOneWidget);

      await typeInto(tester, const Key('bill.line.1.item'), 'cake');
      await key(tester, LogicalKeyboardKey.enter);
      await typeInto(tester, const Key('bill.line.1.bags'), '40');
      await typeInto(tester, const Key('bill.line.1.rate'), '2400');
      expect(find.text('1,20,000'), findsOneWidget);

      // Live bill total and balance preview.
      expect(find.text('Rs 1,97,162'), findsOneWidget);
      expect(find.text('after this bill owes Rs 8,17,162'), findsOneWidget);

      await pressCtrl(tester, LogicalKeyboardKey.enter);
      expect(find.byKey(const Key('bill.saved')), findsOneWidget);
      expect(find.textContaining('Saved'), findsOneWidget);
      expect(
        find.textContaining('-2'),
        findsWidgets,
      ); // bill number <code>-2: the seed's opening balance took -1

      // Esc from the Saved state opens the customer's ledger.
      await key(tester, LogicalKeyboardKey.escape);
      expect(find.byKey(const Key('ledger.screen')), findsOneWidget);
    },
    variant: windowsOnly,
  );

  testWidgets(
    'Ctrl+Enter with no customer or no line shows the problem and saves nothing',
    (tester) async {
      await pumpLedgerly(tester, seed: seedMill);
      await pressCtrl(tester, LogicalKeyboardKey.keyN);
      await pressCtrl(tester, LogicalKeyboardKey.enter);
      expect(find.byKey(const Key('bill.saved')), findsNothing);
      expect(find.textContaining('customer'), findsWidgets);
    },
    variant: windowsOnly,
  );

  testWidgets('a cash receipt: Ctrl+I, customer, amount, Ctrl+Enter', (
    tester,
  ) async {
    await pumpLedgerly(tester, seed: seedMill);
    await pressCtrl(tester, LogicalKeyboardKey.keyI);
    expect(find.text('CASH RECEIVED'), findsOneWidget);
    await typeInto(tester, const Key('bill.customer'), 'Rashid');
    await key(tester, LogicalKeyboardKey.enter);
    await typeInto(tester, const Key('cash.amount'), '1,00,000');
    expect(find.text('after this owes Rs 5,20,000'), findsOneWidget);
    await pressCtrl(tester, LogicalKeyboardKey.enter);
    expect(find.byKey(const Key('bill.saved')), findsOneWidget);
  }, variant: windowsOnly);

  testWidgets(
    'Esc on a dirty form asks before discarding; Esc on a clean form leaves',
    (tester) async {
      await pumpLedgerly(tester, seed: seedMill);
      await pressCtrl(tester, LogicalKeyboardKey.keyN);
      await key(tester, LogicalKeyboardKey.escape);
      expect(find.byKey(const Key('bill.screen')), findsNothing);

      await pressCtrl(tester, LogicalKeyboardKey.keyN);
      await typeInto(tester, const Key('bill.description'), 'Sept supply');
      await key(tester, LogicalKeyboardKey.escape);
      expect(find.byKey(const Key('bill.screen')), findsOneWidget);
      expect(find.byKey(const Key('bill.discardDialog')), findsOneWidget);
    },
    variant: windowsOnly,
  );
}
