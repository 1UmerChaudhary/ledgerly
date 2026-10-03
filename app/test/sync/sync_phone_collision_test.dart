import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ledgerly/sync/backend_client.dart';
import 'package:ledgerly/sync/sync_service.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

/// Two devices that each add the same customer (same phone) before syncing
/// is ordinary use, not an edge case. The server accepts it -- merging the
/// two when the names match, keeping both flagged needs_review when they
/// don't -- so the device must be able to hold whatever the server sends.
/// Before this, the device's own unique-phone index refused the pulled row,
/// the pull failed at that row on every sync, and the device never pulled
/// anything again.

const _firmId = '11111111-1111-4111-8111-111111111111';
const _deviceId = '22222222-2222-4222-8222-222222222222';
const _userId = '33333333-3333-4333-8333-333333333333';
const _otherDevice = '44444444-4444-4444-8444-444444444444';
const _phone = '923001234567';

Future<(AppDatabase, DeviceContext)> _seededDb() async {
  final db = AppDatabase(NativeDatabase.memory());
  var clock = 5000;
  final ctx = DeviceContext(
    firmId: _firmId,
    deviceId: _deviceId,
    deviceShortCode: 'A3F9',
    userId: _userId,
    hlc: Hlc(clock: () => clock++),
  );
  await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
  return (db, ctx);
}

Map<String, dynamic> _customerRow(
  String id, {
  required String name,
  bool needsReview = false,
  int createdAt = 1000,
}) => {
  'table': 'customers',
  'id': id,
  'data': {
    'name': name,
    'name_normalized': normalizeName(name),
    'phone': '0300 1234567',
    'phone_normalized': _phone,
    'notes': null,
    'created_by_user_id': _userId,
    'merged_into_id': null,
    'needs_review': needsReview,
    'created_at': createdAt,
    'updated_at': createdAt,
    'updated_by_device_id': _otherDevice,
    'deleted_at': null,
  },
};

Map<String, dynamic> _billRow(String id, {required String customerId}) => {
  'table': 'transactions',
  'id': id,
  'data': {
    'customer_id': customerId,
    'device_short_code': 'B7C2',
    'display_seq': 1,
    'type': 'opening_balance',
    'entry_date': '2026-09-20',
    'description': null,
    'version': 1,
    'calculated_total': 0,
    'overridden_total': null,
    'overridden_total_basis': null,
    'final_amount': 70000,
    'created_by_user_id': _userId,
    'updated_by_user_id': _userId,
    'created_at': 9500,
    'updated_at': 9500,
    'updated_by_device_id': _otherDevice,
    'deleted_at': null,
    'lines': <Object>[],
  },
};

SyncService _pulling(
  AppDatabase db,
  DeviceContext ctx,
  List<Map<String, dynamic>> rows,
) => SyncService(
  db: db,
  ctx: ctx,
  accessToken: 'token',
  client: BackendClient(
    baseUrl: 'https://api.example.com',
    httpClient: MockClient(
      (request) async => http.Response(
        jsonEncode({'rows': rows, 'next_cursor': 9, 'has_more': false}),
        200,
      ),
    ),
  ),
);

Future<Customer> _localAli(AppDatabase db, DeviceContext ctx) =>
    CustomersRepository(db, ctx).create(name: 'Ali', phone: '0300-1234567');

Future<Bill> _billFor(AppDatabase db, DeviceContext ctx, String customerId) =>
    BillsRepository(db, ctx).saveNew(
      Bill(
        id: newId(),
        customerId: customerId,
        type: TransactionType.openingBalance,
        entryDate: '2026-09-01',
        typedAmount: Money.rupees(500),
      ),
    );

Future<CustomerRow> _customer(AppDatabase db, String id) =>
    (db.select(db.customers)..where((c) => c.id.equals(id))).getSingle();

Future<TransactionRow> _bill(AppDatabase db, String id) =>
    (db.select(db.transactions)..where((t) => t.id.equals(id))).getSingle();

Future<bool> _queued(AppDatabase db, String table, String id) async =>
    (await (db.select(db.syncOutbox)
          ..where((o) => o.targetTable.equals(table) & o.rowId.equals(id)))
        .getSingleOrNull()) !=
    null;

Future<void> _clearOutbox(AppDatabase db) => db.delete(db.syncOutbox).go();

