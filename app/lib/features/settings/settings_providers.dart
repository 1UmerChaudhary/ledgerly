import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../../bootstrap/providers.dart';

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
