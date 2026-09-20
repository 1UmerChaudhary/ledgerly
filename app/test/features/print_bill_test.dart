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

// Same customer, short firm name -- "Al-Madina Oil Mills" trips an unrelated,
// pre-existing app_shell.dart title-bar overflow at phone width (same class
// of bug bill_form_test.dart's seedFirmOnly comment describes for the
// dashboard), which would otherwise contaminate the phoneOnly tests below.
Future<void> seedMillPhone(AppDatabase db, DeviceContext ctx) async {
  await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
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

  testWidgets(
    'on Android with a saved Bluetooth printer, Ctrl+P prints via Bluetooth instead of the OS dialog',
    (tester) async {
      final container = await pumpLedgerly(
        tester,
        seed: seedMillPhone,
        viewSize: const Size(390, 844),
      );
      await container
          .read(globalPrefsProvider)
          .setThermalPrinter(name: 'MPT-II', mac: '00:11:22:33:44:55');
      await pressCtrl(tester, LogicalKeyboardKey.keyI);
      await tester.enterText(find.byKey(const Key('bill.customer')), 'Rashid');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter, platform: 'windows');
      await tester.enterText(find.byKey(const Key('cash.amount')), '1000');
      await pressCtrl(tester, LogicalKeyboardKey.enter);

      await pressCtrl(tester, LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();

      final thermal = container.read(
        thermalPrinterServiceProvider,
      ) as FakeThermalPrinterService;
      expect(thermal.connectedMac, '00:11:22:33:44:55');
      expect(thermal.written, hasLength(1));
      expect(thermal.disconnected, isTrue);
      final printing =
          container.read(printingServiceProvider) as FakePrintingService;
      expect(
        printing.printedJobs,
        isEmpty,
      ); // did not fall through to the PDF path
    },
    variant: phoneOnly,
  );

  testWidgets(
    'a failed Bluetooth connect falls back to the normal PDF print path',
    (tester) async {
      final container = await pumpLedgerly(
        tester,
        seed: seedMillPhone,
        viewSize: const Size(390, 844),
      );
      await container
          .read(globalPrefsProvider)
          .setThermalPrinter(name: 'MPT-II', mac: '00:11:22:33:44:55');
      final thermal = container.read(
        thermalPrinterServiceProvider,
      ) as FakeThermalPrinterService;
      thermal.connectSucceeds = false;
      await pressCtrl(tester, LogicalKeyboardKey.keyI);
      await tester.enterText(find.byKey(const Key('bill.customer')), 'Rashid');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter, platform: 'windows');
      await tester.enterText(find.byKey(const Key('cash.amount')), '1000');
      await pressCtrl(tester, LogicalKeyboardKey.enter);

      await pressCtrl(tester, LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();

      expect(thermal.written, isEmpty);
      final printing =
          container.read(printingServiceProvider) as FakePrintingService;
      expect(printing.printedJobs.length, 1); // fell through correctly
    },
    variant: phoneOnly,
  );
}
