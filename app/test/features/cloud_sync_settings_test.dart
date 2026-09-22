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
}
