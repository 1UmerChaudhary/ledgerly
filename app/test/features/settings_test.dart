import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
