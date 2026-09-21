import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/bootstrap/router.dart';
import 'package:ledgerly/features/settings/settings_providers.dart';
import 'package:ledgerly/printing/print_actions.dart';
import 'package:ledgerly/printing/printing_service.dart';
import 'package:ledgerly/printing/thermal_printer_service.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../support/pump_app.dart';

Future<void> seed(AppDatabase db, DeviceContext ctx) async {
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
      typedAmount: const Money(60283572),
    ),
  );
}

Future<void> type(WidgetTester tester, Key key, String text) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pump();
  await tester.enterText(find.byKey(key), text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Ctrl+, opens Settings; editing the firm name updates the title bar after Ctrl+Enter',
    (tester) async {
      await pumpLedgerly(tester, seed: seed);
      await pressCtrl(tester, LogicalKeyboardKey.comma);
      expect(find.byKey(const Key('settings.screen')), findsOneWidget);
      await type(tester, const Key('settings.firmName'), 'Al-Madina Oil Mills');
      await pressCtrl(tester, LogicalKeyboardKey.enter);
      expect(
        find.text('Al-Madina Oil Mills'),
        findsWidgets,
      ); // title bar + field
    },
    variant: windowsOnly,
  );

  testWidgets('turning paisa on changes how the dashboard shows amounts', (
    tester,
  ) async {
    await pumpLedgerly(tester, seed: seed);
    expect(find.text('6,02,836'), findsOneWidget); // whole rupees, half-up
    await pressCtrl(tester, LogicalKeyboardKey.comma);
    await tester.tap(find.byKey(const Key('settings.showPaisa')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape, platform: 'windows');
    await tester.pumpAndSettle();
    expect(find.text('6,02,835.72'), findsOneWidget);
  }, variant: windowsOnly);

  testWidgets(
    'Backup now updates the status and the title bar reports it '
    '(BackupService itself, real files included, is proven in the data package)',
    (tester) async {
      await pumpLedgerly(tester, seed: seed);
      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await type(
        tester,
        const Key('settings.backupFolder'),
        r'D:\LedgerlyBackups',
      );
      expect(find.textContaining('Backed up'), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('settings.backupNow')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.backupNow')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Backed up'), findsWidgets);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape, platform: 'windows');
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Backed up'),
        findsWidgets,
      ); // survives leaving the screen
    },
    variant: windowsOnly,
  );

  testWidgets(
    'no printer chosen shows "Ask each time"; choosing one from the list '
    'saves it as the default',
    (tester) async {
      final container = await pumpLedgerly(tester, seed: seed);
      (container.read(
        printerDiscoveryProvider,
      ) as FakePrinterDiscovery).printers = const [
        PrinterInfo(name: 'Thermal-80mm', url: 'usb://001'),
      ];
      await pressCtrl(tester, LogicalKeyboardKey.comma);
      expect(find.text('Ask each time'), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings.choosePrinter')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('settings.printerOption.Thermal-80mm')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thermal-80mm'), findsOneWidget);
    },
    variant: windowsOnly,
  );

  testWidgets(
    'choosing "Ask each time" clears a previously chosen default printer',
    (tester) async {
      final container = await pumpLedgerly(tester, seed: seed);
      (container.read(
        printerDiscoveryProvider,
      ) as FakePrinterDiscovery).printers = const [
        PrinterInfo(name: 'Thermal-80mm', url: 'usb://001'),
      ];
      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await tester.tap(find.byKey(const Key('settings.choosePrinter')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('settings.printerOption.Thermal-80mm')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Thermal-80mm'), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings.choosePrinter')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.printerOption.none')));
      await tester.pumpAndSettle();

      expect(find.text('Ask each time'), findsOneWidget);
    },
    variant: windowsOnly,
  );

  testWidgets('Browse fills the backup folder field with the picked folder', (
    tester,
  ) async {
    final container = await pumpLedgerly(tester, seed: seed);
    (container.read(
      nativePickersProvider,
    ) as FakeNativePickers).folderToReturn = r'D:\LedgerlyBackups';
    await pressCtrl(tester, LogicalKeyboardKey.comma);

    await tester.ensureVisible(
      find.byKey(const Key('settings.browseBackupFolder')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings.browseBackupFolder')));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const Key('settings.backupFolder')),
    );
    expect(field.controller!.text, r'D:\LedgerlyBackups');
  }, variant: windowsOnly);

  testWidgets('Restore does nothing when the file picker is cancelled', (
    tester,
  ) async {
    final container = await pumpLedgerly(tester, seed: seed);
    (container.read(nativePickersProvider) as FakeNativePickers).fileToReturn =
        null;
    await pressCtrl(tester, LogicalKeyboardKey.comma);

    await tester.ensureVisible(find.byKey(const Key('settings.restore')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings.restore')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings.restoreConfirm')), findsNothing);
    expect(find.byKey(const Key('settings.screen')), findsOneWidget);
  }, variant: windowsOnly);

  testWidgets(
    'Restore shows a confirmation naming the picked file; cancelling it '
    'does nothing',
    (tester) async {
      final container = await pumpLedgerly(tester, seed: seed);
      (container.read(
        nativePickersProvider,
      ) as FakeNativePickers).fileToReturn = r'D:\backup.db';
      await pressCtrl(tester, LogicalKeyboardKey.comma);

      await tester.ensureVisible(find.byKey(const Key('settings.restore')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.restore')));
      await tester.pumpAndSettle();
      expect(find.textContaining(r'D:\backup.db'), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings.restoreConfirm.cancel')));
      await tester.pumpAndSettle();

      final fake = container.read(restoreServiceProvider) as FakeBackupService;
      expect(fake.restoredPath, isNull);
      expect(find.byKey(const Key('settings.screen')), findsOneWidget);
    },
    variant: windowsOnly,
  );

  testWidgets(
    'confirming restore of a valid backup replaces the data and reopens '
    'the firm',
    (tester) async {
      final container = await pumpLedgerly(tester, seed: seed);
      (container.read(
        nativePickersProvider,
      ) as FakeNativePickers).fileToReturn = r'D:\backup.db';
      await pressCtrl(tester, LogicalKeyboardKey.comma);

      await tester.ensureVisible(find.byKey(const Key('settings.restore')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.restore')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('settings.restoreConfirm.confirm')),
      );
      await tester.pumpAndSettle();

      final fake = container.read(restoreServiceProvider) as FakeBackupService;
      expect(fake.restoredPath, r'D:\backup.db');
      expect(find.textContaining('Restored'), findsOneWidget);
    },
    variant: windowsOnly,
  );

  testWidgets(
    'confirming restore of a file that does not exist shows the failure '
    'and leaves the app working',
    (tester) async {
      final container = await pumpLedgerly(tester, seed: seed);
      (container.read(
        nativePickersProvider,
      ) as FakeNativePickers).fileToReturn = r'D:\junk.db';
      (container.read(restoreServiceProvider) as FakeBackupService).rejectWith =
          'That file does not exist.';
      await pressCtrl(tester, LogicalKeyboardKey.comma);

      await tester.ensureVisible(find.byKey(const Key('settings.restore')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.restore')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('settings.restoreConfirm.confirm')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('does not exist'), findsOneWidget);
      final fake = container.read(restoreServiceProvider) as FakeBackupService;
      expect(fake.restoredPath, isNull); // validated and rejected first
    },
    variant: windowsOnly,
  );

  testWidgets(
    'picking a paired Bluetooth printer saves it and shows it as selected',
    (tester) async {
      final container = await pumpLedgerly(tester, seed: seed);
      final fakeThermal = container.read(
        thermalPrinterServiceProvider,
      ) as FakeThermalPrinterService;
      fakeThermal.paired = [
        const BluetoothPrinterInfo(name: 'MPT-II', mac: '00:11:22:33:44:55'),
      ];
      await pressCtrl(tester, LogicalKeyboardKey.comma);

      await tester.tap(find.byKey(const Key('settings.thermalPrinterPicker')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('MPT-II'));
      await tester.pumpAndSettle();

      expect(find.textContaining('MPT-II'), findsWidgets);
    },
    variant: windowsOnly,
  );

  testWidgets(
    'settings screen renders without overflow at phone width and the printer '
    'pickers stay reachable by touch',
    (tester) async {
      final container = await pumpLedgerly(
        tester,
        seed: seed,
        viewSize: const Size(390, 844),
      );
      container.read(routerProvider).go('/settings');
      await tester.pumpAndSettle();

      // Root cause: _field's hardcoded 130px label + 520px field forces a
      // 650px-wide Row on every settings row -- a hard RenderFlex overflow
      // at a ~346px content width, which also made both printer picker
      // buttons below unreachable by touch on the real device.
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.byKey(const Key('settings.choosePrinter')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.choosePrinter')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings.printerDialog')), findsOneWidget);
      await tester.tap(find.byKey(const Key('settings.printerOption.none')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('settings.thermalPrinterPicker')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.thermalPrinterPicker')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('settings.thermalPrinterDialog')),
        findsOneWidget,
      );
    },
    variant: phoneOnly,
  );

  testWidgets(
    'at phone width, the firm-name field stacks its label above the field '
    'instead of beside it',
    (tester) async {
      final container = await pumpLedgerly(
        tester,
        seed: seed,
        viewSize: const Size(390, 844),
      );
      container.read(routerProvider).go('/settings');
      await tester.pumpAndSettle();

      // Above kCompactBreakpoint the label sits in a fixed 130px SizedBox
      // beside the field; below it there is no such fixed-width column, so
      // the label's left edge and the field's left edge line up (a stacked
      // Column) instead of the field starting 130px to the right of it.
      final labelTopLeft = tester.getTopLeft(find.text('Firm name'));
      final fieldTopLeft = tester.getTopLeft(
        find.byKey(const Key('settings.firmName')),
      );
      expect(fieldTopLeft.dx, labelTopLeft.dx);
      expect(tester.takeException(), isNull);
    },
    variant: phoneOnly,
  );
}
