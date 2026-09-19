import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import 'ledger_screen_test.dart' show seedLedger;

void main() {
  testWidgets(
    'F2 on a bill opens the form prefilled; changing a rate and saving writes v3 and updates the ledger',
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
      await tester.sendKeyEvent(LogicalKeyboardKey.f2, platform: 'windows');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bill.screen')), findsOneWidget);
      expect(find.text('EDIT SALE'), findsOneWidget);
      // Prefilled from the saved bill (v2: oilcake rate 2,400).
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('bill.line.1.rate')),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        '2,400',
      );
      expect(find.text('Rs 1,97,162'), findsOneWidget);

      await tester.tap(find.byKey(const Key('bill.line.1.rate')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('bill.line.1.rate')), '2500');
      await tester.pumpAndSettle();
      expect(find.text('Rs 2,02,162'), findsOneWidget);

      await pressCtrl(tester, LogicalKeyboardKey.enter);
      expect(find.byKey(const Key('bill.saved')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape, platform: 'windows');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ledger.screen')), findsOneWidget);
      expect(
        find.text('Rs 3,22,162'),
        findsOneWidget,
      ); // 2,20,000 − 1,00,000 + 2,02,162
      expect(
        find.descendant(
          of: find.byKey(const Key('ledger.detail')),
          matching: find.textContaining('v3'),
        ),
        findsWidgets,
      );
    },
    variant: windowsOnly,
  );
}
