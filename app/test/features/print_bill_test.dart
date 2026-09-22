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

  for (final (name, arm)
      in <(String, void Function(FakeThermalPrinterService))>[
        ('connect', (FakeThermalPrinterService t) => t.throwOnConnect = true),
        ('write', (FakeThermalPrinterService t) => t.throwOnWrite = true),
      ]) {
    testWidgets(
      'a PlatformException thrown from $name falls through to the PDF path '
      'and still disconnects',
      (tester) async {
        // The real plugin throws (adapter off, bond lost mid-write,
        // permission revoked) rather than returning false. Unhandled, that
        // escaped printSlip as an async error from a button's onPressed:
        // no print, no PDF fallback, no message, and a socket left open.
        final container = await pumpLedgerly(
          tester,
          seed: seedMillPhone,
          viewSize: const Size(390, 844),
        );
        await container
            .read(globalPrefsProvider)
            .setThermalPrinter(name: 'MPT-II', mac: '00:11:22:33:44:55');
        arm(
          container.read(thermalPrinterServiceProvider)
              as FakeThermalPrinterService,
        );
        await pressCtrl(tester, LogicalKeyboardKey.keyI);
        await tester.enterText(
          find.byKey(const Key('bill.customer')),
          'Rashid',
        );
        await tester.sendKeyEvent(
          LogicalKeyboardKey.enter,
          platform: 'windows',
        );
        await tester.enterText(find.byKey(const Key('cash.amount')), '1000');
        await pressCtrl(tester, LogicalKeyboardKey.enter);

        await pressCtrl(tester, LogicalKeyboardKey.keyP);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final thermal = container.read(
          thermalPrinterServiceProvider,
        ) as FakeThermalPrinterService;
        expect(thermal.disconnected, isTrue);
        final printing =
            container.read(printingServiceProvider) as FakePrintingService;
        expect(printing.printedJobs.length, 1); // fell through correctly
      },
      variant: phoneOnly,
    );
  }

  testWidgets(
    'on desktop a saved Bluetooth printer is ignored: slips keep going to '
    'the configured OS printer',
    (tester) async {
      // Bluetooth thermal printing is scoped to Android. A desktop user who
      // once saved a printer must not have their slips silently rerouted.
      final container = await pumpLedgerly(tester, seed: seedMill);
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
      expect(thermal.connectedMac, isNull); // never even tried
      final printing =
          container.read(printingServiceProvider) as FakePrintingService;
      expect(printing.printedJobs.length, 1);
    },
    variant: windowsOnly,
  );

  testWidgets(
    'a disconnect that throws after a successful write does not print twice',
    (tester) async {
      // disconnect() lives in printSlip's finally block, downstream of the
      // successful write + logPrint + return. Before the fix, that throw
      // replaced the pending success and was swallowed by `on Exception`,
      // which fell through to the PDF path below -- a second, duplicate
      // print of the same slip.
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
      thermal.throwOnDisconnect = true;
      await pressCtrl(tester, LogicalKeyboardKey.keyI);
      await tester.enterText(find.byKey(const Key('bill.customer')), 'Rashid');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter, platform: 'windows');
      await tester.enterText(find.byKey(const Key('cash.amount')), '1000');
      await pressCtrl(tester, LogicalKeyboardKey.enter);

      await pressCtrl(tester, LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(thermal.written, hasLength(1));
      expect(thermal.disconnected, isTrue);
      final printing =
          container.read(printingServiceProvider) as FakePrintingService;
      expect(printing.printedJobs, isEmpty); // no fallthrough to the PDF path
      final db = container.read(openFirmProvider).value!.db;
      final rows = await db.customSelect('SELECT kind FROM print_log').get();
      expect(rows, hasLength(1)); // logged once, not twice
    },
    variant: phoneOnly,
  );

  testWidgets(
    'a connected printer that fails mid-write still falls back to the PDF path, and still disconnects',
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
      thermal.writeSucceeds = false;
      await pressCtrl(tester, LogicalKeyboardKey.keyI);
      await tester.enterText(find.byKey(const Key('bill.customer')), 'Rashid');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter, platform: 'windows');
      await tester.enterText(find.byKey(const Key('cash.amount')), '1000');
      await pressCtrl(tester, LogicalKeyboardKey.enter);

      await pressCtrl(tester, LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();

      expect(thermal.connectedMac, '00:11:22:33:44:55');
      expect(thermal.disconnected, isTrue); // still disconnects on failure
      final printing =
          container.read(printingServiceProvider) as FakePrintingService;
      expect(printing.printedJobs.length, 1); // fell through correctly
    },
    variant: phoneOnly,
  );
}
