import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/bootstrap/router.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../support/pump_app.dart';

Future<void> seedFirm(AppDatabase db, DeviceContext ctx) async {
  await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
  await CustomersRepository(
    db,
    ctx,
  ).create(name: 'Existing Customer', phone: '0300-1111111');
}

Future<void> type(WidgetTester tester, Key key, String text) async {
  await tester.tap(find.byKey(key));
  await tester.pump();
  await tester.enterText(find.byKey(key), text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'typing rows in the grid and saving creates customers with the right opening entries',
    (tester) async {
      await pumpLedgerly(tester, seed: seedFirm);
      await tester.tap(find.text('Customers'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import opening balances'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('openingBalances.screen')), findsOneWidget);

      await type(
        tester,
        const Key('openingBalances.row.0.name'),
        'Rashid Traders',
      );
      await type(
        tester,
        const Key('openingBalances.row.0.phone'),
        '0300-9876543',
      );
      await type(tester, const Key('openingBalances.row.0.balance'), '620000');

      await tester.tap(find.byKey(const Key('openingBalances.addRow')));
      await tester.pumpAndSettle();
      await type(
        tester,
        const Key('openingBalances.row.1.name'),
        'Sahiwal Seed Co.',
      );
      await type(tester, const Key('openingBalances.row.1.balance'), '-280000');

      await tester.tap(find.byKey(const Key('openingBalances.save')));
      await tester.pumpAndSettle();

      expect(find.textContaining('2 customers'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Rashid Traders'), findsOneWidget);
      expect(find.textContaining('owes'), findsWidgets);
      expect(find.text('Sahiwal Seed Co.'), findsOneWidget);
    },
    variant: windowsOnly,
  );

  testWidgets(
    'a duplicate phone against an existing customer is reported, not silently skipped',
    (tester) async {
      await pumpLedgerly(tester, seed: seedFirm);
      await tester.tap(find.text('Customers'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import opening balances'));
      await tester.pumpAndSettle();

      await type(
        tester,
        const Key('openingBalances.row.0.name'),
        'Someone Else',
      );
      await type(
        tester,
        const Key('openingBalances.row.0.phone'),
        '0300-1111111',
      );
      await type(tester, const Key('openingBalances.row.0.balance'), '1000');
      await tester.tap(find.byKey(const Key('openingBalances.save')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('belongs to Existing Customer'),
        findsOneWidget,
      );
    },
    variant: windowsOnly,
  );

  testWidgets('pasting CSV fills the grid, ready to review before saving', (
    tester,
  ) async {
    await pumpLedgerly(tester, seed: seedFirm);
    await tester.tap(find.text('Customers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import opening balances'));
    await tester.pumpAndSettle();

    await type(
      tester,
      const Key('openingBalances.csvPaste'),
      'Karim Store,0301-2,50000\nBilal Depot,,-15000',
    );
    await tester.tap(find.byKey(const Key('openingBalances.applyCsv')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('openingBalances.row.0.name')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('openingBalances.row.0.name')),
          )
          .controller!
          .text,
      'Karim Store',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('openingBalances.row.1.name')),
          )
          .controller!
          .text,
      'Bilal Depot',
    );
  }, variant: windowsOnly);

  testWidgets(
    'at phone width, an opening-balance row stacks name/phone/balance so '
    'Balance stays reachable instead of being pushed off the overflow edge',
    (tester) async {
      final container = await pumpLedgerly(
        tester,
        seed: seedFirm,
        viewSize: const Size(390, 844),
      );
      container.read(routerProvider).go('/customers/opening-balances');
      await tester.pumpAndSettle();

      // Root cause: three fixed 240/160/140px SizedBoxes in one Row want
      // ~556px against a ~346px content width -- Balance (the last one)
      // was the one pushed past the overflowing edge.
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(
        find.byKey(const Key('openingBalances.row.0.balance')),
      );
      await tester.pumpAndSettle();
      await type(
        tester,
        const Key('openingBalances.row.0.name'),
        'Rashid Traders',
      );
      await type(
        tester,
        const Key('openingBalances.row.0.balance'),
        '620000',
      );
      await tester.ensureVisible(
        find.byKey(const Key('openingBalances.save')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('openingBalances.save')));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 customer'), findsOneWidget);
    },
    variant: phoneOnly,
  );
}
