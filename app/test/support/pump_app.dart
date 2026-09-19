import 'package:drift/native.dart';

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app.dart';

import 'package:ledgerly/bootstrap/app_paths.dart';
import 'package:ledgerly/bootstrap/global_prefs.dart';
import 'package:ledgerly/bootstrap/providers.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly/features/settings/settings_providers.dart';
import 'package:ledgerly/printing/print_actions.dart';
import 'package:ledgerly/printing/printing_service.dart';
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
  // Real filesystem writes from the flutter_tester binary hang in this
  // sandboxed CI environment (proven by direct probing), so tests never touch
  // disk: AppPaths points somewhere inert, and the backup runner is faked.
  // BackupService's real file behaviour is already tested end-to-end in
  // packages/ledgerly_data/test/backup_service_test.dart via plain `dart test`.
  final fakePrinting = FakePrintingService();
  final container = ProviderContainer(
    overrides: [
      globalPrefsProvider.overrideWithValue(prefs),
      appPathsProvider.overrideWithValue(
        AppPaths(Directory('ledgerly-test-paths-unused')),
      ),
      backupRunnerProvider.overrideWith(FakeBackupRunner.new),
      printingServiceProvider.overrideWithValue(fakePrinting),
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

/// Stands in for [BackupRunner] in widget tests: no ref.listen auto-trigger
/// on firm-open, no real disk access. BackupService's real behaviour is
/// covered in the data package; this only fakes the state a UI test needs.
class FakeBackupRunner extends BackupRunner {
  @override
  BackupStatus build() => const BackupStatus();

  @override
  Future<void> runNow() async {
    state = BackupStatus(lastAt: DateTime.now());
  }

  @override
  Future<void> runIfDue() async {}
}

/// Records every call instead of touching a real printer or save dialog —
/// the OS side of printing cannot be exercised inside an automated test.
class FakePrintingService implements PrintingService {
  final List<String> printedJobs = [];
  final List<String> exportedPdfNames = [];
  final List<String> exportedPngBaseNames = [];
  bool exportPdfResult = true;
  int exportPngPageCount = 1;

  @override
  Future<void> print(Uint8List pdfBytes, {required String jobName}) async {
    printedJobs.add(jobName);
  }

  @override
  Future<bool> exportPdf(
    Uint8List pdfBytes, {
    required String suggestedName,
  }) async {
    exportedPdfNames.add(suggestedName);
    return exportPdfResult;
  }

  @override
  Future<int> exportPng(
    Uint8List pdfBytes, {
    required String suggestedBaseName,
  }) async {
    exportedPngBaseNames.add(suggestedBaseName);
    return exportPngPageCount;
  }
}
