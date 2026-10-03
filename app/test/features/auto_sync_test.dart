import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ledgerly/bootstrap/providers.dart';
import 'package:ledgerly/features/settings/cloud_sync_providers.dart';
import 'package:ledgerly/sync/backend_client.dart';
import 'package:ledgerly/sync/auto_sync.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../support/pump_app.dart';

Future<void> seed(AppDatabase db, DeviceContext ctx) async {
  await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
}

/// A stand-in for the real backend that acks every pushed row the way the
/// server does, so the outbox actually drains -- which is what makes the
/// "an ack doesn't start another sync" test mean anything.
class FakeBackend {
  /// Item names in each /sync/push call, one list per call.
  final pushes = <List<String>>[];
  var pulls = 0;

  /// Set to park the next /sync/push until completed.
  Completer<void>? holdPush;

  /// Set to make every /sync/push hang forever, like a half-open socket.
  var hangPushes = false;

  /// What /sync/pull reports as its cursor. Null reproduces a malformed
  /// page, which fails the cast in BackendPullPage with a TypeError -- an
  /// Error, not an Exception.
  Object? pullCursor = 0;
  var _pushesInFlight = 0;
  var maxPushesInFlight = 0;

  Future<http.Response> handle(http.BaseRequest request) async {
    switch (request.url.path) {
      case '/auth/register':
        return http.Response(
          jsonEncode({
            'access_token': 'a',
            'refresh_token': 'r',
            'token_type': 'bearer',
            'user': {'id': 'u1', 'name': 'Owner', 'email': 'owner@example.com'},
            'firm': {'id': 'f1', 'name': 'Mill'},
          }),
          201,
        );
      case '/sync/push':
        _pushesInFlight++;
        maxPushesInFlight = _pushesInFlight > maxPushesInFlight
            ? _pushesInFlight
            : maxPushesInFlight;
        try {
          final rows =
              (jsonDecode((request as http.Request).body)['rows'] as List)
                  .cast<Map<String, dynamic>>();
          pushes.add([
            for (final row in rows)
              if (row['table'] == 'items')
                (row['data'] as Map<String, dynamic>)['name'] as String,
          ]);
          if (hangPushes) await Completer<void>().future;
          if (holdPush case final hold?) {
            holdPush = null;
            await hold.future;
          }
          return http.Response(
            jsonEncode({
              'accepted': [
                for (final row in rows)
                  {
                    'id': row['id'],
                    'updated_at':
                        (row['data'] as Map<String, dynamic>)['updated_at'],
                  },
              ],
              'rejected': [],
              'rewrites': [],
              'server_time': 1000,
            }),
            200,
          );
        } finally {
          _pushesInFlight--;
        }
      case '/sync/pull':
        pulls++;
        return http.Response(
          jsonEncode({
            'rows': [],
            'next_cursor': pullCursor,
            'has_more': false,
          }),
          200,
        );
    }
    throw StateError(
      'FakeBackend: unexpected ${request.method} ${request.url}',
    );
  }
}

typedef Harness = ({
  ProviderContainer container,
  FakeBackend backend,
  FakeNetworkMonitor network,
  FakeSyncTicker ticker,
});

Future<Harness> pumpWithBackend(WidgetTester tester) async {
  final container = await pumpLedgerly(tester, seed: seed);
  final backend = FakeBackend();
  (container.read(httpClientProvider) as FakeHttpClient).handler =
      backend.handle;
  return (
    container: container,
    backend: backend,
    network: container.read(networkMonitorProvider) as FakeNetworkMonitor,
    ticker: container.read(syncTickerProvider) as FakeSyncTicker,
  );
}

Future<void> signIn(WidgetTester tester, ProviderContainer container) async {
  await container
      .read(cloudSessionProvider.notifier)
      .register(
        name: 'Owner',
        email: 'owner@example.com',
        password: 'correct-password',
      );
  await tester.pumpAndSettle();
}

