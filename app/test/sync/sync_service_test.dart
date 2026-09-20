import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ledgerly/sync/backend_client.dart';
import 'package:ledgerly/sync/sync_service.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

const _firmId = '11111111-1111-4111-8111-111111111111';
const _deviceId = '22222222-2222-4222-8222-222222222222';
const _userId = '33333333-3333-4333-8333-333333333333';

Future<(AppDatabase, DeviceContext)> _seededDb() async {
  final db = AppDatabase(NativeDatabase.memory());
  final ctx = DeviceContext(
    firmId: _firmId,
    deviceId: _deviceId,
    deviceShortCode: 'A3F9',
    userId: _userId,
    hlc: Hlc(clock: () => 5000),
  );
  await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
  return (db, ctx);
}

void main() {
  final itemId1 = newId();
  final txnId1 = newId();
  final lineId1 = newId();
  final itemIdA = newId();
  final itemIdB = newId();

  group('pushPending', () {
    test('pushes an outbox row and clears it once accepted', () async {
      final (db, ctx) = await _seededDb();
      addTearDown(db.close);
      final item = await ItemsRepository(db, ctx).create(name: 'Oil');

      http.Request? captured;
      final client = BackendClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'accepted': [
                {'id': item.id, 'updated_at': 5000},
              ],
              'rejected': [],
              'rewrites': [],
              'server_time': 6000,
            }),
            200,
          );
        }),
      );
      final service = SyncService(
        db: db,
        ctx: ctx,
        client: client,
        accessToken: 'token',
      );

      final summary = await service.pushPending();

      expect(summary.accepted, 1);
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      final rows = (body['rows'] as List).cast<Map<String, dynamic>>();
      expect(rows.single['table'], 'items');
      expect(rows.single['id'], item.id);
      expect((rows.single['data'] as Map)['name'], 'Oil');
      final remaining = await db.select(db.syncOutbox).get();
      expect(remaining.where((o) => o.rowId == item.id), isEmpty);
    });

    test('records the reason and bumps attempts on a rejected row', () async {
      final (db, ctx) = await _seededDb();
      addTearDown(db.close);
      final item = await ItemsRepository(db, ctx).create(name: 'Oil');

      final client = BackendClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'accepted': [],
              'rejected': [
                {'id': item.id, 'reason': 'clock_skew'},
              ],
              'rewrites': [],
              'server_time': 6000,
            }),
            200,
          ),
        ),
      );
      final service = SyncService(
        db: db,
        ctx: ctx,
        client: client,
        accessToken: 'token',
      );

      await service.pushPending();

      final outboxRow = await (db.select(
        db.syncOutbox,
      )..where((o) => o.rowId.equals(item.id))).getSingle();
      expect(outboxRow.attempts, 1);
      expect(outboxRow.failedReason, 'clock_skew');
    });

    test('does nothing when the outbox is empty', () async {
      final (db, ctx) = await _seededDb();
      addTearDown(db.close);
      var called = false;
      final client = BackendClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient((request) async {
          called = true;
          return http.Response('{}', 200);
        }),
      );
      final service = SyncService(
        db: db,
        ctx: ctx,
        client: client,
        accessToken: 'token',
      );

      final summary = await service.pushPending();

      expect(summary.accepted, 0);
      expect(called, isFalse);
    });
  });

  group('pullAll', () {
    test('applies a pulled item and advances the cursor', () async {
      final (db, ctx) = await _seededDb();
      addTearDown(db.close);
      final client = BackendClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'rows': [
                {
                  'table': 'items',
                  'id': itemId1,
                  'data': {
                    'name': 'Refined Oil',
                    'name_normalized': 'refined oil',
                    'default_bag_weight_g': null,
                    'default_rate_base_weight_g': null,
                    'default_uom': 'kg',
                    'track_stock': false,
                    'created_by_user_id': _userId,
                    'created_at': 1000,
                    'updated_at': 1000,
                    'updated_by_device_id': _deviceId,
                    'deleted_at': null,
                  },
                },
              ],
              'next_cursor': 7,
              'has_more': false,
            }),
            200,
          ),
        ),
      );
      final service = SyncService(
        db: db,
        ctx: ctx,
        client: client,
        accessToken: 'token',
      );

      final pulled = await service.pullAll();

      expect(pulled, 1);
      final row = await (db.select(
        db.items,
      )..where((t) => t.id.equals(itemId1))).getSingle();
      expect(row.name, 'Refined Oil');
      final state = await (db.select(
        db.syncState,
      )..where((s) => s.deviceId.equals(_deviceId))).getSingle();
      expect(state.lastPullCursor, 7);
    });

    test('applies a pulled transaction with its lines', () async {
      final (db, ctx) = await _seededDb();
      addTearDown(db.close);
      final item = await ItemsRepository(db, ctx).create(name: 'Oil');
      final client = BackendClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'rows': [
                {
                  'table': 'transactions',
                  'id': txnId1,
                  'data': {
                    'customer_id': null,
                    'device_short_code': 'B7C2',
                    'display_seq': 1,
                    'type': 'sale',
                    'entry_date': '2026-09-20',
                    'description': null,
                    'version': 1,
                    'calculated_total': 1000,
                    'overridden_total': null,
                    'overridden_total_basis': null,
                    'final_amount': 1000,
                    'created_by_user_id': _userId,
                    'updated_by_user_id': _userId,
                    'created_at': 1000,
                    'updated_at': 1000,
                    'updated_by_device_id': _deviceId,
                    'deleted_at': null,
                    'lines': [
                      {
                        'id': lineId1,
                        'line_no': 0,
                        'item_id': item.id,
                        'uom': 'kg',
                        'sale_mode': 'by_weight',
                        'bag_count': null,
                        'bag_weight_g': null,
                        'total_weight_g': 1000,
                        'quantity': null,
                        'rate_paisa': 1000,
                        'rate_base_weight_g': 1000,
                        'overridden_total': null,
                      },
                    ],
                  },
                },
              ],
              'next_cursor': 1,
              'has_more': false,
            }),
            200,
          ),
        ),
      );
      final service = SyncService(
        db: db,
        ctx: ctx,
        client: client,
        accessToken: 'token',
      );

      await service.pullAll();

      final lines = await (db.select(
        db.transactionLines,
      )..where((l) => l.transactionId.equals(txnId1))).get();
      expect(lines, hasLength(1));
      expect(lines.single.itemId, item.id);
    });

    test('loops through pages while has_more is true', () async {
      final (db, ctx) = await _seededDb();
      addTearDown(db.close);
      var callCount = 0;
      final client = BackendClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient((request) async {
          callCount++;
          final since = request.url.queryParameters['since'];
          final isFirstPage = since == '0';
          return http.Response(
            jsonEncode({
              'rows': [
                {
                  'table': 'items',
                  'id': isFirstPage ? itemIdA : itemIdB,
                  'data': {
                    'name': isFirstPage ? 'A' : 'B',
                    'name_normalized': isFirstPage ? 'a' : 'b',
                    'default_bag_weight_g': null,
                    'default_rate_base_weight_g': null,
                    'default_uom': 'kg',
                    'track_stock': false,
                    'created_by_user_id': _userId,
                    'created_at': 1000,
                    'updated_at': 1000,
                    'updated_by_device_id': _deviceId,
                    'deleted_at': null,
                  },
                },
              ],
              'next_cursor': isFirstPage ? 1 : 2,
              'has_more': isFirstPage,
            }),
            200,
          );
        }),
      );
      final service = SyncService(
        db: db,
        ctx: ctx,
        client: client,
        accessToken: 'token',
      );

      final pulled = await service.pullAll();

      expect(callCount, 2);
      expect(pulled, 2);
    });
  });
}
