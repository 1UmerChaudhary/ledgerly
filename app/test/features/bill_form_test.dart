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

// A bare firm, no customers/balances — the phone-width tests below only
// exercise bill_screen.dart's own layout, and a big seeded balance trips an
// unrelated, pre-existing dashboard_screen.dart overflow at this width (see
// task-3-report.md), which would otherwise contaminate every assertion here.
Future<void> seedFirmOnly(AppDatabase db, DeviceContext ctx) async {
  await FirmSetup(db, ctx).createFirm(name: 'Test Firm', contactNumber: '0300');
}

// Same bare firm, plus one item with a default bag weight — for the
// LineCard item-pick test, which needs something with a default to auto-fill.
Future<void> seedFirmWithItem(AppDatabase db, DeviceContext ctx) async {
  await FirmSetup(db, ctx).createFirm(name: 'Test Firm', contactNumber: '0300');
  await ItemsRepository(db, ctx).create(
    name: 'Oil',
    defaultBagWeight: Weight.kg(16),
    defaultRateBase: RateBase.maund,
  );
}

/// The base presets a line card currently shows as chosen, by label ("40",
/// "37.324"). A list rather than a single value so a test can assert that
/// exactly one -- or no -- chip is selected.
List<String> selectedBaseChips(WidgetTester tester) => tester
    .widgetList<ChoiceChip>(find.byType(ChoiceChip))
    .where((chip) => chip.selected)
    .map((chip) => ((chip.label as Text).data ?? '').replaceAll('kg', ''))
    .toList();

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

  testWidgets('at phone width, the bill header does not overflow its row', (
    tester,
  ) async {
    await pumpLedgerly(
      tester,
      seed: seedFirmOnly,
      viewSize: const Size(390, 844),
    );
    await tester.tap(find.byKey(const Key('shell.fab.newSale')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  }, variant: phoneOnly);

  testWidgets(
    'at phone width, the "pick a customer" totals hint wraps normally '
    'instead of one character per line',
    (tester) async {
      await pumpLedgerly(
        tester,
        seed: seedFirmOnly,
        viewSize: const Size(390, 844),
      );
      await tester.tap(find.byKey(const Key('shell.fab.newSale')));
      await tester.pumpAndSettle();

      // The totals section (and this hint inside it) sits below the fold
      // on a phone-height viewport -- scroll to it like a real user would.
      final hint = find.text('Pick a customer to see the balance change.');
      await tester.dragUntilVisible(
        hint,
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // _Totals's compact LayoutBuilder split (fixed earlier in this effort)
      // gives this hint the full row width instead of an Expanded sliver
      // squeezed next to a fixed 320px totals box -- unfixed, that squeeze
      // wraps the sentence character-by-character (measured ~950px tall).
      // A normal 1-2 line wrap is well under 50px.
      expect(tester.getSize(hint).height, lessThan(50));
    },
    variant: phoneOnly,
  );

  testWidgets(
    'at phone width, a sale line renders as a touch card, not the grid',
    (tester) async {
      await pumpLedgerly(
        tester,
        seed: seedFirmOnly,
        viewSize: const Size(390, 844),
      );
      await tester.pumpAndSettle(); // dashboard first at phone width
      // Navigate to a new sale via the FAB added in Task 2.
      await tester.tap(find.byKey(const Key('shell.fab.newSale')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bill.line.0.card')), findsOneWidget);
      expect(
        find.byKey(const Key('bill.line.0.card.deleteButton')),
        findsOneWidget,
      );
    },
    variant: phoneOnly,
  );

  testWidgets('tapping a card delete button removes that line', (tester) async {
    await pumpLedgerly(
      tester,
      seed: seedFirmOnly,
      viewSize: const Size(390, 844),
    );
    await tester.tap(find.byKey(const Key('shell.fab.newSale')));
    await tester.pumpAndSettle();
    // "+ Add line" and then the second card both sit below the fold on a
    // phone viewport now that each card also carries base, line total and
    // override -- a real touch user scrolls to them. dragUntilVisible only
    // guarantees the widget exists, so each scroll finishes with
    // ensureVisible, which is what actually brings it into the viewport.
    await tester.ensureVisible(find.byKey(const Key('bill.line.card.addLine')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bill.line.card.addLine')));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.byKey(const Key('bill.line.1.card.deleteButton')),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.ensureVisible(
      find.byKey(const Key('bill.line.1.card.deleteButton')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bill.line.1.card')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bill.line.1.card.deleteButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bill.line.1.card')), findsNothing);
  }, variant: phoneOnly);

  testWidgets(
    'tapping the mode toggle flips bags to weight, and offers only two segments',
    (tester) async {
      await pumpLedgerly(
        tester,
        seed: seedFirmOnly,
        viewSize: const Size(390, 844),
      );
      await tester.tap(find.byKey(const Key('shell.fab.newSale')));
      await tester.pumpAndSettle();

      // Phase 5's byCount is not wired into any UI yet (see bill_draft.dart's
      // toggleMode, which only flips bags<->weight) — the card must not offer
      // a third option the rest of the app doesn't expose.
      expect(find.text('Count'), findsNothing);
      expect(find.byKey(const Key('bill.line.0.card.bags')), findsOneWidget);
      expect(find.byKey(const Key('bill.line.0.card.totalKg')), findsNothing);

      await tester.tap(find.text('Weight'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bill.line.0.card.bags')), findsNothing);
      expect(find.byKey(const Key('bill.line.0.card.totalKg')), findsOneWidget);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'picking an item with a default bag weight fills the bag-weight field on screen',
    (tester) async {
      await pumpLedgerly(
        tester,
        seed: seedFirmWithItem,
        viewSize: const Size(390, 844),
      );
      await tester.tap(find.byKey(const Key('shell.fab.newSale')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bill.line.0.card.itemButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oil'));
      await tester.pumpAndSettle();

      // The default bag weight (16kg) must actually render, not just update
      // LineDraft state underneath a stale TextFormField(initialValue:).
      expect(find.text('16.000'), findsOneWidget);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'at phone width, tapping the on-screen Save button saves a valid walk-in sale',
    (tester) async {
      await pumpLedgerly(
        tester,
        seed: seedFirmWithItem,
        viewSize: const Size(390, 844),
      );
      await tester.tap(find.byKey(const Key('shell.fab.newSale')));
      await tester.pumpAndSettle();

      // Walk-in skips the customer requirement -- the shortest path to a
      // valid sale, avoiding EntityAutocomplete's touch keyboard entirely.
      await tester.tap(find.byKey(const Key('bill.walkIn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bill.line.0.card.itemButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oil'));
      await tester.pumpAndSettle();

      await typeInto(tester, const Key('bill.line.0.card.bags'), '10');
      await typeInto(tester, const Key('bill.line.0.card.rate'), '9000');

      // The Save/Cancel row sits at the end of the scrollable form content,
      // below the fold on a phone-height viewport -- a real touch user
      // scrolls to it the same way.
      await tester.dragUntilVisible(
        find.byKey(const Key('bill.compactSave')),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.tap(find.byKey(const Key('bill.compactSave')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bill.saved')), findsOneWidget);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'the line card shows the active base, highlights its preset chip, and '
    'lets a non-preset base be typed',
    (tester) async {
      // The preset chips were write-only ActionChips: nothing on screen said
      // which base was active, including the one pickItem fills in from the
      // item's own default, and a base outside the five presets could not be
      // entered at all.
      await pumpLedgerly(
        tester,
        seed: seedFirmWithItem,
        viewSize: const Size(390, 844),
      );
      await tester.tap(find.byKey(const Key('shell.fab.newSale')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bill.line.0.card.itemButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oil'));
      await tester.pumpAndSettle();

      // Oil's defaultRateBase is the maund, so its chip -- and only its chip
      // -- comes up selected, and the base field echoes the same value.
      expect(selectedBaseChips(tester), [formatKg(RateBase.maund, trim: true)]);
      expect(
        (tester.widget<TextField>(
          find.byKey(const Key('bill.line.0.card.base')),
        )).controller!.text,
        formatKg(RateBase.maund),
      );

      // Chip labels use the same spelling as the desktop grid's 1-5 hotkeys
      // ("40kg"), not a raw double ("40.0kg").
      expect(find.text('40kg'), findsOneWidget);

      await typeInto(tester, const Key('bill.line.0.card.base'), '45');
      expect(selectedBaseChips(tester), isEmpty);

      await tester.tap(
        find.byKey(Key('bill.line.0.card.basePreset.${RateBase.forty.grams}')),
      );
      await tester.pumpAndSettle();
      expect(selectedBaseChips(tester), [formatKg(RateBase.forty, trim: true)]);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'the line card shows the computed line total, and a per-line override '
    'replaces it in the bill total',
    (tester) async {
      await pumpLedgerly(
        tester,
        seed: seedFirmWithItem,
        viewSize: const Size(390, 844),
      );
      await tester.tap(find.byKey(const Key('shell.fab.newSale')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bill.line.0.card.itemButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oil'));
      await tester.pumpAndSettle();

      // Incomplete line: a dash, not a blank that would read as zero.
      expect(
        find.descendant(
          of: find.byKey(const Key('bill.line.0.card.lineTotal')),
          matching: find.text('—'),
        ),
        findsOneWidget,
      );

      await typeInto(tester, const Key('bill.line.0.card.bags'), '10');
      await typeInto(tester, const Key('bill.line.0.card.rate'), '9000');

      // Derived through the domain rather than hardcoded, so this asserts
      // the card shows what the desktop grid row shows for the same line.
      final expectedLine = BillLine(
        id: 'unused',
        lineNo: 1,
        itemId: 'unused',
        saleMode: SaleMode.byBags,
        bagCount: 10,
        bagWeight: Weight.kg(16),
        totalWeight: Weight.kg(160),
        rate: Money.rupees(9000),
        rateBase: RateBase.maund,
      );
      await tester.ensureVisible(
        find.byKey(const Key('bill.line.0.card.lineTotal')),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('bill.line.0.card.lineTotal')),
          matching: find.text(
            formatMoney(expectedLine.calculatedTotal, symbol: false),
          ),
        ),
        findsOneWidget,
      );

      // The override is what the bill then totals to -- BillLine.finalTotal
      // prefers overriddenTotal, and the draft sums finalTotal.
      await typeInto(tester, const Key('bill.line.0.card.override'), '40000');
      expect(find.text('Rs 40,000'), findsOneWidget);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'at phone width, tapping Cancel on a dirty unsaved bill asks before discarding',
    (tester) async {
      await pumpLedgerly(
        tester,
        seed: seedFirmOnly,
        viewSize: const Size(390, 844),
      );
      await tester.tap(find.byKey(const Key('shell.fab.newSale')));
      await tester.pumpAndSettle();

      await typeInto(tester, const Key('bill.description'), 'Sept supply');

      // Same below-the-fold reasoning as the Save test above.
      await tester.dragUntilVisible(
        find.byKey(const Key('bill.compactCancel')),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.tap(find.byKey(const Key('bill.compactCancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bill.screen')), findsOneWidget);
      expect(find.byKey(const Key('bill.discardDialog')), findsOneWidget);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'the Android system back gesture on a dirty unsaved bill asks before '
    'discarding instead of silently leaving',
    (tester) async {
      await pumpLedgerly(
        tester,
        seed: seedFirmOnly,
        viewSize: const Size(390, 844),
      );
      await tester.tap(find.byKey(const Key('shell.fab.newSale')));
      await tester.pumpAndSettle();
      await typeInto(tester, const Key('bill.description'), 'Sept supply');

      await systemBack(tester);

      // The shell's generic PopScope would have done context.go('/') here,
      // dropping the bill with no prompt.
      expect(find.byKey(const Key('bill.screen')), findsOneWidget);
      expect(find.byKey(const Key('bill.discardDialog')), findsOneWidget);

      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bill.screen')), findsOneWidget);

      await systemBack(tester);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bill.screen')), findsNothing);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'the title-bar back button on a dirty unsaved bill asks before discarding',
    (tester) async {
      await pumpLedgerly(
        tester,
        seed: seedFirmOnly,
        viewSize: const Size(390, 844),
      );
      await tester.tap(find.byKey(const Key('shell.fab.newSale')));
      await tester.pumpAndSettle();
      await typeInto(tester, const Key('bill.description'), 'Sept supply');

      await tester.tap(find.byKey(const Key('shell.backButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bill.discardDialog')), findsOneWidget);
    },
    variant: phoneOnly,
  );
}
