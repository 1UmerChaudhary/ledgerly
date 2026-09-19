import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../support/pump_app.dart';

Future<void> seedWalkIns(AppDatabase db, DeviceContext ctx) async {
  await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
  final oil = await ItemsRepository(
    db,
    ctx,
  ).create(name: 'Oil', defaultRateBase: RateBase.forty);
  final bills = BillsRepository(db, ctx);
  Future<void> walkIn(String date, int rate) => bills.saveNew(
    Bill(
      id: newId(),
      customerId: null,
      type: TransactionType.sale,
      entryDate: date,
      lines: [
        // rateBase equal to the weight sold makes the line total exactly the
        // rate, which keeps the arithmetic in this test obvious.
        BillLine(
          id: newId(),
          lineNo: 1,
          itemId: oil.id,
          saleMode: SaleMode.byWeight,
          totalWeight: Weight.kg(10),
          rate: Money.rupees(rate),
          rateBase: Weight.kg(10),
        ),
      ],
    ),
  );
  await walkIn('2026-09-18', 5000);
  await walkIn('2026-09-18', 3000);
}

void main() {
  testWidgets('S opens Cash Sales; lists walk-ins for today with a total', (
    tester,
  ) async {
    await pumpLedgerly(tester, seed: seedWalkIns);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape, platform: 'windows');
    await tester.tap(find.text('Cash sales'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cashSales.screen')), findsOneWidget);
    expect(find.byKey(const Key('cashSales.row')), findsNWidgets(2));
    expect(find.textContaining('8,000'), findsWidgets); // 5,000 + 3,000 total
  }, variant: windowsOnly);

  testWidgets('a customer sale never appears in Cash Sales', (tester) async {
    await pumpLedgerly(
      tester,
      seed: (db, ctx) async {
        await seedWalkIns(db, ctx);
        final rashid = await CustomersRepository(
          db,
          ctx,
        ).create(name: 'Rashid Traders');
        await BillsRepository(db, ctx).saveNew(
          Bill(
            id: newId(),
            customerId: rashid.id,
            type: TransactionType.openingBalance,
            entryDate: '2026-09-18',
            typedAmount: Money.rupees(100000),
          ),
        );
      },
    );
    await tester.tap(find.text('Cash sales'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cashSales.row')), findsNWidgets(2));
    expect(find.text('Rashid Traders'), findsNothing);
  }, variant: windowsOnly);
}
