import 'package:drift/drift.dart';
import 'package:ledgerly_core/ledgerly_core.dart';

import '../bill_codec.dart';
import '../db/app_database.dart';
import '../device_context.dart';
import '../ids.dart';
import '../outbox.dart';

class LedgerEntry {
  const LedgerEntry(this.bill, this.runningBalance);
  final Bill bill;
  final Money runningBalance;
}

class HistoryEntry {
  const HistoryEntry({
    required this.version,
    required this.reason,
    required this.changedAt,
    required this.changedByDeviceId,
    required this.bill,
  });
  final int version;
  final String reason;
  final int changedAt;
  final String changedByDeviceId;

  /// The bill as it was BEFORE the change this entry records.
  final Bill bill;
}

class CustomerBalanceEntry {
  const CustomerBalanceEntry(this.customerId, this.balance);
  final String customerId;
  final Money balance;
}

/// Every write is one SQLite transaction: history snapshot, header, lines,
/// outbox. A crash between steps leaves nothing half-done.
class BillsRepository {
  BillsRepository(this.db, this.ctx);

  final AppDatabase db;
  final DeviceContext ctx;

  Future<Bill> saveNew(Bill bill) {
    return db.transaction(() async {
      final now = ctx.stamp();
      final seq = nextDisplaySeq(await _maxSeqForDevice());
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: bill.id,
              firmId: ctx.firmId,
              customerId: Value(bill.customerId),
              deviceShortCode: ctx.deviceShortCode,
              displaySeq: seq,
              type: BillCodec.snake(bill.type.name),
              entryDate: bill.entryDate,
              description: Value(bill.description),
              version: const Value(1),
              calculatedTotal: bill.calculatedTotal.paisa,
              overriddenTotal: Value(bill.overriddenTotal?.paisa),
              overriddenTotalBasis: Value(bill.overriddenTotalBasis?.paisa),
              finalAmount: bill.finalAmount.paisa,
              createdByUserId: ctx.userId,
              updatedByUserId: ctx.userId,
              createdAt: now,
              updatedAt: now,
              updatedByDeviceId: ctx.deviceId,
            ),
          );
      await _insertLines(bill);
      await enqueueOutbox(db, 'transactions', bill.id, now);
      return bill.copyWith(
        version: 1,
        displayNo: renderDisplayNo(ctx.deviceShortCode, seq),
      );
    });
  }

  Future<Bill> edit(Bill bill) => _rewrite(bill, reason: 'edit');

  Future<void> delete(String billId) {
    return db.transaction(() async {
      final current = await byId(billId);
      if (current == null) throw StateError('No bill $billId');
      final now = ctx.stamp();
      await _writeHistory(current, reason: 'delete', at: now);
      await (db.update(
        db.transactions,
      )..where((t) => t.id.equals(billId))).write(
        TransactionsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          updatedByDeviceId: Value(ctx.deviceId),
          updatedByUserId: Value(ctx.userId),
          version: Value(current.version + 1),
        ),
      );
      await enqueueOutbox(db, 'transactions', billId, now);
    });
  }

  /// Restoring never rewinds: the old snapshot is applied as a NEW version, so
  /// history stays a straight line and sync sees an ordinary edit.
  Future<Bill> restoreVersion(String billId, {required int version}) async {
    final row =
        await (db.select(db.transactionHistory)..where(
              (h) => h.transactionId.equals(billId) & h.version.equals(version),
            ))
            .getSingle();
    final old = BillCodec.fromSnapshot(row.snapshot);
    final current = await byId(billId);
    if (current == null) throw StateError('No bill $billId');
    return _rewrite(old.copyWith(version: current.version), reason: 'restore');
  }

  Future<Bill?> byId(String id) async {
    final h = await (db.select(
      db.transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (h == null) return null;
    final lines = await (db.select(
      db.transactionLines,
    )..where((l) => l.transactionId.equals(id))).get();
    return BillCodec.fromRows(h, lines);
  }

  Future<List<LedgerEntry>> ledgerFor(String customerId) async {
    final headers = await db
        .customSelect(
          'SELECT t.*, SUM(signed_amount) OVER (ORDER BY entry_date, created_at, id) AS running '
          'FROM transactions t WHERE firm_id = ? AND customer_id = ? AND deleted_at IS NULL '
          'ORDER BY entry_date, created_at, id',
          variables: [Variable(ctx.firmId), Variable(customerId)],
          readsFrom: {db.transactions},
        )
        .get();
    if (headers.isEmpty) return const [];
    // Join instead of `IN (20k ids)`: no parameter-count limit, one index walk.
    final lines = await db
        .customSelect(
          'SELECT l.* FROM transaction_lines l JOIN transactions t ON t.id = l.transaction_id '
          'WHERE t.firm_id = ? AND t.customer_id = ? AND t.deleted_at IS NULL',
          variables: [Variable(ctx.firmId), Variable(customerId)],
          readsFrom: {db.transactionLines, db.transactions},
        )
        .map((r) => db.transactionLines.map(r.data))
        .get();
    final byBill = <String, List<TransactionLineRow>>{};
    for (final l in lines) {
      (byBill[l.transactionId] ??= []).add(l);
    }
    return [
      for (final r in headers)
        LedgerEntry(
          BillCodec.fromRows(
            db.transactions.map(r.data),
            byBill[r.read<String>('id')] ?? const [],
          ),
          Money(r.read<int>('running')),
        ),
    ];
  }

  /// Prior versions of a bill, newest first. Each snapshot is the bill as it
  /// was before that change; the live row is the current version.
  Future<List<HistoryEntry>> historyFor(String billId) async {
    final rows =
        await (db.select(db.transactionHistory)
              ..where((h) => h.transactionId.equals(billId))
              ..orderBy([
                (h) => OrderingTerm.desc(h.changedAt),
                (h) => OrderingTerm.desc(h.version),
              ]))
            .get();
    return [
      for (final r in rows)
        HistoryEntry(
          version: r.version,
          reason: r.reason,
          changedAt: r.changedAt,
          changedByDeviceId: r.changedByDeviceId,
          bill: BillCodec.fromSnapshot(r.snapshot),
        ),
    ];
  }

  /// Signed balance of one customer, straight from the transactions.
  Future<Money> balanceFor(String customerId) async {
    final row = await db
        .customSelect(
          'SELECT COALESCE(SUM(signed_amount), 0) AS b FROM transactions '
          'WHERE firm_id = ? AND customer_id = ? AND deleted_at IS NULL',
          variables: [Variable(ctx.firmId), Variable(customerId)],
          readsFrom: {db.transactions},
        )
        .getSingle();
    return Money(row.read<int>('b'));
  }

  Future<List<CustomerBalanceEntry>> balances() async {
    final rows =
        await (db.select(db.customerBalances)
              ..where((b) => b.firmId.equals(ctx.firmId))
              ..orderBy([(b) => OrderingTerm.desc(b.balance)]))
            .get();
    return rows
        .map((r) => CustomerBalanceEntry(r.customerId!, Money(r.balance!)))
        .toList();
  }

  Future<Bill> _rewrite(Bill bill, {required String reason}) {
    return db.transaction(() async {
      final current = await byId(bill.id);
      if (current == null) throw StateError('No bill ${bill.id}');
      final now = ctx.stamp();
      await _writeHistory(current, reason: reason, at: now);
      final next = bill.copyWith(
        version: current.version + 1,
        displayNo: current.displayNo,
      );
      await (db.update(
        db.transactions,
      )..where((t) => t.id.equals(bill.id))).write(
        TransactionsCompanion(
          customerId: Value(next.customerId),
          entryDate: Value(next.entryDate),
          description: Value(next.description),
          version: Value(next.version),
          calculatedTotal: Value(next.calculatedTotal.paisa),
          overriddenTotal: Value(next.overriddenTotal?.paisa),
          overriddenTotalBasis: Value(next.overriddenTotalBasis?.paisa),
          finalAmount: Value(next.finalAmount.paisa),
          updatedByUserId: Value(ctx.userId),
          updatedAt: Value(now),
          updatedByDeviceId: Value(ctx.deviceId),
        ),
      );
      await (db.delete(
        db.transactionLines,
      )..where((l) => l.transactionId.equals(bill.id))).go();
      await _insertLines(next);
      await enqueueOutbox(db, 'transactions', bill.id, now);
      return next;
    });
  }

  Future<void> _writeHistory(
    Bill current, {
    required String reason,
    required int at,
  }) async {
    final row = await (db.select(
      db.transactions,
    )..where((t) => t.id.equals(current.id))).getSingle();
    await db
        .into(db.transactionHistory)
        .insert(
          TransactionHistoryCompanion.insert(
            id: historyId(current.id, row.updatedAt, row.updatedByDeviceId),
            firmId: ctx.firmId,
            transactionId: current.id,
            version: current.version,
            snapshot: BillCodec.snapshot(current),
            reason: reason,
            changedAt: at,
            changedByUserId: ctx.userId,
            changedByDeviceId: ctx.deviceId,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _insertLines(Bill bill) async {
    for (final l in bill.lines) {
      await db
          .into(db.transactionLines)
          .insert(
            TransactionLinesCompanion.insert(
              id: l.id,
              firmId: ctx.firmId,
              transactionId: bill.id,
              lineNo: l.lineNo,
              itemId: l.itemId,
              uom: Value(l.uom.name),
              saleMode: BillCodec.snake(l.saleMode.name),
              bagCount: Value(l.bagCount),
              bagWeightG: Value(l.bagWeight?.grams),
              totalWeightG: Value(l.totalWeight?.grams),
              quantity: Value(l.quantity),
              ratePaisa: l.rate.paisa,
              rateBaseWeightG: Value(l.rateBase?.grams),
              overriddenTotal: Value(l.overriddenTotal?.paisa),
            ),
          );
    }
  }

  Future<int?> _maxSeqForDevice() async {
    final row = await db
        .customSelect(
          'SELECT MAX(display_seq) AS m FROM transactions WHERE firm_id = ? AND device_short_code = ?',
          variables: [Variable(ctx.firmId), Variable(ctx.deviceShortCode)],
        )
        .getSingle();
    return row.data['m'] as int?;
  }
}