Future<void> saveItem(
  WidgetTester tester,
  ProviderContainer container,
  String name,
) async {
  final firm = container.read(openFirmProvider).value!;
  await ItemsRepository(firm.db, firm.ctx).create(name: name);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('saving while online pushes that save immediately', (
    tester,
  ) async {
    final h = await pumpWithBackend(tester);
    await signIn(tester, h.container);
    h.network.online = true;

    await saveItem(tester, h.container, 'Rice');

    expect(h.backend.pushes.last, ['Rice']);
  }, variant: phoneOnly);

  testWidgets(
    'saving while offline sends nothing, and the save goes up as soon as the '
    'network comes back',
    (tester) async {
      final h = await pumpWithBackend(tester);
      await signIn(tester, h.container);

      await saveItem(tester, h.container, 'Rice');
      expect(h.backend.pushes, isEmpty);

      h.network.goOnline();
      await tester.pumpAndSettle();

      expect(h.backend.pushes.single, ['Rice']);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'signing in while online syncs right away, without tapping Sync now',
    (tester) async {
      final h = await pumpWithBackend(tester);
      h.network.online = true;

      await signIn(tester, h.container);

      expect(h.backend.pulls, 1);
    },
    variant: phoneOnly,
  );

  testWidgets('the five-minute tick syncs while online and not while offline', (
    tester,
  ) async {
    final h = await pumpWithBackend(tester);
    await signIn(tester, h.container);

    h.ticker.tick();
    await tester.pumpAndSettle();
    expect(h.backend.pulls, 0);

    h.network.online = true;
    h.ticker.tick();
    await tester.pumpAndSettle();
    expect(h.backend.pulls, 1);
  }, variant: phoneOnly);

  testWidgets('coming back to the app syncs, since timers sleep in the '
      'background on Android', (tester) async {
    final h = await pumpWithBackend(tester);
    await signIn(tester, h.container);
    h.network.online = true;

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();

    expect(h.backend.pulls, 1);
  }, variant: phoneOnly);

  testWidgets(
    'the server acking a push does not itself start another sync -- the ack '
    'deletes outbox rows, and only new saves count',
    (tester) async {
      final h = await pumpWithBackend(tester);
      await signIn(tester, h.container);
      h.network.online = true;

      await saveItem(tester, h.container, 'Rice');

      expect(h.backend.pushes, hasLength(1));
      expect(h.backend.pulls, 1);
      final firm = h.container.read(openFirmProvider).value!;
      final queuedItems = await (firm.db.select(
        firm.db.syncOutbox,
      )..where((o) => o.targetTable.equals('items'))).get();
      expect(queuedItems, isEmpty);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'a save made while a sync is running is pushed by one follow-up run, '
    'never by a second sync in parallel',
    (tester) async {
      final h = await pumpWithBackend(tester);
      await signIn(tester, h.container);
      h.network.online = true;
      final held = Completer<void>();
      h.backend.holdPush = held;

      await saveItem(tester, h.container, 'Rice'); // parks on held
      await saveItem(tester, h.container, 'Sugar');
      await saveItem(tester, h.container, 'Salt');
      expect(h.backend.pushes, [
        ['Rice'],
      ]);

      held.complete();
      await tester.pumpAndSettle();

      expect(h.backend.maxPushesInFlight, 1);
      expect(h.backend.pushes, hasLength(2));
      expect(h.backend.pushes[1], unorderedEquals(['Sugar', 'Salt']));
    },
    variant: phoneOnly,
  );

  testWidgets('nothing is sent while signed out, online or not', (
    tester,
  ) async {
    final h = await pumpWithBackend(tester);
    h.network.goOnline();
    await tester.pumpAndSettle();

    await saveItem(tester, h.container, 'Rice');
    h.ticker.tick();
    await tester.pumpAndSettle();

    expect(h.backend.pushes, isEmpty);
    expect(h.backend.pulls, 0);
  }, variant: phoneOnly);

  testWidgets('signing out stops automatic sync', (tester) async {
    final h = await pumpWithBackend(tester);
    await signIn(tester, h.container);
    await h.container.read(cloudSessionProvider.notifier).logout();
    await tester.pumpAndSettle();
    h.network.online = true;

    await saveItem(tester, h.container, 'Rice');
    h.ticker.tick();
    await tester.pumpAndSettle();

    expect(h.backend.pushes, isEmpty);
    // Not just "found nothing to send": the triggers themselves are gone.
    expect(h.ticker.hasListener, isFalse);
    expect(h.network.hasListener, isFalse);
  }, variant: phoneOnly);

  testWidgets(
    'the network monitor reporting "online" when first subscribed is not a '
    'regained network, and online-to-online (Wi-Fi to mobile) is not either',
    (tester) async {
      final h = await pumpWithBackend(tester);
      h.network.online = true;
      await signIn(tester, h.container); // one sync for signing in

      h.network.goOnline(); // already online: a handover, not a regain
      await tester.pumpAndSettle();

      expect(h.backend.pulls, 1);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'coming back to the app moments after a sync does not sync again -- on '
    'Windows "resumed" fires on every alt-tab',
    (tester) async {
      final h = await pumpWithBackend(tester);
      h.network.online = true;
      await signIn(tester, h.container);
      expect(h.backend.pulls, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(h.backend.pulls, 1);
    },
    variant: windowsOnly,
  );

  testWidgets(
    'restoring a backup while signed in and online never syncs against the '
    'database restore just closed, and syncs the restored one once it opens',
    (tester) async {
      final h = await pumpWithBackend(tester);
      await signIn(tester, h.container);
      h.network.online = true;

      // What restoreFromPickedFile does: release the file, then reload.
      final firm = h.container.read(openFirmProvider).value!;
      await firm.db.close();
      h.container.invalidate(firmGateProvider);
      h.container.invalidate(openFirmProvider);
      await tester.pumpAndSettle();

      expect(h.container.read(syncRunnerProvider).error, isNull);
      expect(h.backend.pulls, 1);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'a sync that dies on an Error (not an Exception) still reports it, frees '
    'the Sync now button, and the next save syncs normally',
    (tester) async {
      final h = await pumpWithBackend(tester);
      await signIn(tester, h.container);
      h.network.online = true;
      h.backend.pullCursor = null;

      await saveItem(tester, h.container, 'Rice');

      final failed = h.container.read(syncRunnerProvider);
      expect(failed.running, isFalse);
      expect(failed.error, isNotNull);

      h.backend.pullCursor = 0;
      await saveItem(tester, h.container, 'Sugar');

      expect(h.backend.pushes.last, contains('Sugar'));
      expect(h.container.read(syncRunnerProvider).error, isNull);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'a request that never answers times out instead of holding up every '
    'later sync forever',
    (tester) async {
      final h = await pumpWithBackend(tester);
      await signIn(tester, h.container);
      h.network.online = true;
      h.backend.hangPushes = true;

      await saveItem(tester, h.container, 'Rice');
      await tester.pump(backendRequestTimeout + const Duration(seconds: 1));
      await tester.pumpAndSettle();

      final timedOut = h.container.read(syncRunnerProvider);
      expect(timedOut.running, isFalse);
      expect(timedOut.error, contains('did not answer'));

      h.backend.hangPushes = false;
      await saveItem(tester, h.container, 'Sugar');

      expect(h.backend.pushes.last, containsAll(['Rice', 'Sugar']));
    },
    variant: phoneOnly,
  );
}
