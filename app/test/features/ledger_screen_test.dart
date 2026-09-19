import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../support/pump_app.dart';

late String rashidId;
late String editedBillId;

Future<void> seedLedger(AppDatabase db, DeviceContext ctx) async {
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
  rashidId = rashid.id;
  final oil = await items.create(
    name: 'Oil',
    defaultBagWeight: Weight.kg(16),
    defaultRateBase: RateBase.maund,
  );
  final cake = await items.create(
    name: 'Oilcake',
    defaultBagWeight: Weight.kg(50),
    defaultRateBase: RateBase.forty,
  );

  Future<Bill> cash(TransactionType t, String date, int rupees) =>
      bills.saveNew(
        Bill(
          id: newId(),
          customerId: rashid.id,
          type: t,
          entryDate: date,
          typedAmount: Money.rupees(rupees),
        ),
      );
  await cash(TransactionType.openingBalance, '2026-09-01', 220000);
  final sale = await bills.saveNew(
    Bill(
      id: newId(),
      customerId: rashid.id,
      type: TransactionType.sale,
      entryDate: '2026-09-12',
      description: 'Oil + oilcake',
      lines: [
        BillLine(
          id: newId(),
          lineNo: 1,
          itemId: oil.id,
          saleMode: SaleMode.byBags,
          bagCount: 20,
          bagWeight: Weight.kg(16),
          totalWeight: Weight.kg(320),
          rate: Money.rupees(9000),
          rateBase: RateBase.maund,
        ),
        BillLine(
          id: newId(),
          lineNo: 2,
          itemId: cake.id,
          saleMode: SaleMode.byBags,
          bagCount: 40,
          bagWeight: Weight.kg(50),
          totalWeight: Weight.kg(2000),
          rate: Money.rupees(2000),
          rateBase: RateBase.forty,
        ),
      ],
    ),
  );
  await cash(
    TransactionType.cashIn,
    '2026-09-05',
    100000,
  ); // backdated relative to the sale
  // Edit: oilcake rate 2,000 → 2,400 (v2)
  editedBillId = sale.id;
  await bills.edit(
    sale.copyWith(
      lines: [
        sale.lines.first,
        sale.lines.last.copyWith(rate: Money.rupees(2400)),
      ],
    ),
  );
}

void main() {
  testWidgets(
    'ledger lists entries in date order with running balance, debit/credit columns and an edited badge',
    (tester) async {
      await pumpLedgerly(tester, seed: seedLedger);
      await tester.enterText(
        find.byKey(const Key('dashboard.search')),
        'rashid',
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter, platform: 'windows');
      await tester.pumpAndSettle();

      final ledger = find.byKey(const Key('ledger.table'));
      expect(ledger, findsOneWidget);
      // Order: opening (01/09), cash in (05/09, backdated), sale (12/09).
      final rows = tester
          .widgetList<Text>(
            find.descendant(
              of: ledger,
              matching: find.byKey(const Key('ledger.row.type')),
            ),
          )
          .map((t) => t.data)
          .toList();
      expect(rows, ['Opening balance', 'Cash in', 'Sale']);
      // Running balance after each: 2,20,000 → 1,20,000 → 1,20,000 + 77,162 + 1,20,000 = 3,17,162
      expect(
        find.descendant(of: ledger, matching: find.text('2,20,000')),
        findsWidgets,
      );
      expect(
        find.descendant(of: ledger, matching: find.text('1,20,000')),
        findsWidgets,
      );
      expect(
        find.descendant(of: ledger, matching: find.text('3,17,162')),
        findsOneWidget,
      );
      expect(find.text('edited'), findsOneWidget);
      expect(find.text('Rs 3,17,162'), findsOneWidget); // header balance
    },
    variant: windowsOnly,
  );

  testWidgets(
    'selecting the edited bill shows its lines and a history diff; R restores v1 as v3',
    (tester) async {
      await pumpLedgerly(tester, seed: seedLedger);
      await tester.enterText(
        find.byKey(const Key('dashboard.search')),
        'rashid',
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter, platform: 'windows');
      await tester.pumpAndSettle();

      // Arrow down twice: opening → cash in → sale.
      await tester.sendKeyEvent(
        LogicalKeyboardKey.arrowDown,
        platform: 'windows',
      );
      await tester.sendKeyEvent(
        LogicalKeyboardKey.arrowDown,
        platform: 'windows',
      );
      await tester.pumpAndSettle();
      final detail = find.byKey(const Key('ledger.detail'));
      expect(
        find.descendant(of: detail, matching: find.textContaining('Oilcake')),
        findsWidgets,
      );
      expect(
        find.descendant(of: detail, matching: find.textContaining('v2')),
        findsWidgets,
      );
      // Diff of the edit: rate 2,000 → 2,400
      expect(
        find.descendant(of: detail, matching: find.text('2,000')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: detail, matching: find.text('2,400')),
        findsOneWidget,
      );

      // Select v1 in the history list and restore it.
      await tester.tap(find.byKey(const Key('history.version.1')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR, platform: 'windows');
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: detail, matching: find.textContaining('v3')),
        findsWidgets,
      );
      expect(
        find.text('Rs 2,97,162'),
        findsOneWidget,
      ); // header balance back to the v1 rate
    },
    variant: windowsOnly,
  );

  testWidgets(
    'F2 on a bill opens it for editing; Del soft-deletes after confirmation',
    (tester) async {
      await pumpLedgerly(tester, seed: seedLedger);
      await tester.enterText(
        find.byKey(const Key('dashboard.search')),
        'rashid',
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter, platform: 'windows');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(
        LogicalKeyboardKey.arrowDown,
        platform: 'windows',
      );
      await tester.sendKeyEvent(
        LogicalKeyboardKey.arrowDown,
        platform: 'windows',
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.delete, platform: 'windows');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ledger.deleteDialog')), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(
        find.text('Rs 1,20,000'),
        findsOneWidget,
      ); // sale gone from the balance
      expect(find.byKey(const Key('ledger.row.type')), findsNWidgets(2));
    },
    variant: windowsOnly,
  );
}
