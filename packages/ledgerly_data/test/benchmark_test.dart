@Tags(['benchmark'])
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:test/test.dart';

// Guards the "balances are computed, never stored" decision. If either query
// ever exceeds the budget on a realistic dataset, this fails in CI and we add
// a cache column with real numbers in hand, not a guess. Budgets are ~4x what
// this Mac measures (17 ms / 32 ms / 150 ms) because GitHub's shared runners
// are slower and noisy; the guard is against a slide into seconds.
void main() {
  test('ledger and balance queries stay fast with 200k transactions (budgets sized for CI runners)', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final ctx = DeviceContext(
      firmId: '11111111-1111-4111-8111-111111111111',
      deviceId: '22222222-2222-4222-8222-222222222222',
      deviceShortCode: 'A3F9',
      userId: '33333333-3333-4333-8333-333333333333',
      hlc: Hlc(clock: () => 1000),
    );
    await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
    await seedBenchmarkData(db, ctx, customers: 2000, transactions: 200000);

    final bills = BillsRepository(db, ctx);
    final customers = await CustomersRepository(db, ctx).all();
    final busiest = customers.first.id;

    final sw = Stopwatch()..start();
    final balances = await bills.balances();
    final balancesMs = sw.elapsedMilliseconds;
    sw.reset();
    final rawLedger = await db
        .customSelect(
          'SELECT id, SUM(signed_amount) OVER (ORDER BY entry_date, created_at, id) AS running '
          'FROM transactions WHERE firm_id = ? AND customer_id = ? AND deleted_at IS NULL '
          'ORDER BY entry_date, created_at, id',
          variables: [Variable(ctx.firmId), Variable(busiest)],
        )
        .get();
    final rawLedgerMs = sw.elapsedMilliseconds;
    sw.reset();
    final ledger = await bills.ledgerFor(busiest);
    final ledgerMs = sw.elapsedMilliseconds;

    // ignore: avoid_print -- the timings are the result of this test
    print(
      'customer_balances: ${balances.length} rows in $balancesMs ms; raw ledger: ${rawLedger.length} rows in $rawLedgerMs ms; ledgerFor objects: $ledgerMs ms',
    );
    expect(balances.length, greaterThan(1500));
    expect(
      balancesMs,
      lessThan(200),
      reason: 'balance aggregate must stay index-only',
    );
    expect(rawLedgerMs, lessThan(200), reason: 'running-balance window query');
    expect(ledger.length, 20000);
    expect(
      ledgerMs,
      lessThan(1500),
      reason: 'materialising 20k Bill objects with lines',
    );
    await db.close();
  }, timeout: const Timeout(Duration(minutes: 3)));
}
