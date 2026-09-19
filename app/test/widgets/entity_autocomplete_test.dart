import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/bills/widgets/entity_autocomplete.dart';
import 'package:ledgerly/theme/ledgerly_theme.dart';

void main() {
  testWidgets(
    'typing shows fuzzy matches; Enter picks the highlighted one and reports it',
    (tester) async {
      String? picked;
      await tester.pumpWidget(
        MaterialApp(
          theme: ledgerlyTheme(Brightness.light),
          home: Scaffold(
            body: EntityAutocomplete<String>(
              fieldKey: const Key('ac'),
              options: const ['Rashid Traders', 'Rasheed Bros', 'Karim Store'],
              labelOf: (s) => s,
              onSelected: (s) => picked = s,
              autofocus: true,
            ),
          ),
        ),
      );
      await tester.enterText(find.byKey(const Key('ac')), 'rash');
      await tester.pumpAndSettle();
      expect(find.text('Rasheed Bros'), findsOneWidget);
      expect(find.text('Karim Store'), findsNothing);

      await tester.sendKeyEvent(
        LogicalKeyboardKey.arrowDown,
        platform: 'windows',
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter, platform: 'windows');
      await tester.pumpAndSettle();
      expect(picked, 'Rasheed Bros');
      expect(find.text('Karim Store'), findsNothing);
      expect(find.text('Rashid Traders'), findsNothing); // list closed
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}
