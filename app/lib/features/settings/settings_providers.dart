import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../../bootstrap/providers.dart';
import '../../platform/native_pickers.dart';
import '../../printing/printing_service.dart';

/// Firm-level settings (name on the title bar, paisa on/off, digit grouping).
final firmSettingsProvider = FutureProvider<Firm?>((ref) async {
  final firm = await ref.watch(openFirmProvider.future);
  if (firm == null) return null;
  return FirmsRepository(firm.db, firm.ctx).get();
});

typedef MoneyFormatter = String Function(Money amount, {bool symbol});

/// Every screen formats money through this so the firm's display choices
/// apply everywhere at once.
final moneyFormatProvider = Provider<MoneyFormatter>((ref) {
  final firm = ref.watch(firmSettingsProvider).value;
  final showPaisa = firm?.showPaisa ?? false;
  final grouping = firm?.grouping ?? NumberGrouping.pakistani;
  return (Money amount, {bool symbol = true}) => formatMoney(
    amount,
    showPaisa: showPaisa,
    grouping: grouping,
    symbol: symbol,
  );
});

final backupServiceProvider = Provider<BackupService?>((ref) {
  final firm = ref.watch(openFirmProvider).value;
  if (firm == null) return null;
  final paths = ref.watch(appPathsProvider);
  final folder = ref.watch(backupFolderProvider);
  return BackupService(
    db: firm.db,
    databaseFile: paths.firmDatabase(firm.ctx.firmId),
    localBackupDir: paths.backups,
    userBackupDir: folder == null ? null : Directory(folder),
    now: () => DateTime.now(),
  );
});

/// The user's chosen backup folder (a USB drive or a cloud-synced folder).
class BackupFolder extends Notifier<String?> {
  @override
  String? build() => ref.watch(globalPrefsProvider).backupFolder;

  Future<void> set(String? path) async {
    final clean = (path ?? '').trim();
    await ref
        .read(globalPrefsProvider)
        .setBackupFolder(clean.isEmpty ? null : clean);
    state = clean.isEmpty ? null : clean;
  }
}

final backupFolderProvider = NotifierProvider<BackupFolder, String?>(
  BackupFolder.new,
);

class BackupStatus {
  const BackupStatus({this.lastAt, this.error, this.running = false});
  final DateTime? lastAt;
  final String? error;
  final bool running;
}

/// Runs backups (on demand and, once per open, when one is due) and remembers
/// the result for the title bar.
class BackupRunner extends Notifier<BackupStatus> {
  @override
  BackupStatus build() {
    // Registered once, when this provider is first created — NOT inside a
    // widget's build() (Riverpod would otherwise add one listener per
    // rebuild). Runs the once-per-session "is a backup due" check the moment
    // a firm's database is open.
    ref.listen(openFirmProvider, (prev, next) {
      if (next.value != null && prev?.value == null) {
        runIfDue();
      }
    });
    return const BackupStatus();
  }

  Future<void> runNow() async {
    final service = ref.read(backupServiceProvider);
    if (service == null) return;
    state = BackupStatus(lastAt: state.lastAt, running: true);
    try {
      final result = await service.backupNow();
      state = BackupStatus(lastAt: DateTime.now(), error: result.userCopyError);
    } on Exception catch (e) {
      state = BackupStatus(lastAt: state.lastAt, error: 'Backup failed: $e');
    }
  }

  Future<void> runIfDue() async {
    final service = ref.read(backupServiceProvider);
    if (service != null && await service.isDue()) await runNow();
  }
}

final backupRunnerProvider = NotifierProvider<BackupRunner, BackupStatus>(
  BackupRunner.new,
);

final nativePickersProvider = Provider<NativePickers>(
  (ref) => RealNativePickers(),
);

/// The saved default printer, for silent printing and for the Settings
/// display. Kept as one small record so choosing and clearing are one write.
class PrinterChoice extends Notifier<PrinterInfo?> {
  @override
  PrinterInfo? build() {
    final prefs = ref.watch(globalPrefsProvider);
    final name = prefs.printerName;
    final url = prefs.printerUrl;
    return (name == null || url == null)
        ? null
        : PrinterInfo(name: name, url: url);
  }

  Future<void> set(PrinterInfo? printer) async {
    await ref
        .read(globalPrefsProvider)
        .setPrinter(name: printer?.name, url: printer?.url);
    state = printer;
  }
}

final printerChoiceProvider = NotifierProvider<PrinterChoice, PrinterInfo?>(
  PrinterChoice.new,
);

enum RestoreOutcome { success, cancelled }

class RestoreFailure implements Exception {
  RestoreFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The service that performs the actual restore, built from the open firm.
/// A separate provider (rather than constructing `BackupService` inline)
/// so tests can substitute one that never touches a real file.
final restoreServiceProvider = Provider<BackupService>((ref) {
  final firm = ref.watch(openFirmProvider).value;
  if (firm == null) {
    throw StateError('restoreServiceProvider read with no firm open');
  }
  final paths = ref.watch(appPathsProvider);
  return BackupService(
    db: firm.db,
    databaseFile: paths.firmDatabase(firm.ctx.firmId),
    localBackupDir: paths.backups,
  );
});

/// Restores the open firm's database from a backup file the user picks and
/// confirms. The picked file is validated first, before anything about the
/// live firm is touched — an invalid file is rejected with the app left
/// exactly as it was. Only a valid backup causes the live connection to
/// close (SQLite must not have the file open while it is replaced) and a
/// fresh one to open afterwards, by invalidating [openFirmProvider] — no
/// app relaunch needed.
Future<RestoreOutcome> restoreFromPickedFile(
  WidgetRef ref, {
  required Future<bool> Function(String path) confirm,
}) async {
  final firm = ref.read(openFirmProvider).value;
  if (firm == null) return RestoreOutcome.cancelled;
  final path = await ref
      .read(nativePickersProvider)
      .pickFile(extensions: const ['db'], label: 'Ledgerly backup');
  if (path == null) return RestoreOutcome.cancelled;
  if (!await confirm(path)) return RestoreOutcome.cancelled;

  final service = ref.read(restoreServiceProvider);
  try {
    service.validateBackup(File(path));
  } on InvalidBackupException catch (e) {
    throw RestoreFailure(e.message);
  }

  await firm.db.close();
  await service.restoreFrom(File(path)); // re-validates; the file cannot
  // have changed between the check above and here within one user action.
  ref.invalidate(openFirmProvider);
  return RestoreOutcome.success;
}
