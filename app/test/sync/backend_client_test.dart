import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ledgerly/sync/backend_client.dart';

void main() {
  group('register', () {
    test('sends the firm/device/user shape and returns a session', () async {
      http.Request? captured;
      final client = BackendClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'access_token': 'a',
              'refresh_token': 'r',
              'token_type': 'bearer',
              'user': {'id': 'u1', 'name': 'Rashid', 'email': 'r@x.com'},
              'firm': {'id': 'f1', 'name': 'Mill'},
            }),
            201,
          );
        }),
      );

      final session = await client.register(
        name: 'Rashid',
        email: 'r@x.com',
        password: 'correct-password',
        firm: const BackendFirmInfo(
          id: 'f1',
          name: 'Mill',
          contactNumber: '0300',
        ),
        device: const BackendDeviceInfo(
          id: 'd1',
          name: 'Desktop',
          platform: 'windows',
          shortCode: 'A3F9',
        ),
      );

      expect(captured!.method, 'POST');
      expect(captured!.url.toString(), 'https://api.example.com/auth/register');
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['email'], 'r@x.com');
      expect(body['firm'], {
        'id': 'f1',
        'name': 'Mill',
        'contact_number': '0300',
      });
      expect(body['device'], {
        'id': 'd1',
        'name': 'Desktop',
        'platform': 'windows',
        'short_code': 'A3F9',
      });
      expect(session.accessToken, 'a');
      expect(session.refreshToken, 'r');
      expect(session.userId, 'u1');
      expect(session.firmId, 'f1');
      expect(session.firmName, 'Mill');
    });

    test('throws BackendConflictException on a duplicate email', () async {
      final client = BackendClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'detail': 'An account with that email already exists.',
            }),
            409,
          ),
        ),
      );

      expect(
        () => client.register(
          name: 'Rashid',
          email: 'r@x.com',
          password: 'correct-password',
          firm: const BackendFirmInfo(
            id: 'f1',
            name: 'Mill',
            contactNumber: '0300',
          ),
          device: const BackendDeviceInfo(
            id: 'd1',
            name: 'Desktop',
            platform: 'windows',
            shortCode: 'A3F9',
          ),
        ),
        throwsA(isA<BackendConflictException>()),
      );
    });
  });

  group('login', () {
    test('returns a session on success', () async {
      final client = BackendClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'access_token': 'a',
              'refresh_token': 'r',
              'token_type': 'bearer',
              'user': {'id': 'u1', 'name': 'Rashid', 'email': 'r@x.com'},
              'firm': {'id': 'f1', 'name': 'Mill'},
            }),
            200,
          ),
        ),
      );

      final session = await client.login(
        email: 'r@x.com',
        password: 'correct-password',
        deviceId: 'd1',
      );

      expect(session.firmId, 'f1');
    });

    test('throws BackendAuthException on wrong credentials', () async {
      final client = BackendClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({'detail': 'Invalid email or password.'}),
            401,
          ),
        ),
      );

      expect(
        () => client.login(email: 'r@x.com', password: 'wrong', deviceId: 'd1'),
        throwsA(isA<BackendAuthException>()),
      );
    });
  });

  group('refresh', () {
    test('returns a new token pair', () async {
      final client = BackendClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'access_token': 'a2',
              'refresh_token': 'r2',
              'token_type': 'bearer',
            }),
            200,
          ),
        ),
      );

      final tokens = await client.refresh('r1');

      expect(tokens.accessToken, 'a2');
      expect(tokens.refreshToken, 'r2');
    });
  });

  group('serverTime', () {
    test('returns the server_time field', () async {
      final client = BackendClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient(
          (request) async =>
              http.Response(jsonEncode({'server_time': 123456}), 200),
        ),
      );

      expect(await client.serverTime(), 123456);
    });
  });

  group('push', () {
    test(
      'sends auth headers and the row batch, parses accepted/rewrites',
      () async {
        http.Request? captured;
        final client = BackendClient(
          baseUrl: 'https://api.example.com',
          httpClient: MockClient((request) async {
            captured = request;
            return http.Response(
              jsonEncode({
                'accepted': [
                  {'id': 'row1', 'updated_at': 1000},
                ],
                'rejected': [],
                'rewrites': [
                  {'old_id': 'c1', 'new_id': 'c2'},
                ],
                'server_time': 2000,
              }),
              200,
            );
          }),
        );

        final result = await client.push(
          accessToken: 'a',
          firmId: 'f1',
          deviceId: 'd1',
          rows: const [
            BackendPushRow(table: 'items', id: 'row1', data: {'name': 'Oil'}),
          ],
        );

        expect(captured!.headers['Authorization'], 'Bearer a');
        expect(captured!.headers['X-Firm-Id'], 'f1');
        final body = jsonDecode(captured!.body) as Map<String, dynamic>;
        expect(body['rows'], [
          {
            'table': 'items',
            'id': 'row1',
            'data': {'name': 'Oil'},
          },
        ]);
        expect(result.accepted, {'row1': 1000});
        expect(result.rejected, isEmpty);
        expect(result.rewrites, {'c1': 'c2'});
      },
    );

    test('throws BackendAuthException on an expired access token', () async {
      final client = BackendClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({'detail': 'Invalid or expired access token.'}),
            401,
          ),
        ),
      );

      expect(
        () => client.push(
          accessToken: 'expired',
          firmId: 'f1',
          deviceId: 'd1',
          rows: const [],
        ),
        throwsA(isA<BackendAuthException>()),
      );
    });
  });

  group('pull', () {
    test('sends since/limit and auth headers, parses the page', () async {
      http.Request? captured;
      final client = BackendClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'rows': [
                {
                  'table': 'items',
                  'id': 'row1',
                  'data': {'name': 'Oil'},
                },
              ],
              'next_cursor': 5,
              'has_more': false,
            }),
            200,
          );
        }),
      );

      final page = await client.pull(
        accessToken: 'a',
        firmId: 'f1',
        since: 3,
        limit: 50,
      );

      expect(captured!.url.queryParameters, {'since': '3', 'limit': '50'});
      expect(captured!.headers['Authorization'], 'Bearer a');
      expect(page.rows, hasLength(1));
      expect(page.rows.single.table, 'items');
      expect(page.rows.single.data['name'], 'Oil');
      expect(page.nextCursor, 5);
      expect(page.hasMore, false);
    });
  });

  group('linkGoogle', () {
    test(
      'posts the ID token to /auth/google/link with the session bearer token',
      () async {
        http.Request? captured;
        final client = BackendClient(
          baseUrl: 'https://api.example.com',
          httpClient: MockClient((request) async {
            captured = request;
            return http.Response('', 204);
          }),
        );

        await client.linkGoogle(accessToken: 'access-1', idToken: 'google-id');

        expect(captured!.url.path, '/auth/google/link');
        expect(captured!.headers['Authorization'], 'Bearer access-1');
        expect(jsonDecode(captured!.body), {'id_token': 'google-id'});
      },
    );

    test('surfaces the already-linked collision as a conflict, not a generic '
        'failure', () async {
      final client = BackendClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'detail':
                  'That Google account is already linked to another '
                  'account.',
            }),
            409,
          ),
        ),
      );

      expect(
        () => client.linkGoogle(accessToken: 'a', idToken: 'g'),
        throwsA(isA<BackendConflictException>()),
      );
    });

    test('an expired access token is an auth failure the caller can refresh '
        'on', () async {
      final client = BackendClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient(
          (request) async =>
              http.Response(jsonEncode({'detail': 'expired'}), 401),
        ),
      );

      expect(
        () => client.linkGoogle(accessToken: 'stale', idToken: 'g'),
        throwsA(isA<BackendAuthException>()),
      );
    });
  });
}
