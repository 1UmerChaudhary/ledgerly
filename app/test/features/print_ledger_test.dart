import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/printing/print_actions.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../support/pump_app.dart';

Future<void> seedLedger(AppDatabase db, DeviceContext ctx) async {
  await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
  final rashid = await CustomersRepository(
    db,
    ctx,
  ).create(name: 'Rashid Traders');
  await BillsRepository(db, ctx).saveNew(
    Bill(
      id: newId(),
      customerId: rashid.id,
      type: TransactionType.openingBalance,
      entryDate: '2026-09-01',
      typedAmount: Money.rupees(220000),
    ),
  );
}

void main() {
  testWidgets(
    'Ctrl+Shift+P opens the range dialog; All prints the whole ledger',
    (tester) async {
      final container = await pumpLedgerly(tester, seed: seedLedger);
      await tester.enterText(
        find.byKey(const Key('dashboard.search')),
        'rashid',
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter, platform: 'windows');
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.controlLeft,
        platform: 'windows',
      );
      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.shiftLeft,
        platform: 'windows',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP, platform: 'windows');
      await tester.sendKeyUpEvent(
        LogicalKeyboardKey.shiftLeft,
        platform: 'windows',
      );
      await tester.sendKeyUpEvent(
        LogicalKeyboardKey.controlLeft,
        platform: 'windows',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('printRange.dialog')), findsOneWidget);
      await tester.tap(find.byKey(const Key('printRange.all')));
      await tester.pumpAndSettle();

      final printing =
          container.read(printingServiceProvider) as FakePrintingService;
      expect(printing.printedJobs.length, 1);
    },
    variant: windowsOnly,
  );

  testWidgets('Custom range asks for two dates before printing', (
    tester,
  ) async {
    final container = await pumpLedgerly(tester, seed: seedLedger);
    await tester.enterText(find.byKey(const Key('dashboard.search')), 'rashid');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter, platform: 'windows');
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(
      LogicalKeyboardKey.controlLeft,
      platform: 'windows',
    );
    await tester.sendKeyDownEvent(
      LogicalKeyboardKey.shiftLeft,
      platform: 'windows',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP, platform: 'windows');
    await tester.sendKeyUpEvent(
      LogicalKeyboardKey.shiftLeft,
      platform: 'windows',
    );
    await tester.sendKeyUpEvent(
      LogicalKeyboardKey.controlLeft,
      platform: 'windows',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('printRange.custom')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('printRange.fromDate')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('printRange.fromDate')),
      '01/09/2026',
    );
    await tester.enterText(
      find.byKey(const Key('printRange.toDate')),
      '30/09/2026',
    );
    await tester.tap(find.byKey(const Key('printRange.go')));
    await tester.pumpAndSettle();

    final printing =
        container.read(printingServiceProvider) as FakePrintingService;
    expect(printing.printedJobs.length, 1);
  }, variant: windowsOnly);
}
