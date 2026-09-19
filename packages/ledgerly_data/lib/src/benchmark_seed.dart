import 'db/app_database.dart';
import 'device_context.dart';

/// Fills a database with synthetic customers and transactions using recursive
/// CTEs, so 200k rows take seconds, not minutes. Test/benchmark use only.
Future<void> seedBenchmarkData(
  AppDatabase db,
  DeviceContext ctx, {
  required int customers,
  required int transactions,
}) async {
  await db.transaction(() async {
    await db.customStatement('''
      WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < $customers)
      INSERT INTO customers (id, firm_id, name, name_normalized, created_by_user_id, created_at, updated_at, updated_by_device_id)
      SELECT printf('%08x-%04x-4%03x-8%03x-%012x', n, n, n % 4096, n % 4096, n),
             '${ctx.firmId}', printf('Customer %06d', n), printf('customer %06d', n),
             '${ctx.userId}', n, n, '${ctx.deviceId}'
      FROM seq
    ''');
    // Customer 1 receives every 10th transaction so one ledger is genuinely long.
    await db.customStatement('''
      WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < $transactions),
      rows AS (
        SELECT n, CASE WHEN n % 10 = 0 THEN 1 ELSE (n % $customers) + 1 END AS c FROM seq
      )
      INSERT INTO transactions (id, firm_id, customer_id, device_short_code, display_seq, type, entry_date, version,
                                calculated_total, final_amount, created_by_user_id, updated_by_user_id,
                                created_at, updated_at, updated_by_device_id)
      SELECT printf('%08x-%04x-4%03x-8%03x-%012x', n, n % 65536, n % 4096, n % 4096, n),
             '${ctx.firmId}',
             printf('%08x-%04x-4%03x-8%03x-%012x', c, c, c % 4096, c % 4096, c),
             'A3F9', n,
             CASE n % 4 WHEN 0 THEN 'sale' WHEN 1 THEN 'purchase' WHEN 2 THEN 'cash_in' ELSE 'cash_out' END,
             date('2020-01-01', '+' || (n % 2000) || ' days'), 1,
             (n % 100000) + 1, (n % 100000) + 1,
             '${ctx.userId}', '${ctx.userId}', n, n, '${ctx.deviceId}'
      FROM rows
    ''');
  });
}
