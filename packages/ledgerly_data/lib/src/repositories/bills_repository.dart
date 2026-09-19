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

  /// Null for a deleted bill shown via `includeDeleted`: a deleted row never
  /// moves the running total, so it has no meaningful balance of its own.
  final Money? runningBalance;
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

  /// [includeDeleted] additionally returns soft-deleted bills, interleaved by
  /// date, with a null [LedgerEntry.runningBalance] — a "show deleted" toggle
  /// reveals them without them ever moving the real running total.
  Future<List<LedgerEntry>> ledgerFor(
    String customerId, {
    bool includeDeleted = false,
  }) async {
    final headers = await db
        .customSelect(
          'SELECT t.*, SUM(signed_amount) OVER (ORDER BY entry_date, created_at, id) AS running '
          'FROM transactions t WHERE firm_id = ? AND customer_id = ? AND deleted_at IS NULL '
          'ORDER BY entry_date, created_at, id',
          variables: [Variable(ctx.firmId), Variable(customerId)],
          readsFrom: {db.transactions},
        )
        .get();
    final deletedHeaders = includeDeleted
        ? await db
              .customSelect(
                'SELECT * FROM transactions '
                'WHERE firm_id = ? AND customer_id = ? AND deleted_at IS NOT NULL '
                'ORDER BY entry_date, created_at, id',
                variables: [Variable(ctx.firmId), Variable(customerId)],
                readsFrom: {db.transactions},
              )
              .get()
        : const <QueryRow>[];
    if (headers.isEmpty && deletedHeaders.isEmpty) return const [];

    final ids = [
      for (final r in headers) r.read<String>('id'),
      for (final r in deletedHeaders) r.read<String>('id'),
    ];
    final lines = await (db.select(
      db.transactionLines,
    )..where((l) => l.transactionId.isIn(ids))).get();
    final byBill = <String, List<TransactionLineRow>>{};
    for (final l in lines) {
      (byBill[l.transactionId] ??= []).add(l);
    }

    final entries =
        <(String entryDate, int createdAt, String id, LedgerEntry entry)>[
          for (final r in headers)
            (
              r.read<String>('entry_date'),
              r.read<int>('created_at'),
              r.read<String>('id'),
              LedgerEntry(
                BillCodec.fromRows(
                  db.transactions.map(r.data),
                  byBill[r.read<String>('id')] ?? const [],
                ),
                Money(r.read<int>('running')),
              ),
            ),
          for (final r in deletedHeaders)
            (
              r.read<String>('entry_date'),
              r.read<int>('created_at'),
              r.read<String>('id'),
              LedgerEntry(
                BillCodec.fromRows(
                  db.transactions.map(r.data),
                  byBill[r.read<String>('id')] ?? const [],
                ),
                null,
              ),
            ),
        ]..sort((a, b) {
          final byDate = a.$1.compareTo(b.$1);
          if (byDate != 0) return byDate;
          final byCreated = a.$2.compareTo(b.$2);
          if (byCreated != 0) return byCreated;
          return a.$3.compareTo(b.$3);
        });
    return [for (final e in entries) e.$4];
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

  /// Counter sales with no customer — never appear in any ledger. Uses
  /// idx_txn_walkin (firm_id, entry_date WHERE customer_id IS NULL).
  Future<List<Bill>> walkInSales({String? fromDate, String? toDate}) async {
    final query = db.select(db.transactions)
      ..where(
        (t) =>
            t.firmId.equals(ctx.firmId) &
            t.customerId.isNull() &
            t.deletedAt.isNull(),
      )
      ..orderBy([
        (t) => OrderingTerm.asc(t.entryDate),
        (t) => OrderingTerm.asc(t.createdAt),
      ]);
    if (fromDate != null) {
      query.where((t) => t.entryDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where((t) => t.entryDate.isSmallerOrEqualValue(toDate));
    }
    final headers = await query.get();
    if (headers.isEmpty) return const [];
    final ids = headers.map((h) => h.id).toList();
    final lines = await (db.select(
      db.transactionLines,
    )..where((l) => l.transactionId.isIn(ids))).get();
    final byBill = <String, List<TransactionLineRow>>{};
    for (final l in lines) {
      (byBill[l.transactionId] ??= []).add(l);
    }
    return [
      for (final h in headers) BillCodec.fromRows(h, byBill[h.id] ?? const []),
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
          // Any rewrite (edit or restore) brings a bill back to life: a
          // restore of a deleted bill's history must actually undelete it.
          deletedAt: const Value(null),
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
