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
/// while online, the network coming back, every [autoSyncInterval] while
/// online, the app returning to the foreground, and whenever a signed-in
/// firm opens (sign-in, app start, unlock, restore). Active only while the
/// app shell is up, a firm is fully open AND a cloud session exists; any
/// change to those rebuilds or disposes this, cancelling every trigger
/// first. Each trigger just calls [SyncRunner.syncNow], whose single-flight
/// turns a burst of triggers into one run plus at most one follow-up.
class AutoSync extends Notifier<void> {
  /// "Resumed" fires on every alt-tab back to the window on desktop; without
  /// this, flicking between windows would sync each time.
  static const resumeQuietPeriod = Duration(minutes: 1);

  @override
  void build() {
    final session = ref.watch(cloudSessionProvider.select((s) => s != null));
    // Not `.value` alone: while openFirmProvider reloads (restore, lock,
    // enabling encryption) it still hands back the previous firm, whose
    // database is already closed. Wait for the reload to settle instead.
    final firmState = ref.watch(openFirmProvider);
    final firm = firmState.isLoading ? null : firmState.value;
    if (firm == null || !session) return;

    final db = firm.db;
    bool? wasOnline;
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
          .listen((_) => unawaited(_syncIfOnline())),
      ref
          .read(syncTickerProvider)
          .ticks
          .listen((_) => unawaited(_syncIfOnline())),
      // Only offline -> online counts. The plugin reports the current state
      // the moment it's subscribed to, and Wi-Fi -> mobile data reports
      // "online" again; neither is the network coming back.
      ref.read(networkMonitorProvider).onlineChanges.listen((online) {
        final regained = online && wasOnline == false;
        wasOnline = online;
        if (regained) unawaited(_sync());
      }),
    ];
    // Android stops Dart timers while the app is in the background, so the
    // periodic tick alone could leave a returning user's data unsynced.
    final lifecycle = AppLifecycleListener(onResume: _onResume);
    ref.onDispose(() {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
      lifecycle.dispose();
    });

    unawaited(_syncIfOnline());
  }

  void _onResume() {
    final lastAt = ref.read(syncRunnerProvider).lastAt;
    if (lastAt != null &&
        DateTime.now().difference(lastAt) < resumeQuietPeriod) {
      return;
    }
    unawaited(_syncIfOnline());
  }

  Future<void> _syncIfOnline() async {
    final bool online;
    try {
      online = await ref.read(networkMonitorProvider).isOnline();
    } on Exception {
      return; // can't tell (a platform hiccup); the next trigger asks again
    }
    if (online) await _sync();
  }

  Future<void> _sync() async {
    // Stops a trigger that was already on its way when this was disposed
    // (sign-out, the app shell going away). After a mere rebuild `mounted`
    // is still true; that's safe because SyncRunner re-reads the session
    // and the settled firm itself rather than trusting the caller's.
    if (!ref.mounted) return;
    await ref.read(syncRunnerProvider.notifier).syncNow();
  }
}

/// autoDispose: when the app shell unmounts (locked, first launch) nothing
/// watches this any more, and a plain provider would keep its last build's
/// timers and listeners alive for the rest of the session.
final autoSyncProvider = NotifierProvider.autoDispose<AutoSync, void>(
  AutoSync.new,
);
