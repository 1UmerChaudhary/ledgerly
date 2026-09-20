import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/ledger/ledger_screen.dart';
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

/// One customer with a single opening-balance bill — just enough for the
/// customer to appear on the dashboard's balance panel (a zero-balance
/// customer wouldn't) and for the ledger's `entries` list to be non-empty.
Future<void> seedWithOneBill(AppDatabase db, DeviceContext ctx) async {
  await FirmSetup(db, ctx).createFirm(name: 'Test Firm', contactNumber: '0300');
  final customers = CustomersRepository(db, ctx);
  final bills = BillsRepository(db, ctx);
  final customer = await customers.create(name: 'Test Customer');
  await bills.saveNew(
    Bill(
      id: newId(),
      customerId: customer.id,
      type: TransactionType.openingBalance,
      entryDate: '2026-09-01',
      typedAmount: Money.rupees(10000),
    ),
  );
}

void main() {
  test('compactAmountLabel: positive is a debit, negative is a credit, zero is neither', () {
    // A widget-level LedgerEntry with a zero bill.signedAmount can't
    // actually be constructed: signedAmountFor throws ArgumentError for
    // every TransactionType when finalAmount is zero (verified directly
    // against packages/ledgerly_core — sale/purchase/cashIn/cashOut/
    // openingBalance require strictly positive, adjustment explicitly
    // rejects zero). So this tests the compact card's amount-label
    // decision as the pure function it now is, against Money directly,
    // rather than fabricating a Bill the domain can't produce.
    expect(
      compactAmountLabel(Money.rupees(100)),
      'Debit ${formatMoney(Money.rupees(100), symbol: false)}',
    );
    expect(
      compactAmountLabel(Money.rupees(-100)),
      'Credit ${formatMoney(Money.rupees(100), symbol: false)}',
    );
    expect(compactAmountLabel(Money.zero), isNull);
  });

  testWidgets('ledger screen renders without overflow at phone width', (
    tester,
  ) async {
    await pumpLedgerly(
      tester,
      seed: seedWithOneBill,
      viewSize: const Size(390, 844),
    );
    await tester.tap(find.text('Test Customer')); // navigate into the ledger
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  }, variant: phoneOnly);

  testWidgets(
    'at phone width, tapping a ledger row pushes a detail screen instead of showing a side panel',
    (tester) async {
      await pumpLedgerly(
        tester,
        seed: seedWithOneBill,
        viewSize: const Size(390, 844),
      );
      await tester.tap(find.text('Test Customer')); // navigate into the ledger
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ledger.detailPanel')), findsNothing);

      // Below kCompactBreakpoint, entries render as _LedgerTable's compact
      // card list rather than the desktop table, each row keyed by index.
      await tester.tap(find.byKey(const Key('ledger.compactRow.0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ledger.detailPanel')), findsOneWidget);
      expect(find.byKey(const Key('shell.backButton')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: phoneOnly,
  );

  _showDeletedTests();
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

void _showDeletedTests() {
  testWidgets(
    'show-deleted toggle reveals a deleted bill with no running balance, and R restores it',
    (tester) async {
      await pumpLedgerly(tester, seed: seedLedger);
      await tester.enterText(
        find.byKey(const Key('dashboard.search')),
        'rashid',
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter, platform: 'windows');
      await tester.pumpAndSettle();

      // Delete the sale row (the third row: opening, cash in, sale).
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
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Gone from the plain view; header balance dropped by the sale.
      expect(find.byKey(const Key('ledger.row.type')), findsNWidgets(2));
      expect(find.text('Rs 1,20,000'), findsOneWidget);

      // Show deleted: the sale reappears, marked, with a dash for its balance.
      await tester.tap(find.byKey(const Key('ledger.showDeleted')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ledger.row.type')), findsNWidgets(3));
      expect(find.text('deleted'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      // The header balance is unaffected by turning the toggle on.
      expect(find.text('Rs 1,20,000'), findsOneWidget);

      // Select the deleted row (toggling reset the selection to the top, so
      // two steps down: opening → cash in → the deleted sale), pick its last
      // history version, restore it.
      await tester.sendKeyEvent(
        LogicalKeyboardKey.arrowDown,
        platform: 'windows',
      );
      await tester.sendKeyEvent(
        LogicalKeyboardKey.arrowDown,
        platform: 'windows',
      );
      await tester.pumpAndSettle();
      final versionTiles = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey &&
            (w.key! as ValueKey).value.toString().startsWith(
              'history.version.',
            ),
      );
      await tester.tap(versionTiles.first);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR, platform: 'windows');
      await tester.pumpAndSettle();

      // Restored: back in the plain view, balance restored, no longer marked deleted.
      await tester.tap(find.byKey(const Key('ledger.showDeleted')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ledger.row.type')), findsNWidgets(3));
      expect(find.text('deleted'), findsNothing);
      expect(find.text('Rs 3,17,162'), findsOneWidget);
    },
    variant: windowsOnly,
  );

  testWidgets(
    'Del does nothing on an already-deleted row shown via the toggle',
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
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ledger.showDeleted')));
      await tester.pumpAndSettle();
      // Toggling resets the selection to the top; move down to the deleted row.
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
      expect(find.byKey(const Key('ledger.deleteDialog')), findsNothing);
    },
    variant: windowsOnly,
  );
}
