import 'dart:math';

import 'package:drift/native.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:test/test.dart';

const firm = '11111111-1111-4111-8111-111111111111';
const device = '22222222-2222-4222-8222-222222222222';
const owner = '33333333-3333-4333-8333-333333333333';
const rashid = '44444444-4444-4444-8444-444444444444';
const oil = '55555555-5555-4555-8555-555555555555';

Future<void> seedFirmCustomerItem(AppDatabase db) async {
  await db.customStatement(
    "INSERT INTO firms (id, name, contact_number, created_at, updated_at, updated_by_device_id) VALUES ('$firm','Al-Madina','0300',1,1,'$device')",
  );
  await db.customStatement(
    "INSERT INTO users (id, name, created_at, updated_at, updated_by_device_id) VALUES ('$owner','Owner',1,1,'$device')",
  );
  await db.customStatement(
    "INSERT INTO customers (id, firm_id, name, name_normalized, created_by_user_id, created_at, updated_at, updated_by_device_id) VALUES ('$rashid','$firm','Rashid Traders','rashid traders','$owner',1,1,'$device')",
  );
  await db.customStatement(
    "INSERT INTO items (id, firm_id, name, name_normalized, created_by_user_id, created_at, updated_at, updated_by_device_id) VALUES ('$oil','$firm','Oil','oil','$owner',1,1,'$device')",
  );
}

Future<void> insertTxn(
  AppDatabase db, {
  required String id,
  String? customerId = rashid,
  required String type,
  required int finalAmount,
  String entryDate = '2026-09-18',
  int seq = 1,
  int createdAt = 1,
}) {
  final cust = customerId == null ? 'NULL' : "'$customerId'";
  return db.customStatement(
    'INSERT INTO transactions (id, firm_id, customer_id, device_short_code, display_seq, type, entry_date, version, calculated_total, final_amount, created_by_user_id, updated_by_user_id, created_at, updated_at, updated_by_device_id) '
    "VALUES ('$id','$firm',$cust,'A3F9',$seq,'$type','$entryDate',1,$finalAmount,$finalAmount,'$owner','$owner',$createdAt,$createdAt,'$device')",
  );
}

