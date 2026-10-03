import 'package:flutter/gestures.dart';
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

  testWidgets(
    'two options with the same label are both offered, and picking the '
    'second reports the second -- two customers can share a name',
    (tester) async {
      (int, String)? picked;
      await tester.pumpWidget(
        MaterialApp(
          theme: ledgerlyTheme(Brightness.light),
          home: Scaffold(
            body: EntityAutocomplete<(int, String)>(
              fieldKey: const Key('ac'),
              options: const [(1, 'Ali'), (2, 'Bilal'), (3, 'Ali')],
              labelOf: (o) => o.$2,
              trailingOf: (o) => '#${o.$1}',
              onSelected: (o) => picked = o,
              autofocus: true,
            ),
          ),
        ),
      );
      await tester.enterText(find.byKey(const Key('ac')), 'ali');
      await tester.pumpAndSettle();
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);

      await tester.tap(find.text('#3'));
      await tester.pumpAndSettle();
      expect(picked, (3, 'Ali'));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'on desktop, clicking a suggestion with the mouse picks it -- the click '
    'used to unfocus the field first, emptying the list under the pointer',
    (tester) async {
      String? picked;
      await tester.pumpWidget(
        MaterialApp(
          theme: ledgerlyTheme(Brightness.light),
          home: Scaffold(
            body: EntityAutocomplete<String>(
              fieldKey: const Key('ac'),
              options: const ['Rashid Traders', 'Karim Store'],
              labelOf: (s) => s,
              onSelected: (s) => picked = s,
              autofocus: true,
            ),
          ),
        ),
      );
      await tester.enterText(find.byKey(const Key('ac')), 'kar');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Karim Store'), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(picked, 'Karim Store');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}
