import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/bootstrap/router.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets(
    'first launch asks for the firm, Ctrl+Enter creates it and lands on the dashboard',
    (tester) async {
      await pumpLedgerly(tester);
      expect(find.text('Set up your firm'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('setup.firmName')),
        'Al-Madina Oil Mills',
      );
      await tester.enterText(
        find.byKey(const Key('setup.contact')),
        '0300-1234567',
      );
      await pressCtrl(tester, LogicalKeyboardKey.enter);

      expect(find.text('Set up your firm'), findsNothing);
      expect(find.text('Al-Madina Oil Mills'), findsOneWidget); // title bar
      expect(
        find.text('No customers yet. Press Ctrl+N to record the first sale.'),
        findsOneWidget,
      );
    },
    variant: windowsOnly,
  );

  testWidgets(
    'dashboard shows receivables and giveables from real transactions, sorted high to low',
    (tester) async {
      await pumpLedgerly(
        tester,
        seed: (db, ctx) async {
          await FirmSetup(
            db,
            ctx,
          ).createFirm(name: 'Al-Madina Oil Mills', contactNumber: '0300');
          final customers = CustomersRepository(db, ctx);
          final bills = BillsRepository(db, ctx);
          final rashid = await customers.create(name: 'Rashid Traders');
          final ahmed = await customers.create(name: 'Ahmed & Sons');
          final seedCo = await customers.create(name: 'Sahiwal Seed Co.');
          Future<void> cash(String cust, TransactionType type, int rupees) =>
              bills.saveNew(
                Bill(
                  id: newId(),
                  customerId: cust,
                  type: type,
                  entryDate: '2026-09-18',
                  typedAmount: Money.rupees(rupees),
                ),
              );
          await cash(rashid.id, TransactionType.openingBalance, 620000);
          await cash(ahmed.id, TransactionType.openingBalance, 415500);
          await cash(
            seedCo.id,
            TransactionType.cashIn,
            280000,
          ); // advance received → we owe them
        },
      );

      final recv = find.byKey(const Key('dashboard.receivables'));
      final give = find.byKey(const Key('dashboard.giveables'));
      expect(
        find.descendant(of: recv, matching: find.text('Rashid Traders')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: recv, matching: find.text('6,20,000')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: recv, matching: find.text('4,15,500')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: give, matching: find.text('Sahiwal Seed Co.')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: give, matching: find.text('2,80,000')),
        findsOneWidget,
      );
      expect(find.text('Rs 10,35,500'), findsOneWidget); // receivable total
      expect(find.text('Rs 2,80,000'), findsOneWidget); // giveable total

      // Rashid (bigger) is listed before Ahmed.
      final rashidY = tester.getTopLeft(find.text('Rashid Traders')).dy;
      final ahmedY = tester.getTopLeft(find.text('Ahmed & Sons')).dy;
      expect(rashidY, lessThan(ahmedY));
    },
    variant: windowsOnly,
  );

  testWidgets(
    'search is focused on open, filters fuzzily, and Enter opens the ledger',
    (tester) async {
      await pumpLedgerly(
        tester,
        seed: (db, ctx) async {
          await FirmSetup(
            db,
            ctx,
          ).createFirm(name: 'Mill', contactNumber: '0300');
          final customers = CustomersRepository(db, ctx);
          final bills = BillsRepository(db, ctx);
          for (final name in [
            'Rashid Traders',
            'Ahmed & Sons',
            'Karim Store',
          ]) {
            final c = await customers.create(name: name);
            await bills.saveNew(
              Bill(
                id: newId(),
                customerId: c.id,
                type: TransactionType.openingBalance,
                entryDate: '2026-09-18',
                typedAmount: Money.rupees(1000),
              ),
            );
          }
        },
      );

      expect(
        tester.binding.focusManager.primaryFocus?.debugLabel,
        'dashboard.search',
      );
      await tester.enterText(
        find.byKey(const Key('dashboard.search')),
        'rashd',
      );
      await tester.pumpAndSettle();
      expect(find.text('Rashid Traders'), findsOneWidget);
      expect(find.text('Karim Store'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter, platform: 'windows');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ledger.screen')), findsOneWidget);
      expect(find.text('Rashid Traders'), findsWidgets);
    },
    variant: windowsOnly,
  );

  testWidgets('arrow keys move the selection and Ctrl+N opens a new sale', (
    tester,
  ) async {
    await pumpLedgerly(
      tester,
      seed: (db, ctx) async {
        await FirmSetup(
          db,
          ctx,
        ).createFirm(name: 'Mill', contactNumber: '0300');
        final customers = CustomersRepository(db, ctx);
        final bills = BillsRepository(db, ctx);
        for (final (name, rupees) in [
          ('Rashid Traders', 5000),
          ('Ahmed & Sons', 3000),
        ]) {
          final c = await customers.create(name: name);
          await bills.saveNew(
            Bill(
              id: newId(),
              customerId: c.id,
              type: TransactionType.openingBalance,
              entryDate: '2026-09-18',
              typedAmount: Money.rupees(rupees),
            ),
          );
        }
      },
    );

    await tester.sendKeyEvent(
      LogicalKeyboardKey.arrowDown,
      platform: 'windows',
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter, platform: 'windows');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ledger.screen')), findsOneWidget);
    expect(find.text('Ahmed & Sons'), findsWidgets);

    await pressCtrl(tester, LogicalKeyboardKey.keyN);
    expect(find.byKey(const Key('bill.screen')), findsOneWidget);
  }, variant: windowsOnly);

  testWidgets('dashboard renders at phone width without the desktop rail', (
    tester,
  ) async {
    await pumpLedgerly(
      tester,
      seed: (db, ctx) async {
        await FirmSetup(db, ctx)
            .createFirm(name: 'Test Firm', contactNumber: '0300');
      },
      viewSize: const Size(390, 844),
    );

    expect(find.byKey(const Key('shell.bottomNav')), findsOneWidget);
  }, variant: phoneOnly);

  testWidgets(
    'dashboard balance panel header does not overflow at phone width with a large balance',
    (tester) async {
      await pumpLedgerly(
        tester,
        seed: (db, ctx) async {
          await FirmSetup(db, ctx)
              .createFirm(name: 'Test Firm', contactNumber: '0300');
          final customers = CustomersRepository(db, ctx);
          final bills = BillsRepository(db, ctx);
          final rashid = await customers.create(name: 'Rashid Traders');
          await bills.saveNew(
            Bill(
              id: newId(),
              customerId: rashid.id,
              type: TransactionType.openingBalance,
              entryDate: '2026-09-18',
              typedAmount: Money.rupees(50000000), // Rs 5,00,00,000
            ),
          );
        },
        viewSize: const Size(390, 844),
      );

      expect(tester.takeException(), isNull);
    },
    variant: phoneOnly,
  );

  testWidgets('desktop width still shows the nav rail, not the bottom nav', (
    tester,
  ) async {
    final seed = (AppDatabase db, DeviceContext ctx) async {
      await FirmSetup(db, ctx)
          .createFirm(name: 'Test Firm', contactNumber: '0300');
    };
    await pumpLedgerly(tester, seed: seed); // default desktop size

    expect(find.byKey(const Key('shell.bottomNav')), findsNothing);
  }, variant: windowsOnly);

  testWidgets('a drill-down route at phone width shows a back button, not the bottom nav', (
    tester,
  ) async {
    final container = await pumpLedgerly(
      tester,
      seed: (db, ctx) async {
        await FirmSetup(db, ctx)
            .createFirm(name: 'Test Firm', contactNumber: '0300');
      },
      viewSize: const Size(412, 844),
    );
    // Navigate to items new (a drill-down route, not a top-level destination)
    container.read(routerProvider).go('/items/new');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shell.backButton')), findsOneWidget);
    expect(find.byKey(const Key('shell.bottomNav')), findsNothing);
  }, variant: phoneOnly);

  testWidgets('at phone width, the customers tab FAB opens the new-customer form', (
    tester,
  ) async {
    final container = await pumpLedgerly(
      tester,
      seed: (db, ctx) async {
        await FirmSetup(db, ctx)
            .createFirm(name: 'Test Firm', contactNumber: '0300');
      },
      viewSize: const Size(390, 844),
    );
    container.read(routerProvider).go('/customers');
    await tester.pumpAndSettle();

    // customers_screen.dart's header overflow at phone width was fixed
    // separately (customers_items_test.dart) -- no exception expected here.
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('shell.fab.addCustomer')), findsOneWidget);
    await tester.tap(find.byKey(const Key('shell.fab.addCustomer')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('customer.form')), findsOneWidget);
  }, variant: phoneOnly);

  testWidgets('at phone width, the items tab FAB opens the new-item form', (
    tester,
  ) async {
    final container = await pumpLedgerly(
      tester,
      seed: (db, ctx) async {
        await FirmSetup(db, ctx)
            .createFirm(name: 'Test Firm', contactNumber: '0300');
      },
      viewSize: const Size(390, 844),
    );
    container.read(routerProvider).go('/items');
    await tester.pumpAndSettle();

    // items_screen.dart's header/NAME-column overflow at phone width was
    // fixed separately (customers_items_test.dart) -- no exception
    // expected here.
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('shell.fab.addItem')), findsOneWidget);
    await tester.tap(find.byKey(const Key('shell.fab.addItem')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('item.form')), findsOneWidget);
  }, variant: phoneOnly);

  testWidgets('at phone width, settings has no FAB at all', (tester) async {
    final container = await pumpLedgerly(
      tester,
      seed: (db, ctx) async {
        await FirmSetup(db, ctx)
            .createFirm(name: 'Test Firm', contactNumber: '0300');
      },
      viewSize: const Size(390, 844),
    );
    container.read(routerProvider).go('/settings');
    await tester.pumpAndSettle();

    // settings_screen.dart's _field overflow at phone width was fixed
    // separately (settings_test.dart) -- no exception expected here anymore.
    expect(tester.takeException(), isNull);
    expect(find.byType(FloatingActionButton), findsNothing);
  }, variant: phoneOnly);

  testWidgets(
    'at phone width, the cash-sales tab FAB opens a chooser and "Cash in" opens the cash-in form',
    (tester) async {
      final container = await pumpLedgerly(
        tester,
        seed: (db, ctx) async {
          await FirmSetup(db, ctx)
              .createFirm(name: 'Test Firm', contactNumber: '0300');
        },
        viewSize: const Size(390, 844),
      );
      container.read(routerProvider).go('/cash-sales');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shell.fab.cashChooser')), findsOneWidget);
      await tester.tap(find.byKey(const Key('shell.fab.cashChooser')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shell.cashChooserDialog')), findsOneWidget);
      expect(
        find.byKey(const Key('shell.cashChooserDialog.cashIn')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shell.cashChooserDialog.cashOut')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('shell.cashChooserDialog.cashIn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shell.cashChooserDialog')), findsNothing);
      expect(find.text('CASH RECEIVED'), findsOneWidget); // type=cash_in
    },
    variant: phoneOnly,
  );

  testWidgets(
    'at phone width, the cash-sales tab FAB chooser\'s "Cash out" opens the cash-out form',
    (tester) async {
      final container = await pumpLedgerly(
        tester,
        seed: (db, ctx) async {
          await FirmSetup(db, ctx)
              .createFirm(name: 'Test Firm', contactNumber: '0300');
        },
        viewSize: const Size(390, 844),
      );
      container.read(routerProvider).go('/cash-sales');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shell.fab.cashChooser')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('shell.cashChooserDialog.cashOut')),
      );
      await tester.pumpAndSettle();

      expect(find.text('CASH PAID'), findsOneWidget); // type=cash_out
    },
    variant: phoneOnly,
  );

  testWidgets(
    'at phone width, a long customer name is ellipsized in the dashboard '
    'receivables list instead of wrapping across several lines',
    (tester) async {
      const longName =
          'Muhammad Abdul Rahman Extremely Long Trading Company Name';
      await pumpLedgerly(
        tester,
        seed: (db, ctx) async {
          await FirmSetup(db, ctx)
              .createFirm(name: 'Test Firm', contactNumber: '0300');
          final customer = await CustomersRepository(
            db,
            ctx,
          ).create(name: longName);
          await BillsRepository(db, ctx).saveNew(
            Bill(
              id: newId(),
              customerId: customer.id,
              type: TransactionType.openingBalance,
              entryDate: '2026-09-01',
              typedAmount: Money.rupees(10000),
            ),
          );
        },
        viewSize: const Size(390, 844),
      );

      expect(tester.takeException(), isNull);
      // Before the fix this Text had no overflow/maxLines handling, so the
      // Expanded slice next to the balance column wrapped the name across
      // several lines instead of truncating cleanly.
      final nameFinder = find.text(longName);
      expect(nameFinder, findsOneWidget);
      expect(tester.getSize(nameFinder).height, lessThan(30));
    },
    variant: phoneOnly,
  );
}
