import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bootstrap/providers.dart';
import '../features/settings/cloud_sync_providers.dart';

/// Whether the device has a network path at all -- Wi-Fi or mobile data is
/// up. NOT proof the internet works (a captive portal is "online" here): the
/// push itself is the real test, and a failed one just waits for the next
/// trigger, since nothing leaves the outbox until the server acks it.
abstract class NetworkMonitor {
  Future<bool> isOnline();

  /// Emits on every connectivity change, true when there is a network path.
  Stream<bool> get onlineChanges;
}

class RealNetworkMonitor implements NetworkMonitor {
  final _connectivity = Connectivity();

  static bool _online(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async =>
      _online(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onlineChanges =>
      _connectivity.onConnectivityChanged.map(_online);
}

final networkMonitorProvider = Provider<NetworkMonitor>(
  (ref) => RealNetworkMonitor(),
);

const autoSyncInterval = Duration(minutes: 5);

/// The every-[autoSyncInterval] beat, behind a seam so a widget test can
/// tick it by hand rather than leave a real periodic timer running.
abstract class SyncTicker {
  Stream<void> get ticks;
}

class RealSyncTicker implements SyncTicker {
  @override
  Stream<void> get ticks => Stream<void>.periodic(autoSyncInterval);
}

final syncTickerProvider = Provider<SyncTicker>((ref) => RealSyncTicker());

/// The automatic sync triggers (docs/design-spec.md Section 4): every save
/// while online, network regained, every [autoSyncInterval] while online,
/// the app coming back to the foreground, and right after sign-in. Active
/// only while a firm is open AND a cloud session exists; signing out or
/// closing the firm tears every trigger down. Each one just calls
/// [SyncRunner.syncNow], whose single-flight turns a burst of triggers into
/// one run plus at most one follow-up.
class AutoSync extends Notifier<void> {
  @override
  void build() {
    final firm = ref.watch(openFirmProvider).value;
    final signedIn = ref.watch(cloudSessionProvider.select((s) => s != null));
    if (firm == null || !signedIn) return;

    final db = firm.db;
    final subscriptions = <StreamSubscription<Object?>>[
      // Inserts only: every save enqueues through an insert, while the sync
      // itself only ever deletes (an ack) or updates (a reject/re-stamp)
      // outbox rows -- so a sync can never trigger the next one.
      db
          .tableUpdates(
            TableUpdateQuery.onTable(
              db.syncOutbox,
              limitUpdateKind: UpdateKind.insert,
            ),
          )
          .listen((_) => _syncIfOnline()),
      ref.read(syncTickerProvider).ticks.listen((_) => _syncIfOnline()),
      ref
          .read(networkMonitorProvider)
          .onlineChanges
          .where((online) => online)
          .listen((_) => _sync()),
    ];
    // Android stops Dart timers while the app is in the background, so the
    // periodic tick alone could leave a returning user's data unsynced.
    final lifecycle = AppLifecycleListener(onResume: _syncIfOnline);
    ref.onDispose(() {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
      lifecycle.dispose();
    });

    // Just signed in, or just opened a signed-in firm: don't wait for a
    // trigger to catch up on what changed elsewhere.
    _syncIfOnline();
  }

  Future<void> _syncIfOnline() async {
    if (await ref.read(networkMonitorProvider).isOnline()) await _sync();
  }

  Future<void> _sync() async {
    // A trigger that was already on its way when sign-out or a firm switch
    // tore this down must not reach for a disposed ref.
    if (!ref.mounted) return;
    await ref.read(syncRunnerProvider.notifier).syncNow();
  }
}

final autoSyncProvider = NotifierProvider<AutoSync, void>(AutoSync.new);