String uuidN(int n) =>
    '66666666-6666-4666-8666-${n.toString().padLeft(12, '0')}';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await seedFirmCustomerItem(db);
  });
  tearDown(() => db.close());

  test('foreign keys are enforced on every connection', () async {
    final rows = await db.customSelect('PRAGMA foreign_keys').get();
    expect(rows.single.data.values.first, 1);
    expect(
      () => insertTxn(
        db,
        id: uuidN(1),
        customerId: '99999999-9999-4999-8999-999999999999',
        type: 'sale',
        finalAmount: 100,
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  group('CHECK constraints reject what the app must never store', () {
    test('a type typo', () {
      expect(
        () => insertTxn(db, id: uuidN(1), type: 'Sale', finalAmount: 100),
        throwsA(isA<SqliteException>()),
      );
    });
    test('a zero or negative sale', () {
      expect(
        () => insertTxn(db, id: uuidN(1), type: 'sale', finalAmount: 0),
        throwsA(isA<SqliteException>()),
      );
      expect(
        () => insertTxn(db, id: uuidN(2), type: 'sale', finalAmount: -5),
        throwsA(isA<SqliteException>()),
      );
    });
    test('a zero adjustment, but not a negative one', () async {
      expect(
        () => insertTxn(db, id: uuidN(1), type: 'adjustment', finalAmount: 0),
        throwsA(isA<SqliteException>()),
      );
      await insertTxn(db, id: uuidN(2), type: 'adjustment', finalAmount: -300);
    });
    test('an uppercase or short uuid', () {
      expect(
        () => insertTxn(
          db,
          id: 'ABCDEF12-3456-4789-8ABC-DEF012345678',
          type: 'sale',
          finalAmount: 100,
        ),
        throwsA(isA<SqliteException>()),
      );
      expect(
        () => insertTxn(db, id: 'abc', type: 'sale', finalAmount: 100),
        throwsA(isA<SqliteException>()),
      );
    });
    test('a dd/MM/yyyy date', () {
      expect(
        () => insertTxn(
          db,
          id: uuidN(1),
          type: 'sale',
          finalAmount: 100,
          entryDate: '18/09/2026',
        ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  test(
    'signed_amount is computed by the database and agrees with BalanceEngine',
    () async {
      final cases = {
        'sale': 100,
        'cash_out': 100,
        'opening_balance': 100,
        'purchase': 100,
        'cash_in': 100,
        'adjustment': -40,
      };
      var n = 1;
      for (final e in cases.entries) {
        await insertTxn(
          db,
          id: uuidN(n),
          type: e.key,
          finalAmount: e.value,
          seq: n,
        );
        n++;
      }
      final rows = await db
          .customSelect(
            'SELECT type, final_amount, signed_amount FROM transactions',
          )
          .get();
      for (final r in rows) {
        final type = TransactionType.values.byName(
          _camel(r.read<String>('type')),
        );
        expect(
          r.read<int>('signed_amount'),
          signedAmountFor(type, Money(r.read<int>('final_amount'))).paisa,
          reason: r.read<String>('type'),
        );
      }
    },
  );

  test(
    'customer_balances sums live rows, excludes walk-ins and deleted rows',
    () async {
      await insertTxn(db, id: uuidN(1), type: 'sale', finalAmount: 500, seq: 1);
      await insertTxn(
        db,
        id: uuidN(2),
        type: 'cash_in',
        finalAmount: 200,
        seq: 2,
      );
      await insertTxn(db, id: uuidN(3), type: 'sale', finalAmount: 999, seq: 3);
      await db.customStatement(
        "UPDATE transactions SET deleted_at = 5 WHERE id = '${uuidN(3)}'",
      );
      await insertTxn(
        db,
        id: uuidN(4),
        customerId: null,
        type: 'sale',
        finalAmount: 12500,
        seq: 4,
      );
      final rows = await db
          .customSelect('SELECT customer_id, balance FROM customer_balances')
          .get();
      expect(rows.length, 1);
      expect(rows.single.read<String>('customer_id'), rashid);
      expect(rows.single.read<int>('balance'), 300);
    },
  );

  test('running balance query orders by entry_date, created_at, id', () async {
    await insertTxn(
      db,
      id: uuidN(1),
      type: 'sale',
      finalAmount: 100,
      entryDate: '2026-09-10',
      createdAt: 50,
      seq: 1,
    );
    await insertTxn(
      db,
      id: uuidN(2),
      type: 'sale',
      finalAmount: 100,
      entryDate: '2026-09-12',
      createdAt: 10,
      seq: 2,
    );
    await insertTxn(
      db,
      id: uuidN(3),
      type: 'cash_in',
      finalAmount: 50,
      entryDate: '2026-09-01',
      createdAt: 99,
      seq: 3,
    ); // backdated
    final rows = await db
        .customSelect(
          "SELECT id, SUM(signed_amount) OVER (ORDER BY entry_date, created_at, id) AS running FROM transactions WHERE customer_id = '$rashid' AND deleted_at IS NULL ORDER BY entry_date, created_at, id",
        )
        .get();
    expect(rows.map((r) => r.read<int>('running')), [-50, 50, 150]);
  });

  test('line totals are generated by the database and match RateCalculator on random inputs', () async {
    await insertTxn(db, id: uuidN(1), type: 'sale', finalAmount: 1);
    final rnd = Random(7);
    for (var i = 0; i < 300; i++) {
      final rate = rnd.nextInt(2000000) + 1;
      final weight = rnd.nextInt(5000000) + 1;
      final base = RateBase.presets[rnd.nextInt(RateBase.presets.length)];
      final override = i % 10 == 0 ? rate : null;
      await db.customStatement(
        'INSERT INTO transaction_lines (id, firm_id, transaction_id, line_no, item_id, uom, sale_mode, total_weight_g, rate_paisa, rate_base_weight_g, overridden_total) '
        "VALUES ('${uuidN(1000 + i)}','$firm','${uuidN(1)}',$i,'$oil','kg','by_weight',$weight,$rate,${base.grams},${override ?? 'NULL'})",
      );
      final row =
          (await db
                  .customSelect(
                    "SELECT calculated_total, final_amount FROM transaction_lines WHERE id = '${uuidN(1000 + i)}'",
                  )
                  .get())
              .single;
      final expected = lineTotalByWeight(
        rate: Money(rate),
        totalWeight: Weight(weight),
        rateBase: base,
      ).paisa;
      expect(row.read<int>('calculated_total'), expected);
      expect(row.read<int>('final_amount'), override ?? expected);
    }
  });

  test('a by_bags line without bag fields is rejected', () async {
    await insertTxn(db, id: uuidN(1), type: 'sale', finalAmount: 1);
    expect(
      () => db.customStatement(
        'INSERT INTO transaction_lines (id, firm_id, transaction_id, line_no, item_id, uom, sale_mode, total_weight_g, rate_paisa, rate_base_weight_g) '
        "VALUES ('${uuidN(2)}','$firm','${uuidN(1)}',1,'$oil','kg','by_bags',1000,100,40000)",
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('deleting a bill cascades to its lines', () async {
    await insertTxn(db, id: uuidN(1), type: 'sale', finalAmount: 1);
    await db.customStatement(
      'INSERT INTO transaction_lines (id, firm_id, transaction_id, line_no, item_id, uom, sale_mode, total_weight_g, rate_paisa, rate_base_weight_g) '
      "VALUES ('${uuidN(2)}','$firm','${uuidN(1)}',1,'$oil','kg','by_weight',1000,100,40000)",
    );
    await db.customStatement(
      "DELETE FROM transactions WHERE id = '${uuidN(1)}'",
    );
    final left = await db
        .customSelect('SELECT count(*) AS c FROM transaction_lines')
        .get();
    expect(left.single.read<int>('c'), 0);
  });

  test('the two partial indexes are used by the balance and ledger queries', () async {
    final plan1 = await db
        .customSelect(
          'EXPLAIN QUERY PLAN SELECT firm_id, customer_id, SUM(signed_amount) FROM transactions WHERE deleted_at IS NULL AND customer_id IS NOT NULL GROUP BY firm_id, customer_id',
        )
        .get();
    expect(
      plan1.map((r) => r.data['detail']).join(' '),
      contains('idx_txn_balance'),
    );
    final plan2 = await db
        .customSelect(
          "EXPLAIN QUERY PLAN SELECT * FROM transactions WHERE firm_id = '$firm' AND customer_id = '$rashid' AND deleted_at IS NULL ORDER BY entry_date, created_at, id",
        )
        .get();
    expect(
      plan2.map((r) => r.data['detail']).join(' '),
      contains('idx_txn_ledger'),
    );
  });
}

String _camel(String snake) {
  final parts = snake.split('_');
  return parts.first +
      parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
}