void main() {
  test('a pulled customer the server flagged needs_review can share my '
      "customer's phone: both are kept, and the pull goes through", () async {
    final (db, ctx) = await _seededDb();
    addTearDown(db.close);
    final mine = await _localAli(db, ctx);
    final theirs = newId();

    final pulled = await _pulling(db, ctx, [
      _customerRow(theirs, name: 'Ali Khan', needsReview: true),
    ]).pullAll();

    expect(pulled, 1);
    expect((await _customer(db, theirs)).needsReview, isTrue);
    expect((await _customer(db, mine.id)).mergedIntoId, isNull);
  });

  test('same phone and same name is the server having merged them: mine '
      'folds into the server copy, and my bills follow it and are queued to '
      'sync', () async {
    final (db, ctx) = await _seededDb();
    addTearDown(db.close);
    final mine = await _localAli(db, ctx); // created at ~5000
    final bill = await _billFor(db, ctx, mine.id);
    await _clearOutbox(db); // as if already pushed
    final theirs = newId();

    await _pulling(db, ctx, [
      _customerRow(theirs, name: 'Ali', createdAt: 1000),
    ]).pullAll();

    expect((await _customer(db, mine.id)).mergedIntoId, theirs);
    expect((await _customer(db, theirs)).mergedIntoId, isNull);
    expect((await _bill(db, bill.id)).customerId, theirs);
    expect(await _queued(db, 'transactions', bill.id), isTrue);
    expect(await _queued(db, 'customers', mine.id), isTrue);
    final list = await CustomersRepository(db, ctx).all();
    expect(list.map((c) => c.id), [theirs]);
  });

  test('even when mine is older, mine folds into the server\'s: the server '
      'only ever holds one live customer per phone and name, so its copy is '
      'the one every device keeps -- and bills pulled later for mine move '
      'too', () async {
    final (db, ctx) = await _seededDb();
    addTearDown(db.close);
    final mine = await _localAli(db, ctx); // created at ~5000
    await _clearOutbox(db);
    final theirs = newId();
    final lateBill = newId();

    await _pulling(db, ctx, [
      _customerRow(theirs, name: 'Ali', createdAt: 9000),
      _billRow(lateBill, customerId: mine.id),
    ]).pullAll();

    expect((await _customer(db, mine.id)).mergedIntoId, theirs);
    expect((await _customer(db, theirs)).mergedIntoId, isNull);
    expect((await _bill(db, lateBill)).customerId, theirs);
    expect(await _queued(db, 'transactions', lateBill), isTrue);
  });

  test('same phone, different names, neither flagged (resolved on the '
      'server): mine gets flagged needs_review so both can be kept', () async {
    final (db, ctx) = await _seededDb();
    addTearDown(db.close);
    final mine = await _localAli(db, ctx);
    await _clearOutbox(db);
    final theirs = newId();

    await _pulling(db, ctx, [_customerRow(theirs, name: 'Ali Khan')]).pullAll();

    expect((await _customer(db, mine.id)).needsReview, isTrue);
    expect(await _queued(db, 'customers', mine.id), isTrue);
    expect((await _customer(db, theirs)).needsReview, isFalse);
  });

  test('the server saying it merged mine into its copy is followed, even '
      'when its copy is flagged needs_review (where guessing from the pull '
      'alone would leave mine live and its bills rejected forever)', () async {
    final (db, ctx) = await _seededDb();
    addTearDown(db.close);
    final mine = await _localAli(db, ctx);
    final bill = await _billFor(db, ctx, mine.id);
    final theirs = newId();
    final service = SyncService(
      db: db,
      ctx: ctx,
      accessToken: 'token',
      client: BackendClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient((request) async {
          if (request.url.path == '/sync/push') {
            return http.Response(
              jsonEncode({
                'accepted': [
                  {'id': mine.id, 'updated_at': 5000},
                ],
                'rejected': [
                  {'id': bill.id, 'reason': 'invalid'},
                ],
                'rewrites': [
                  {'old_id': mine.id, 'new_id': theirs},
                ],
                'server_time': 6000,
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'rows': [_customerRow(theirs, name: 'Ali', needsReview: true)],
              'next_cursor': 9,
              'has_more': false,
            }),
            200,
          );
        }),
      ),
    );

    await service.pushPending();
    await service.pullAll();

    expect((await _customer(db, mine.id)).mergedIntoId, theirs);
    expect((await _bill(db, bill.id)).customerId, theirs);
    // Queued again, with the old rejection cleared -- it isn't "invalid"
    // any more, and Settings shouldn't keep saying so.
    final outbox = await (db.select(
      db.syncOutbox,
    )..where((o) => o.rowId.equals(bill.id))).getSingle();
    expect(outbox.attempts, 0);
    expect(outbox.failedReason, isNull);
  });
}
