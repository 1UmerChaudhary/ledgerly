import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ledgerly/features/settings/cloud_sync_providers.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../support/pump_app.dart';

Future<void> seed(AppDatabase db, DeviceContext ctx) async {
  await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
}

/// Same firm as [seed], plus one item queued in the outbox — pushPending()
/// makes no HTTP call at all when the outbox is empty (see
/// SyncService.pushPending), so a test about a 401 *during* /sync/push
/// needs a real pending row or the push request is never sent.
Future<void> seedWithPendingSync(AppDatabase db, DeviceContext ctx) async {
  await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
  await ItemsRepository(db, ctx).create(name: 'Flour');
}

Future<void> _type(WidgetTester tester, Key key, String text) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.enterText(find.byKey(key), text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('registering a cloud account shows the connected state', (
    tester,
  ) async {
    final container = await pumpLedgerly(tester, seed: seed);
    final fakeHttp = container.read(httpClientProvider) as FakeHttpClient;
    fakeHttp.handler = (request) async => http.Response(
      jsonEncode({
        'access_token': 'a',
        'refresh_token': 'r',
        'token_type': 'bearer',
        'user': {'id': 'u1', 'name': 'Owner', 'email': 'owner@example.com'},
        'firm': {'id': 'f1', 'name': 'Mill'},
      }),
      201,
    );
    await pressCtrl(tester, LogicalKeyboardKey.comma);

    await _type(tester, const Key('settings.cloudEmail'), 'owner@example.com');
    await _type(
      tester,
      const Key('settings.cloudPassword'),
      'correct-password',
    );
    await tester.ensureVisible(find.byKey(const Key('settings.cloudRegister')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings.cloudRegister')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings.cloudConnected')), findsOneWidget);
    expect(find.textContaining('owner@example.com'), findsOneWidget);
  }, variant: windowsOnly);

  testWidgets('a failed login shows the server error without crashing', (
    tester,
  ) async {
    final container = await pumpLedgerly(tester, seed: seed);
    final fakeHttp = container.read(httpClientProvider) as FakeHttpClient;
    fakeHttp.handler = (request) async => http.Response(
      jsonEncode({'detail': 'Invalid email or password.'}),
      401,
    );
    await pressCtrl(tester, LogicalKeyboardKey.comma);

    await _type(tester, const Key('settings.cloudEmail'), 'owner@example.com');
    await _type(tester, const Key('settings.cloudPassword'), 'wrong');
    await tester.ensureVisible(find.byKey(const Key('settings.cloudLogin')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings.cloudLogin')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings.cloudError')), findsOneWidget);
    expect(find.textContaining('Invalid email or password'), findsOneWidget);
  }, variant: windowsOnly);

  testWidgets('sync now pushes and pulls, then shows a summary', (
    tester,
  ) async {
    final container = await pumpLedgerly(tester, seed: seed);
    final fakeHttp = container.read(httpClientProvider) as FakeHttpClient;
    fakeHttp.handler = (request) async {
      if (request.url.path == '/auth/register') {
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
      }
      if (request.url.path == '/sync/push') {
        return http.Response(
          jsonEncode({
            'accepted': [],
            'rejected': [],
            'rewrites': [],
            'server_time': 1000,
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({'rows': [], 'next_cursor': 0, 'has_more': false}),
        200,
      );
    };
    await pressCtrl(tester, LogicalKeyboardKey.comma);
    await _type(tester, const Key('settings.cloudEmail'), 'owner@example.com');
    await _type(
      tester,
      const Key('settings.cloudPassword'),
      'correct-password',
    );
    await tester.ensureVisible(find.byKey(const Key('settings.cloudRegister')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings.cloudRegister')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('settings.syncNow')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings.syncNow')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pushed 0, pulled 0'), findsOneWidget);
  }, variant: windowsOnly);

  testWidgets(
    'a 401 during sync refreshes the token and retries once, succeeding',
    (tester) async {
      final container = await pumpLedgerly(tester, seed: seedWithPendingSync);
      final fakeHttp = container.read(httpClientProvider) as FakeHttpClient;
      var pushCalls = 0;
      fakeHttp.handler = (request) async {
        if (request.url.path == '/auth/register') {
          return http.Response(
            jsonEncode({
              'access_token': 'a',
              'refresh_token': 'r',
              'token_type': 'bearer',
              'user': {
                'id': 'u1',
                'name': 'Owner',
                'email': 'owner@example.com',
              },
              'firm': {'id': 'f1', 'name': 'Mill'},
            }),
            201,
          );
        }
        if (request.url.path == '/sync/push') {
          pushCalls++;
          if (pushCalls == 1) {
            return http.Response(
              jsonEncode({'detail': 'Invalid or expired token'}),
              401,
            );
          }
          return http.Response(
            jsonEncode({
              'accepted': [],
              'rejected': [],
              'rewrites': [],
              'server_time': 1000,
            }),
            200,
          );
        }
        if (request.url.path == '/auth/refresh') {
          return http.Response(
            jsonEncode({'access_token': 'new-a', 'refresh_token': 'new-r'}),
            200,
          );
        }
        return http.Response(
          jsonEncode({'rows': [], 'next_cursor': 0, 'has_more': false}),
          200,
        );
      };
      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await _type(
        tester,
        const Key('settings.cloudEmail'),
        'owner@example.com',
      );
      await _type(
        tester,
        const Key('settings.cloudPassword'),
        'correct-password',
      );
      await tester.ensureVisible(
        find.byKey(const Key('settings.cloudRegister')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.cloudRegister')));
      await tester.pumpAndSettle();

      await container.read(syncRunnerProvider.notifier).syncNow();

      expect(pushCalls, 2); // one 401, one successful retry
      expect(container.read(syncRunnerProvider).error, isNull);
    },
    variant: windowsOnly,
  );

  testWidgets(
    'two concurrent syncs against an expired token only refresh once',
    (tester) async {
      final container = await pumpLedgerly(tester, seed: seedWithPendingSync);
      final fakeHttp = container.read(httpClientProvider) as FakeHttpClient;
      var pushCalls = 0;
      var refreshCalls = 0;
      fakeHttp.handler = (request) async {
        if (request.url.path == '/auth/register') {
          return http.Response(
            jsonEncode({
              'access_token': 'a',
              'refresh_token': 'r',
              'token_type': 'bearer',
              'user': {
                'id': 'u1',
                'name': 'Owner',
                'email': 'owner@example.com',
              },
              'firm': {'id': 'f1', 'name': 'Mill'},
            }),
            201,
          );
        }
        if (request.url.path == '/sync/push') {
          pushCalls++;
          // Both concurrent syncNow() calls send their first push before
          // either has a chance to retry, so the first two /sync/push
          // calls are the ones that see the expired token; anything past
          // that is a post-refresh retry and should succeed.
          if (pushCalls <= 2) {
            return http.Response(
              jsonEncode({'detail': 'Invalid or expired token'}),
              401,
            );
          }
          return http.Response(
            jsonEncode({
              'accepted': [],
              'rejected': [],
              'rewrites': [],
              'server_time': 1000,
            }),
            200,
          );
        }
        if (request.url.path == '/auth/refresh') {
          refreshCalls++;
          return http.Response(
            jsonEncode({'access_token': 'new-a', 'refresh_token': 'new-r'}),
            200,
          );
        }
        return http.Response(
          jsonEncode({'rows': [], 'next_cursor': 0, 'has_more': false}),
          200,
        );
      };
      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await _type(
        tester,
        const Key('settings.cloudEmail'),
        'owner@example.com',
      );
      await _type(
        tester,
        const Key('settings.cloudPassword'),
        'correct-password',
      );
      await tester.ensureVisible(
        find.byKey(const Key('settings.cloudRegister')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.cloudRegister')));
      await tester.pumpAndSettle();

      // Fire both without awaiting the first, so they race against the
      // same expired token.
      final first = container.read(syncRunnerProvider.notifier).syncNow();
      final second = container.read(syncRunnerProvider.notifier).syncNow();
      await Future.wait([first, second]);

      expect(refreshCalls, 1);
      expect(container.read(cloudSessionProvider), isNotNull);
      expect(container.read(syncRunnerProvider).error, isNull);
    },
    variant: windowsOnly,
  );

  testWidgets(
    'a sync that entered before another caller rotated the token refreshes '
    'with the CURRENT one, not the one it captured on the way in',
    (tester) async {
      // Not the concurrency case above -- that is two refreshes overlapping,
      // and the single-flight guard already covers it. This is a SEQUENCING
      // case: caller B enters and captures the session, caller A completes a
      // whole refresh (rotating the token and clearing the guard), and only
      // THEN does B's own request come back 401. B is now alone, so it starts
      // its own refresh -- and if it uses the token it captured on the way in,
      // that token is one the server rotated away a moment ago, so the refresh
      // itself 401s and signs the user out. Which is the exact wrongful logout
      // this whole feature exists to prevent.
      final container = await pumpLedgerly(tester, seed: seedWithPendingSync);
      final fakeHttp = container.read(httpClientProvider) as FakeHttpClient;
      final heldPush = Completer<void>();
      final refreshTokensSeen = <String>[];
      var currentRefreshToken = 'r1';
      var pushCalls = 0;

      fakeHttp.handler = (request) async {
        if (request.url.path == '/auth/register') {
          return http.Response(
            jsonEncode({
              'access_token': 'a1',
              'refresh_token': 'r1',
              'token_type': 'bearer',
              'user': {
                'id': 'u1',
                'name': 'Owner',
                'email': 'owner@example.com',
              },
              'firm': {'id': 'f1', 'name': 'Mill'},
            }),
            201,
          );
        }
        if (request.url.path == '/auth/refresh') {
          final sent =
              jsonDecode((request as http.Request).body)['refresh_token']
                  as String;
          refreshTokensSeen.add(sent);
          // A real /auth/refresh rotates: the token it was given stops
          // working the moment a new one is issued, so presenting a
          // superseded one is a 401, not a second success.
          if (sent != currentRefreshToken) {
            return http.Response(
              jsonEncode({'detail': 'Invalid or expired refresh token'}),
              401,
            );
          }
          currentRefreshToken = 'r2';
          return http.Response(
            jsonEncode({'access_token': 'a2', 'refresh_token': 'r2'}),
            200,
          );
        }
        if (request.url.path == '/sync/push') {
          pushCalls++;
          // Caller B's first push: held open until caller A has been all the
          // way through a refresh, so B's 401 lands in a world where the
          // guard is clear and its captured token is already stale.
          if (pushCalls == 1) {
            await heldPush.future;
            return http.Response(
              jsonEncode({'detail': 'Invalid or expired token'}),
              401,
            );
          }
          // Caller A's push, on the token that has just expired.
          if (pushCalls == 2) {
            return http.Response(
              jsonEncode({'detail': 'Invalid or expired token'}),
              401,
            );
          }
          return http.Response(
            jsonEncode({
              'accepted': [],
              'rejected': [],
              'rewrites': [],
              'server_time': 1000,
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({'rows': [], 'next_cursor': 0, 'has_more': false}),
          200,
        );
      };

      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await _type(
        tester,
        const Key('settings.cloudEmail'),
        'owner@example.com',
      );
      await _type(
        tester,
        const Key('settings.cloudPassword'),
        'correct-password',
      );
      await tester.ensureVisible(
        find.byKey(const Key('settings.cloudRegister')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.cloudRegister')));
      await tester.pumpAndSettle();

      final runner = container.read(syncRunnerProvider.notifier);
      final b = runner.syncNow(); // captures r1, then parks on heldPush
      await tester.pump();
      final a = runner.syncNow(); // 401 -> refreshes r1 -> r2 -> retries
      await a;

      heldPush.complete(); // now B's 401 finally arrives
      await b;

      expect(
        refreshTokensSeen,
        ['r1', 'r2'],
        reason:
            'the second refresh must present the token the first one '
            'issued, not the one it superseded',
      );
      expect(container.read(cloudSessionProvider), isNotNull);
      expect(container.read(syncRunnerProvider).error, isNull);
    },
    variant: windowsOnly,
  );

  testWidgets('a refresh that itself 401s still logs the user out', (
    tester,
  ) async {
    final container = await pumpLedgerly(tester, seed: seedWithPendingSync);
    final fakeHttp = container.read(httpClientProvider) as FakeHttpClient;
    fakeHttp.handler = (request) async {
      if (request.url.path == '/auth/register') {
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
      }
      if (request.url.path == '/sync/push') {
        return http.Response(
          jsonEncode({'detail': 'Invalid or expired token'}),
          401,
        );
      }
      if (request.url.path == '/auth/refresh') {
        return http.Response(
          jsonEncode({'detail': 'Invalid or expired token'}),
          401,
        );
      }
      return http.Response(
        jsonEncode({'rows': [], 'next_cursor': 0, 'has_more': false}),
        200,
      );
    };
    await pressCtrl(tester, LogicalKeyboardKey.comma);
    await _type(tester, const Key('settings.cloudEmail'), 'owner@example.com');
    await _type(
      tester,
      const Key('settings.cloudPassword'),
      'correct-password',
    );
    await tester.ensureVisible(find.byKey(const Key('settings.cloudRegister')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings.cloudRegister')));
    await tester.pumpAndSettle();

    await container.read(syncRunnerProvider.notifier).syncNow();

    expect(container.read(cloudSessionProvider), isNull);
    expect(container.read(syncRunnerProvider).error, isNotNull);
  }, variant: windowsOnly);

  testWidgets('Sign in with Google is only shown on Android', (tester) async {
    await pumpLedgerly(tester, seed: seed);
    await pressCtrl(tester, LogicalKeyboardKey.comma);
    expect(find.byKey(const Key('settings.signInWithGoogle')), findsNothing);
  }, variant: windowsOnly);

  testWidgets('Sign in with Google is offered on Android', (tester) async {
    await pumpLedgerly(tester, seed: seed);
    await pressCtrl(tester, LogicalKeyboardKey.comma);
    expect(find.byKey(const Key('settings.signInWithGoogle')), findsOneWidget);
  }, variant: phoneOnly);

  testWidgets(
    'signing in with Google reaches the backend and shows the connected '
    'state',
    (tester) async {
      final container = await pumpLedgerly(tester, seed: seed);
      final fakeGoogleAuth = container.read(
        googleAuthenticatorProvider,
      ) as FakeGoogleAuthenticator;
      fakeGoogleAuth.idToken = 'fake-google-id-token';
      final fakeHttp = container.read(httpClientProvider) as FakeHttpClient;
      fakeHttp.handler = (request) async {
        expect(request.url.path, '/auth/google');
        return http.Response(
          jsonEncode({
            'access_token': 'a',
            'refresh_token': 'r',
            'token_type': 'bearer',
            'user': {'id': 'u1', 'name': 'Owner', 'email': 'owner@gmail.com'},
            'firm': {'id': 'f1', 'name': 'Mill'},
          }),
          201,
        );
      };
      await pressCtrl(tester, LogicalKeyboardKey.comma);

      await tester.ensureVisible(
        find.byKey(const Key('settings.signInWithGoogle')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.signInWithGoogle')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings.cloudConnected')), findsOneWidget);
      expect(find.textContaining('owner@gmail.com'), findsOneWidget);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'signing in with Google when the email already has a password account '
    'shows a specific message',
    (tester) async {
      final container = await pumpLedgerly(tester, seed: seed);
      final fakeGoogleAuth = container.read(
        googleAuthenticatorProvider,
      ) as FakeGoogleAuthenticator;
      fakeGoogleAuth.idToken = 'fake-google-id-token';
      final fakeHttp = container.read(httpClientProvider) as FakeHttpClient;
      fakeHttp.handler = (request) async =>
          http.Response(jsonEncode({'detail': 'email_exists_unlinked'}), 409);
      await pressCtrl(tester, LogicalKeyboardKey.comma);

      await tester.ensureVisible(
        find.byKey(const Key('settings.signInWithGoogle')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.signInWithGoogle')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings.cloudError')), findsOneWidget);
      expect(find.textContaining('Log in with your password'), findsOneWidget);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'cancelling the Google account picker shows an error instead of crashing',
    (tester) async {
      final container = await pumpLedgerly(tester, seed: seed);
      final fakeGoogleAuth = container.read(
        googleAuthenticatorProvider,
      ) as FakeGoogleAuthenticator;
      fakeGoogleAuth.idToken = null; // simulates a cancelled account picker
      await pressCtrl(tester, LogicalKeyboardKey.comma);

      await tester.ensureVisible(
        find.byKey(const Key('settings.signInWithGoogle')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.signInWithGoogle')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings.cloudError')), findsOneWidget);
      expect(find.textContaining('cancelled'), findsOneWidget);
    },
    variant: phoneOnly,
  );

  /// The far end of the 409 above. That message tells the user to log in with
  /// their password and then link Google from Settings, so Settings has to
  /// have somewhere to do it -- POST /auth/google/link existed with no caller
  /// anywhere in the app, which left the account-takeover mitigation this
  /// whole endpoint exists for terminating in a dead end.
  Future<void> connectWithPassword(
    WidgetTester tester,
    FakeHttpClient fakeHttp,
  ) async {
    fakeHttp.handler = (request) async => http.Response(
      jsonEncode({
        'access_token': 'access-1',
        'refresh_token': 'r',
        'token_type': 'bearer',
        'user': {'id': 'u1', 'name': 'Owner', 'email': 'owner@example.com'},
        'firm': {'id': 'f1', 'name': 'Mill'},
      }),
      200,
    );
    await _type(tester, const Key('settings.cloudEmail'), 'owner@example.com');
    await _type(
      tester,
      const Key('settings.cloudPassword'),
      'correct-password',
    );
    await tester.ensureVisible(find.byKey(const Key('settings.cloudLogin')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings.cloudLogin')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a password session can link Google sign-in from Settings, sending the '
    'ID token with the session bearer token',
    (tester) async {
      final container = await pumpLedgerly(tester, seed: seed);
      final fakeHttp = container.read(httpClientProvider) as FakeHttpClient;
      final fakeGoogleAuth = container.read(
        googleAuthenticatorProvider,
      ) as FakeGoogleAuthenticator;
      fakeGoogleAuth.idToken = 'fake-google-id-token';
      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await connectWithPassword(tester, fakeHttp);

      http.BaseRequest? linkRequest;
      String? sentIdToken;
      fakeHttp.handler = (request) async {
        linkRequest = request;
        sentIdToken =
            jsonDecode((request as http.Request).body)['id_token'] as String;
        return http.Response('', 204);
      };

      await tester.ensureVisible(find.byKey(const Key('settings.linkGoogle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.linkGoogle')));
      await tester.pumpAndSettle();

      expect(linkRequest!.url.path, '/auth/google/link');
      expect(linkRequest!.headers['Authorization'], 'Bearer access-1');
      expect(sentIdToken, 'fake-google-id-token');
      expect(find.textContaining('Google sign-in is linked'), findsOneWidget);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'a Google account already attached to someone else says so rather than '
    'failing silently',
    (tester) async {
      final container = await pumpLedgerly(tester, seed: seed);
      final fakeHttp = container.read(httpClientProvider) as FakeHttpClient;
      final fakeGoogleAuth = container.read(
        googleAuthenticatorProvider,
      ) as FakeGoogleAuthenticator;
      fakeGoogleAuth.idToken = 'fake-google-id-token';
      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await connectWithPassword(tester, fakeHttp);

      fakeHttp.handler = (request) async => http.Response(
        jsonEncode({
          'detail': 'That Google account is already linked to another account.',
        }),
        409,
      );

      await tester.ensureVisible(find.byKey(const Key('settings.linkGoogle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.linkGoogle')));
      await tester.pumpAndSettle();

      expect(find.textContaining('already linked'), findsOneWidget);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'the link action is not offered on a platform Google sign-in cannot run '
    'on at all',
    (tester) async {
      final container = await pumpLedgerly(tester, seed: seed);
      final fakeHttp = container.read(httpClientProvider) as FakeHttpClient;
      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await connectWithPassword(tester, fakeHttp);

      expect(find.byKey(const Key('settings.linkGoogle')), findsNothing);
    },
    variant: windowsOnly,
  );
}
