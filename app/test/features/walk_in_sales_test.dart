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
  await CustomersRepository(
    db,
    ctx,
  ).create(name: 'Rashid Traders', phone: '0300-9876543');
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
    'checking Walk-in hides the customer field and lets a sale save with no customer',
    (tester) async {
      await pumpLedgerly(tester, seed: seedMill);
      await pressCtrl(tester, LogicalKeyboardKey.keyN);
      expect(find.byKey(const Key('bill.customer')), findsOneWidget);

      await tester.tap(find.byKey(const Key('bill.walkIn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bill.customer')), findsNothing);
      expect(find.textContaining('Walk-in'), findsWidgets);

      await typeInto(tester, const Key('bill.line.0.item'), 'Oi');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter, platform: 'windows');
      await typeInto(tester, const Key('bill.line.0.bags'), '20');
      await typeInto(tester, const Key('bill.line.0.rate'), '9000');
      await pressCtrl(tester, LogicalKeyboardKey.enter);

      expect(find.byKey(const Key('bill.saved')), findsOneWidget);
      expect(find.textContaining('Cash sale'), findsWidgets);
    },
    variant: windowsOnly,
  );

  testWidgets(
    'unchecking Walk-in brings the customer field back and clears the error',
    (tester) async {
      await pumpLedgerly(tester, seed: seedMill);
      await pressCtrl(tester, LogicalKeyboardKey.keyN);
      await pressCtrl(
        tester,
        LogicalKeyboardKey.enter,
      ); // no customer, not walk-in → error
      expect(find.textContaining('Pick a customer'), findsWidgets);

      await tester.tap(find.byKey(const Key('bill.walkIn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bill.walkIn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bill.customer')), findsOneWidget);
    },
    variant: windowsOnly,
  );
}

Future<void> typeInto(WidgetTester tester, Key key, String text) async {
  await tester.tap(find.byKey(key));
  await tester.pump();
  await tester.enterText(find.byKey(key), text);
  await tester.pumpAndSettle();
}
