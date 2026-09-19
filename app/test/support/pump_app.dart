import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app.dart';
import 'package:ledgerly/bootstrap/global_prefs.dart';
import 'package:ledgerly/bootstrap/providers.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

/// Boots the real app against an in-memory database. Use together with
/// [windowsOnly] so key handling and focus traversal behave as on the target OS. When [seed] is given it
/// runs before the first frame with an already-created firm, so the app opens
/// on the dashboard instead of the setup screen.
Future<ProviderContainer> pumpLedgerly(
  WidgetTester tester, {
  Future<void> Function(AppDatabase db, DeviceContext ctx)? seed,
}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final prefs = InMemoryGlobalPrefs();
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  var clock = 1000;
  final ctx = DeviceContext(
    firmId: '11111111-1111-4111-8111-111111111111',
    deviceId: prefs.deviceId,
    deviceShortCode: deviceShortCode(prefs.deviceId),
    userId: '33333333-3333-4333-8333-333333333333',
    hlc: Hlc(clock: () => clock++),
  );
  if (seed != null) {
    await seed(db, ctx);
    await prefs.setLastFirmId(ctx.firmId);
  }
  final container = ProviderContainer(
    overrides: [
      globalPrefsProvider.overrideWithValue(prefs),
      databaseOpenerProvider.overrideWithValue((firmId) async => db),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const LedgerlyApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

final windowsOnly = TargetPlatformVariant.only(TargetPlatform.windows);

Future<void> pressCtrl(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(
    LogicalKeyboardKey.controlLeft,
    platform: 'windows',
  );
  await tester.sendKeyEvent(key, platform: 'windows');
  await tester.sendKeyUpEvent(
    LogicalKeyboardKey.controlLeft,
    platform: 'windows',
  );
  await tester.pumpAndSettle();
}
