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
import 'package:ledgerly/features/encryption/encryption_service.dart';
import 'package:ledgerly/features/encryption/encryption_setup_screen.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly/features/settings/cloud_sync_providers.dart';
import 'package:ledgerly/features/settings/settings_providers.dart';
import 'package:ledgerly/platform/native_pickers.dart';
import 'package:ledgerly/printing/print_actions.dart';
import 'package:ledgerly/printing/printing_service.dart';
import 'package:ledgerly/printing/thermal_printer_service.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

/// Boots the real app against an in-memory database. Use together with
/// [windowsOnly] or [phoneOnly] so key handling and focus traversal behave as on the target OS. When [seed] is given it
/// runs before the first frame with an already-created firm, so the app opens
/// on the dashboard instead of the setup screen. [viewSize] sets the logical viewport size; defaults to desktop dimensions (1280×800).
/// The firm [pumpLedgerly] seeds. Tests that need to talk about the firm
/// before the app is pumped (putting it into the encrypted state, say) need
/// the same id the harness is about to use.
const testFirmId = '11111111-1111-4111-8111-111111111111';

Future<ProviderContainer> pumpLedgerly(
  WidgetTester tester, {
  Future<void> Function(AppDatabase db, DeviceContext ctx)? seed,
  Size viewSize = const Size(1280, 800),
  FakeEncryptionService? encryption,
  FakePlaintextBackupCleaner? backupCleaner,
}) async {
  // Every test opens its own in-memory database (plus FakeBackupService's
  // own throwaway one), which drift otherwise warns about as if it were the
  // production multi-database misuse it's meant to catch.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  tester.view.physicalSize = viewSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final prefs = InMemoryGlobalPrefs();
  const firmId = testFirmId;
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
    } on Object {
      // `on Object`, not `on Exception`: drift reports a closed connection as
      // a StateError ("Can't re-open a database after closing it"), which is
      // an Error, so `on Exception` silently never fired and this fake could
      // not actually reopen anything.
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
  final fakeThermal = FakeThermalPrinterService();
  final fakeRestoreService = FakeBackupService();
  final fakeHttp = FakeHttpClient();
  final fakeGoogleAuth = FakeGoogleAuthenticator();
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
      thermalPrinterServiceProvider.overrideWithValue(fakeThermal),
      restoreServiceProvider.overrideWithValue(fakeRestoreService),
      httpClientProvider.overrideWithValue(fakeHttp),
      googleAuthenticatorProvider.overrideWithValue(fakeGoogleAuth),
      databaseOpenerProvider.overrideWithValue(openDb),
      // Same reasoning as the fakes above: EncryptionService is all real file
      // I/O, which wedges the widget tester here. Its real behaviour --
      // envelopes, KDFs, the migration -- is proven end-to-end in
      // app/test/features/encryption/, which runs plain `test()` bodies.
      encryptionServiceProvider.overrideWithValue(
        encryption ?? FakeEncryptionService(),
      ),
      plaintextBackupCleanerProvider.overrideWithValue(
        backupCleaner ?? FakePlaintextBackupCleaner(),
      ),
    ],
  );
  addTearDown(() async {
    for (final d in opened) {
      // A test that exercised restoreFromPickedFile already closed its own
      // db as part of that flow — closing again here is a no-op either way.
      try {
        await d.close();
      } on Object {
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

/// Simulates the Android system back gesture / hardware back button: the
/// platform sends a `popRoute` navigation message, which the Router's
/// back-button dispatcher turns into `routerDelegate.popRoute()`. Nothing
/// else in a widget test exercises PopScope the way a real device does.
Future<void> systemBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await tester.pumpAndSettle();
}

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

/// Records connect/write/disconnect calls instead of touching real
/// Bluetooth hardware, which cannot run in an automated test either.
class FakeThermalPrinterService implements ThermalPrinterService {
  List<BluetoothPrinterInfo> paired = const [];
  String? connectedMac;
  final List<Uint8List> written = [];
  bool disconnected = false;

  /// Set to false to simulate a printer that's off/out of range/unpaired.
  bool connectSucceeds = true;

  /// Set to false to simulate a printer that connects but fails mid-job
  /// (out of paper, jammed, dropped mid-write).
  bool writeSucceeds = true;

  /// Set to simulate what the real plugin does when the adapter is off, the
  /// bond was dropped, or the Bluetooth permission was revoked: it throws a
  /// PlatformException rather than returning false.
  bool throwOnConnect = false;
  bool throwOnWrite = false;

  /// Set to simulate a disconnect that itself throws after a successful
  /// write -- the real plugin can fail to tear down the socket cleanly
  /// (adapter dropped mid-teardown, already-gone connection) even though
  /// the print itself went through.
  bool throwOnDisconnect = false;

  @override
  Future<List<BluetoothPrinterInfo>> pairedPrinters() async => paired;

  @override
  Future<bool> connect(String mac) async {
    connectedMac = mac;
    if (throwOnConnect) {
      throw PlatformException(code: 'BT_OFF', message: 'adapter is off');
    }
    return connectSucceeds;
  }

  @override
  Future<bool> writeBytes(Uint8List bytes) async {
    if (throwOnWrite) {
      throw PlatformException(code: 'BT_LOST', message: 'bond lost');
    }
    written.add(bytes);
    return writeSucceeds;
  }

  @override
  Future<void> disconnect() async {
    disconnected = true;
    if (throwOnDisconnect) {
      throw PlatformException(code: 'BT_TEARDOWN', message: 'teardown failed');
    }
  }
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

  /// The key the restore was actually performed with — null for a backup
  /// keyed like this session, the backup's own unwrapped key for one that
  /// came with its own envelope.
  List<int>? restoredWithKey;
  List<int>? validatedWithKey;

  /// Set to reject the next validation, the way a real corrupt or missing
  /// file would, without ever touching a real file.
  String? rejectWith;

  /// Set to the path of the envelope a picked backup arrived with. Overriding
  /// [pairedEnvelopeOf] rather than letting the real one stat the disk is
  /// what keeps this out of the filesystem in a widget test.
  String? pairedEnvelopePath;

  /// What a picked backup's bytes look like, for the "encrypted backup with
  /// no envelope beside it" message.
  bool ciphertext = false;

  @override
  File? pairedEnvelopeOf(File backupFile) =>
      pairedEnvelopePath == null ? null : File(pairedEnvelopePath!);

  @override
  bool isCiphertext(File backupFile) => ciphertext;

  @override
  void validateBackup(File backupFile, {List<int>? withKey}) {
    validatedWithKey = withKey;
    if (rejectWith case final message?) {
      throw InvalidBackupException(message);
    }
  }

  @override
  Future<File> restoreFrom(File backupFile, {List<int>? withKey}) async {
    validateBackup(backupFile, withKey: withKey);
    restoredPath = backupFile.path;
    restoredWithKey = withKey;
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

/// Stands in for [GoogleAuthenticator] in widget tests: no real platform
/// channel call (flutter_tester has no Google Sign-In implementation
/// registered for it, the same reasoning [FakeHttpClient] exists for). Set
/// [idToken] to the value the fake interactive sign-in should hand back;
/// left null, it reproduces a flow that completed without one (cancelled
/// picker), which [CloudSessionNotifier.signInWithGoogle] turns into a
/// thrown StateError -- the same "fails loudly on the unconfigured case"
/// shape as [FakeHttpClient]'s default handler.
class FakeGoogleAuthenticator implements GoogleAuthenticator {
  String? idToken;

  @override
  Future<String?> signIn() async => idToken;
}

/// Stands in for [EncryptionService] in widget tests: the same method
/// contract, the same fail-closed answers, but envelopes held in a map
/// instead of on disk. Real file I/O from a `testWidgets` body hangs in this
/// environment (same reason [FakeBackupService] exists), and the crypto
/// itself is already proven against real files by
/// `app/test/features/encryption/encryption_service_test.dart` and
/// `encryption_migration_test.dart`. What a widget test needs from here is
/// which method the UI called, with which arguments, and what it did with
/// the answer — so every call is recorded.
class FakeEncryptionService extends EncryptionService {
  FakeEncryptionService()
    : super(paths: AppPaths(Directory('ledgerly-test-paths-unused')));

  final _envelopes = <String, _FakeEnvelope>{};

  /// Every `(firmId, masterKey)` pair [retirePreEncryptionCopy] was called
  /// with — the Task 6 obligation this task had to wire into firm-open.
  final retiredCopies = <({String firmId, Uint8List masterKey})>[];

  /// Every firm id [recoverInterruptedMigration] was asked about.
  final recoveryChecks = <String>[];

  /// Every firm id migrated from plaintext through [migrateToEncrypted].
  final migrations = <String>[];

  /// Set to make [retirePreEncryptionCopy] fail the way the real one does
  /// when the live database will not verify under the key it was handed.
  Object? retireFailure;

  /// Set to make [changePassphrase] fail the way the real one does when the
  /// envelope it is rewriting has gone.
  Object? changePassphraseFailure;

  /// What [recoverInterruptedMigration] should report. Set this to
  /// [RecoveryOutcome.indeterminate] to exercise the unverifiable state.
  RecoveryOutcome recoveryOutcome = RecoveryOutcome.nothingToRecover;

  var _counter = 0;
  Uint8List _bytes(int length) => Uint8List.fromList(
    List.generate(length, (i) => (++_counter * 31 + i) % 256),
  );

  /// Puts a firm into the encrypted state without going through the UI, for
  /// tests about unlocking rather than about setup.
  String encryptNow(String firmId, {required String passphrase}) {
    final code = encodeRecoveryCode(_bytes(32));
    _envelopes[firmId] = _FakeEnvelope(
      passphrase: passphrase,
      recoveryCode: code,
      masterKey: _bytes(32),
    );
    return code;
  }

  Uint8List masterKeyOf(String firmId) => _envelopes[firmId]!.masterKey;

  /// Envelopes addressed by FILE rather than by firm: the sidecar that
  /// travelled beside a backup, which is the only thing that can open it
  /// once that backup is somewhere this device's key means nothing.
  final _envelopesByPath = <String, _FakeEnvelope>{};

  /// Puts a backup's own envelope at [envelopePath] and returns the master
  /// key it wraps, so a test can assert the restore used exactly that key.
  ({Uint8List masterKey, String recoveryCode}) enrolBackupEnvelope(
    String envelopePath, {
    required String passphrase,
  }) {
    final code = encodeRecoveryCode(_bytes(32));
    final key = _bytes(32);
    _envelopesByPath[envelopePath] = _FakeEnvelope(
      passphrase: passphrase,
      recoveryCode: code,
      masterKey: key,
    );
    return (masterKey: key, recoveryCode: code);
  }

  @override
  Future<Uint8List?> unlockEnvelopeWithPassphrase(
    File envelopeFile,
    String passphrase,
  ) async {
    final envelope = _envelopesByPath[envelopeFile.path];
    if (envelope == null || envelope.passphrase != passphrase) return null;
    return Uint8List.fromList(envelope.masterKey);
  }

  @override
  Future<Uint8List?> unlockEnvelopeWithRecoveryCode(
    File envelopeFile,
    String recoveryCode,
  ) async {
    final envelope = _envelopesByPath[envelopeFile.path];
    if (envelope == null || envelope.recoveryCode != recoveryCode) return null;
    return Uint8List.fromList(envelope.masterKey);
  }

  @override
  Future<bool> isEncrypted(String firmId) async =>
      _envelopes.containsKey(firmId);

  @override
  Future<void> enableEncryption(
    String firmId, {
    required String passphrase,
    required void Function(String recoveryCode) onRecoveryCodeGenerated,
  }) async =>
      onRecoveryCodeGenerated(encryptNow(firmId, passphrase: passphrase));

  @override
  Future<void> migrateToEncrypted(
    String firmId, {
    required String passphrase,
    required void Function(String recoveryCode) onRecoveryCodeGenerated,
  }) async {
    if (_envelopes.containsKey(firmId)) {
      throw StateError('Firm $firmId is already encrypted');
    }
    migrations.add(firmId);
    onRecoveryCodeGenerated(encryptNow(firmId, passphrase: passphrase));
  }

  @override
  Future<Uint8List?> unlockWithPassphrase(
    String firmId,
    String passphrase,
  ) async {
    final envelope = _envelopes[firmId];
    if (envelope == null || envelope.passphrase != passphrase) return null;
    // A COPY, because the real unwrapKey returns freshly allocated bytes
    // every time -- a caller that zeroes what it was handed (the Settings
    // dialogs do) must not be zeroing the envelope's own key.
    return Uint8List.fromList(envelope.masterKey);
  }

  @override
  Future<Uint8List?> unlockWithRecoveryCode(
    String firmId,
    String recoveryCode,
  ) async {
    final envelope = _envelopes[firmId];
    // Deliberately an exact string comparison, mirroring the real service:
    // the KDF there hashes the code as typed, so a code entered in a
    // different case or spacing derives a different wrapping key and fails.
    // A UI that does not canonicalise first fails here exactly as it would
    // against the real thing.
    if (envelope == null || envelope.recoveryCode != recoveryCode) return null;
    return Uint8List.fromList(envelope.masterKey);
  }

  @override
  Future<void> changePassphrase(
    String firmId, {
    required Uint8List masterKey,
    required String newPassphrase,
  }) async {
    final envelope = _envelopes[firmId];
    if (envelope == null) throw StateError('No envelope for firm $firmId');
    if (!_sameKey(envelope.masterKey, masterKey)) {
      throw StateError('changePassphrase called with the wrong master key');
    }
    if (changePassphraseFailure case final failure?) throw failure;
    _envelopes[firmId] = envelope.withPassphrase(newPassphrase);
  }

  @override
  Future<String> rotateRecoveryCode(
    String firmId, {
    required Uint8List masterKey,
  }) async {
    final envelope = _envelopes[firmId];
    if (envelope == null) throw StateError('No envelope for firm $firmId');
    if (!_sameKey(envelope.masterKey, masterKey)) {
      throw StateError('rotateRecoveryCode called with the wrong master key');
    }
    final code = encodeRecoveryCode(_bytes(32));
    _envelopes[firmId] = envelope.withRecoveryCode(code);
    return code;
  }

  @override
  Future<RecoveryOutcome> recoverInterruptedMigration(String firmId) async {
    recoveryChecks.add(firmId);
    return recoveryOutcome;
  }

  @override
  Future<void> retirePreEncryptionCopy(
    String firmId,
    Uint8List masterKey,
  ) async {
    retiredCopies.add((firmId: firmId, masterKey: masterKey));
    if (retireFailure case final failure?) throw failure;
  }

  static bool _sameKey(Uint8List a, Uint8List b) =>
      a.length == b.length && !a.indexed.any((e) => b[e.$1] != e.$2);
}

class _FakeEnvelope {
  _FakeEnvelope({
    required this.passphrase,
    required this.recoveryCode,
    required this.masterKey,
  });
  final String passphrase;
  final String recoveryCode;
  final Uint8List masterKey;

  _FakeEnvelope withPassphrase(String next) => _FakeEnvelope(
    passphrase: next,
    recoveryCode: recoveryCode,
    masterKey: masterKey,
  );
  _FakeEnvelope withRecoveryCode(String next) => _FakeEnvelope(
    passphrase: passphrase,
    recoveryCode: next,
    masterKey: masterKey,
  );
}

/// Lists and deletes nothing real — the plaintext backups a migration leaves
/// behind, without a directory to scan or a file to unlink.
class FakePlaintextBackupCleaner extends PlaintextBackupCleaner {
  FakePlaintextBackupCleaner({List<String>? files})
    : files = files ?? [],
      super(directories: const []);

  List<String> files;
  var deleteCalls = 0;

  @override
  List<File> find(String firmId) => files.map(File.new).toList();

  @override
  Future<void> delete(List<File> backups) async {
    deleteCalls++;
    files = [];
  }
}
