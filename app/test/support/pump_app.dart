import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ledgerly/app.dart';

import 'package:ledgerly/bootstrap/app_paths.dart';
import 'package:ledgerly/bootstrap/global_prefs.dart';
import 'package:ledgerly/bootstrap/providers.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly/features/settings/cloud_sync_providers.dart';
import 'package:ledgerly/features/settings/settings_providers.dart';
import 'package:ledgerly/platform/native_pickers.dart';
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
  Size viewSize = const Size(1280, 800),
}) async {
  // Every test opens its own in-memory database (plus FakeBackupService's
  // own throwaway one), which drift otherwise warns about as if it were the
  // production multi-database misuse it's meant to catch.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  tester.view.physicalSize = viewSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final prefs = InMemoryGlobalPrefs();
  const firmId = '11111111-1111-4111-8111-111111111111';
  var clock = 1000;
  DeviceContext makeCtx() => DeviceContext(
    firmId: firmId,
    deviceId: prefs.deviceId,
    deviceShortCode: deviceShortCode(prefs.deviceId),
    userId: '33333333-3333-4333-8333-333333333333',
    hlc: Hlc(clock: () => clock++),
  );
  // A real reopen (production's databaseOpenerProvider) always returns a
  // working connection to the same file, whether that's the connection
  // opened moments ago (first-launch wizard's create → invalidate) or a
  // brand new one after a restore replaced the file. This stand-in mirrors
  // both cases without ever touching disk: it hands back the same
  // in-memory database while it is still open, and only opens (and, when a
  // seed was given, reseeds) a fresh one once the old one has been closed —
  // which restoreFromPickedFile does deliberately, to release the file
  // before copying over it.
  var db = AppDatabase(NativeDatabase.memory());
  final opened = <AppDatabase>[db];
  Future<AppDatabase> openDb(String _) async {
    try {
      await db.customSelect('SELECT 1').getSingle();
      return db;
    } on Exception {
      db = AppDatabase(NativeDatabase.memory());
      opened.add(db);
      if (seed != null) await seed(db, makeCtx());
      return db;
    }
  }

  if (seed != null) {
    await seed(db, makeCtx());
    await prefs.setLastFirmId(firmId);
  }
  // Real filesystem writes from the flutter_tester binary hang in this
  // sandboxed CI environment (proven by direct probing), so tests never touch
  // disk: AppPaths points somewhere inert, and the backup runner and restore
  // service are faked. BackupService's real file behaviour is already tested
  // end-to-end in packages/ledgerly_data/test/backup_service_test.dart via
  // plain `dart test`.
  final fakePrinting = FakePrintingService();
  final fakePickers = FakeNativePickers();
  final fakePrinterDiscovery = FakePrinterDiscovery();
  final fakeRestoreService = FakeBackupService();
  final fakeHttp = FakeHttpClient();
  final container = ProviderContainer(
    overrides: [
      globalPrefsProvider.overrideWithValue(prefs),
      appPathsProvider.overrideWithValue(
        AppPaths(Directory('ledgerly-test-paths-unused')),
      ),
      backupRunnerProvider.overrideWith(FakeBackupRunner.new),
      printingServiceProvider.overrideWithValue(fakePrinting),
      nativePickersProvider.overrideWithValue(fakePickers),
      printerDiscoveryProvider.overrideWithValue(fakePrinterDiscovery),
      restoreServiceProvider.overrideWithValue(fakeRestoreService),
      httpClientProvider.overrideWithValue(fakeHttp),
      databaseOpenerProvider.overrideWithValue(openDb),
    ],
  );
  addTearDown(() async {
    for (final d in opened) {
      // A test that exercised restoreFromPickedFile already closed its own
      // db as part of that flow — closing again here is a no-op either way.
      try {
        await d.close();
      } on Exception {
        // already closed
      }
    }
  });
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const LedgerlyApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

final windowsOnly = TargetPlatformVariant.only(TargetPlatform.windows);
final phoneOnly = TargetPlatformVariant.only(TargetPlatform.android);

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

/// Records what was requested and returns a pre-set answer instead of
/// opening a real OS folder/file dialog.
class FakeNativePickers implements NativePickers {
  String? folderToReturn;
  String? fileToReturn;
  int folderPickCount = 0;
  int filePickCount = 0;

  @override
  Future<String?> pickFolder() async {
    folderPickCount++;
    return folderToReturn;
  }

  @override
  Future<String?> pickFile({
    required List<String> extensions,
    required String label,
  }) async {
    filePickCount++;
    return fileToReturn;
  }
}

/// A fixed, settable printer list instead of the real OS enumeration, which
/// cannot run in an automated test either.
class FakePrinterDiscovery implements PrinterDiscovery {
  List<PrinterInfo> printers = const [];

  @override
  Future<List<PrinterInfo>> list() async => printers;
}

/// Records what restore was asked to do instead of touching a real backup
/// file — real disk I/O cannot run in an automated test here either.
class FakeBackupService extends BackupService {
  FakeBackupService()
    : super(
        db: AppDatabase(NativeDatabase.memory()),
        databaseFile: File('unused'),
        localBackupDir: Directory('unused'),
      );

  String? restoredPath;

  /// Set to reject the next validation, the way a real corrupt or missing
  /// file would, without ever touching a real file.
  String? rejectWith;

  @override
  void validateBackup(File backupFile) {
    if (rejectWith case final message?) {
      throw InvalidBackupException(message);
    }
  }

  @override
  Future<File> restoreFrom(File backupFile) async {
    validateBackup(backupFile);
    restoredPath = backupFile.path;
    return File('unused-pre-restore-copy');
  }
}

/// Stands in for the phase-2 backend — a real socket from the
/// flutter_tester binary is exactly the kind of OS call that hangs in this
/// project's sandboxed environment, same reasoning as printing and file
/// pickers. Defaults to throwing on any request, so a test that forgets to
/// set [handler] fails loudly instead of hanging or silently doing nothing.
class FakeHttpClient extends http.BaseClient {
  Future<http.Response> Function(http.BaseRequest request) handler =
      (request) async => throw StateError(
        'FakeHttpClient: unexpected ${request.method} ${request.url}',
      );

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}
