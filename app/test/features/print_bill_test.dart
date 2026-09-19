import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/bootstrap/providers.dart';
import 'package:ledgerly/printing/print_actions.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../support/pump_app.dart';

Future<void> seedMill(AppDatabase db, DeviceContext ctx) async {
  await FirmSetup(
    db,
    ctx,
  ).createFirm(name: 'Al-Madina Oil Mills', contactNumber: '0300');
  await CustomersRepository(db, ctx).create(name: 'Rashid Traders');
}

void main() {
  testWidgets(
    'Ctrl+P from a cash entry\'s Saved state prints the slip and logs it',
    (tester) async {
      final container = await pumpLedgerly(tester, seed: seedMill);
      await pressCtrl(tester, LogicalKeyboardKey.keyI);
      await tester.enterText(find.byKey(const Key('bill.customer')), 'Rashid');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter, platform: 'windows');
      await tester.enterText(find.byKey(const Key('cash.amount')), '1000');
      await pressCtrl(tester, LogicalKeyboardKey.enter);
      expect(find.byKey(const Key('bill.saved')), findsOneWidget);

      await pressCtrl(tester, LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();

      final printing =
          container.read(printingServiceProvider) as FakePrintingService;
      expect(printing.printedJobs.length, 1);
      final db = container.read(openFirmProvider).value!.db;
      final rows = await db.customSelect('SELECT kind FROM print_log').get();
      expect(rows.single.read<String>('kind'), 'slip');
    },
    variant: windowsOnly,
  );

  testWidgets('Ctrl+P before saving does nothing (no saved bill to print)', (
    tester,
  ) async {
    final container = await pumpLedgerly(tester, seed: seedMill);
    await pressCtrl(tester, LogicalKeyboardKey.keyN);
    await pressCtrl(tester, LogicalKeyboardKey.keyP);
    await tester.pumpAndSettle();
    final printing =
        container.read(printingServiceProvider) as FakePrintingService;
    expect(printing.printedJobs, isEmpty);
  }, variant: windowsOnly);
}
