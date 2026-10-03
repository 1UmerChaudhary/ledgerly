import 'package:drift/drift.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import 'backend_client.dart';

class PushSummary {
  const PushSummary({required this.accepted, required this.rejected});
  final int accepted;
  final Map<String, String> rejected;
}

/// Drains the local outbox to the backend, then pulls everything new back
/// down (docs/design-spec.md Section 4). One access token per instance —
/// the caller (the Settings sync UI) is responsible for refreshing it
/// before calling this; there's no in-flight 401-retry here yet.
///
/// A `rewrite` in a push response (the server auto-merged a customer this
/// device created into one it already had) is applied after the pull, once
/// the survivor exists locally: the device's copy is marked merged and its
/// bills move across. Rewrites live only for this instance's push+pull; if
/// the app dies in between, the pull-time phone-clash settling in
/// [_settlePhoneClash] still folds an unflagged duplicate the same way.
class SyncService {
  SyncService({
    required this.db,
    required this.ctx,
    required this.client,
    required this.accessToken,
  });

  final AppDatabase db;
  final DeviceContext ctx;
  final BackendClient client;
  final String accessToken;

  /// Customer id -> the id the server merged it into, from this instance's
  /// push, applied by [pullAll].
  final _rewrites = <String, String>{};

  /// Whether this sync merged any customer, so the bill move also checks
  /// deleted bills (a deleted bill of a merged customer still has to push).
  var _mergedThisSync = false;

  Future<PushSummary> pushPending() async {
    final outboxRows = await db.select(db.syncOutbox).get();
    final pending = <SyncOutboxRow>[];
    final pushRows = <BackendPushRow>[];
    for (final entry in outboxRows) {
      final data = await _currentRowData(entry.targetTable, entry.rowId);
      if (data == null) continue; // e.g. a table not wired up to sync yet
      pending.add(entry);
      pushRows.add(
        BackendPushRow(table: entry.targetTable, id: entry.rowId, data: data),
      );
    }
    if (pushRows.isEmpty) return const PushSummary(accepted: 0, rejected: {});

    final result = await client.push(
      accessToken: accessToken,
      firmId: ctx.firmId,
      deviceId: ctx.deviceId,
      rows: pushRows,
    );
    _rewrites.addAll(result.rewrites);

    for (final entry in pending) {
      if (result.accepted.containsKey(entry.rowId)) {
        // Only clears the row if queued_updated_at still matches what was
        // pushed — a fresh local edit that re-queued it mid-flight must
        // survive to be pushed again next time.
        await (db.delete(db.syncOutbox)..where(
              (o) =>
                  o.targetTable.equals(entry.targetTable) &
                  o.rowId.equals(entry.rowId) &
                  o.queuedUpdatedAt.equals(entry.queuedUpdatedAt),
            ))
            .go();
      } else if (result.rejected.containsKey(entry.rowId)) {
        await (db.update(db.syncOutbox)..where(
              (o) =>
                  o.targetTable.equals(entry.targetTable) &
                  o.rowId.equals(entry.rowId),
            ))
            .write(
              SyncOutboxCompanion(
                attempts: Value(entry.attempts + 1),
                failedReason: Value(result.rejected[entry.rowId]),
              ),
            );
      }
    }
    return PushSummary(
      accepted: result.accepted.length,
      rejected: result.rejected,
    );
  }

  Future<int> pullAll() async {
    final state = await (db.select(
      db.syncState,
    )..where((s) => s.deviceId.equals(ctx.deviceId))).getSingleOrNull();
    var cursor = state?.lastPullCursor ?? 0;
    var pulled = 0;
    while (true) {
      final page = await client.pull(
        accessToken: accessToken,
        firmId: ctx.firmId,
        since: cursor,
      );
      for (final row in page.rows) {
        await _applyPulledRow(row);
        pulled++;
      }
      cursor = page.nextCursor;
      await db
          .into(db.syncState)
          .insertOnConflictUpdate(
            SyncStateCompanion(
              deviceId: Value(ctx.deviceId),
              lastPullCursor: Value(cursor),
              lastSyncAt: Value(ctx.stamp()),
            ),
          );
      if (!page.hasMore) break;
    }
    await _applyRewrites();
    await _moveBillsOffMergedCustomers();
    return pulled;
  }

  /// Marks each customer the server merged away as merged into its
  /// survivor -- the server's own answer, not a guess, so it also covers a
  /// survivor that arrived flagged needs_review (which [_settlePhoneClash]
  /// leaves alone, since a flagged row can't clash on the phone index).
  /// Skipped while the survivor isn't local yet.
  Future<void> _applyRewrites() async {
    for (final MapEntry(key: oldId, value: newId) in _rewrites.entries) {
      final survivor = await (db.select(
        db.customers,
      )..where((c) => c.id.equals(newId))).getSingleOrNull();
      if (survivor == null) continue;
      final stamp = ctx.stamp();
      final changed =
          await (db.update(db.customers)..where(
                (c) =>
                    c.id.equals(oldId) &
                    c.mergedIntoId.isNull() &
                    c.deletedAt.isNull(),
              ))
              .write(
                CustomersCompanion(
                  mergedIntoId: Value(newId),
                  updatedAt: Value(stamp),
                  updatedByDeviceId: Value(ctx.deviceId),
                ),
              );
      if (changed > 0) {
        await enqueueOutbox(db, 'customers', oldId, stamp);
        _mergedThisSync = true;
      }
    }
    _rewrites.clear();
  }

  /// Repoints every bill whose customer has been merged away onto the
  /// customer it merged into, and queues it. The server refuses a bill for
  /// a customer it never created (an auto-merged duplicate), so such a bill
  /// would otherwise be rejected on every push; and a merged-away customer
  /// is hidden, so its bills would vanish from every ledger. Derived from
  /// the rows themselves rather than remembered, so a crash between the
  /// merge and this step just means the next pull finishes it.
  Future<void> _moveBillsOffMergedCustomers() async {
    final mergedInto = {
      for (final c in await (db.select(
        db.customers,
      )..where((c) => c.mergedIntoId.isNotNull())).get())
        c.id: c.mergedIntoId!,
    };
    if (mergedInto.isEmpty) return;
    String survivorOf(String id) {
      var current = id;
      // Bounded: a merge chain (A into B into C) is short, a cycle is a bug.
      for (var hops = 0; hops < 10; hops++) {
        current = mergedInto[current] ?? current;
      }
      return current;
    }

    await db.transaction(() async {
      // Live bills only, normally: `deleted_at IS NULL` lets this use the
      // partial ledger index instead of scanning every bill on every sync.
      // A deleted bill of a just-merged customer still has to push, so a
      // sync that merged something checks those too.
      final includeDeleted = _mergedThisSync;
      final bills =
          await (db.select(db.transactions)..where(
                (t) =>
                    t.firmId.equals(ctx.firmId) &
                    t.customerId.isIn(mergedInto.keys) &
                    (includeDeleted
                        ? const Constant(true)
                        : t.deletedAt.isNull()),
              ))
              .get();
      for (final bill in bills) {
        final stamp = ctx.stamp();
        await (db.update(
          db.transactions,
        )..where((t) => t.id.equals(bill.id))).write(
          TransactionsCompanion(
            customerId: Value(survivorOf(bill.customerId!)),
            updatedAt: Value(stamp),
            updatedByDeviceId: Value(ctx.deviceId),
            updatedByUserId: Value(ctx.userId),
          ),
        );
        await enqueueOutbox(db, 'transactions', bill.id, stamp);
        // Whatever the server said about the old customer (usually
        // "invalid": it never had that customer) no longer applies.
        await (db.update(db.syncOutbox)..where(
              (o) =>
                  o.targetTable.equals('transactions') &
                  o.rowId.equals(bill.id),
            ))
            .write(
              const SyncOutboxCompanion(
                attempts: Value(0),
                failedReason: Value(null),
              ),
            );
      }
    });
    _mergedThisSync = false;
  }

  /// A pulled customer [id] whose phone a different live, unflagged local
  /// customer already has -- which the device's unique-phone index would
  /// refuse, failing this pull at this row on every sync from then on. Two
  /// devices adding the same customer before syncing is ordinary use, and
  /// the server accepts it, so this settles it the way the server does:
  /// - same name: the server auto-merged them, so the local copy folds into
  ///   the pulled one. The pulled one always survives -- it's the copy the
  ///   server has, so a merge into it can never point at a customer the
  ///   server lacks. The local copy's bills follow it after the pull.
  /// - different name: the server keeps both and flags them needs_review;
  ///   flagging the local one too lets both be held until someone decides.
  /// The local change is queued either way, so the server hears it.
  Future<void> _settlePhoneClash(String id, Map<String, dynamic> data) async {
    final phone = data['phone_normalized'] as String?;
    final indexed =
        phone != null &&
        data['deleted_at'] == null &&
        data['merged_into_id'] == null &&
        data['needs_review'] != true;
    if (!indexed) return;
    final clash =
        await (db.select(db.customers)..where(
              (c) =>
                  c.firmId.equals(ctx.firmId) &
                  c.phoneNormalized.equals(phone) &
                  c.id.equals(id).not() &
                  c.deletedAt.isNull() &
                  c.mergedIntoId.isNull() &
                  c.needsReview.equals(false),
            ))
            .getSingleOrNull();
    if (clash == null) return;
    final sameName = clash.nameNormalized == data['name_normalized'];
    final stamp = ctx.stamp();
    await (db.update(db.customers)..where((c) => c.id.equals(clash.id))).write(
      CustomersCompanion(
        mergedIntoId: sameName ? Value(id) : const Value.absent(),
        needsReview: sameName ? const Value.absent() : const Value(true),
        updatedAt: Value(stamp),
        updatedByDeviceId: Value(ctx.deviceId),
      ),
    );
    await enqueueOutbox(db, 'customers', clash.id, stamp);
    if (sameName) _mergedThisSync = true;
  }

  Future<Map<String, dynamic>?> _currentRowData(String table, String id) async {
    switch (table) {
      case 'items':
        final row = await (db.select(
          db.items,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        if (row == null) return null;
        return {
          'name': row.name,
          'name_normalized': row.nameNormalized,
          'default_bag_weight_g': row.defaultBagWeightG,
          'default_rate_base_weight_g': row.defaultRateBaseWeightG,
          'default_uom': row.defaultUom,
          'track_stock': row.trackStock,
          'created_by_user_id': row.createdByUserId,
          'created_at': row.createdAt,
          'updated_at': row.updatedAt,
          'updated_by_device_id': row.updatedByDeviceId,
          'deleted_at': row.deletedAt,
        };
      case 'customers':
        final row = await (db.select(
          db.customers,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        if (row == null) return null;
        return {
          'name': row.name,
          'name_normalized': row.nameNormalized,
          'phone': row.phone,
          'phone_normalized': row.phoneNormalized,
          'notes': row.notes,
          'created_by_user_id': row.createdByUserId,
          'merged_into_id': row.mergedIntoId,
          'needs_review': row.needsReview,
          'created_at': row.createdAt,
          'updated_at': row.updatedAt,
          'updated_by_device_id': row.updatedByDeviceId,
          'deleted_at': row.deletedAt,
        };
      case 'transactions':
        final header = await (db.select(
          db.transactions,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        if (header == null) return null;
        final lines =
            await (db.select(db.transactionLines)
                  ..where((l) => l.transactionId.equals(id))
                  ..orderBy([(l) => OrderingTerm(expression: l.lineNo)]))
                .get();
        return {
          'customer_id': header.customerId,
          'device_short_code': header.deviceShortCode,
          'display_seq': header.displaySeq,
          'type': header.type,
          'entry_date': header.entryDate,
          'description': header.description,
          'version': header.version,
          'calculated_total': header.calculatedTotal,
          'overridden_total': header.overriddenTotal,
          'overridden_total_basis': header.overriddenTotalBasis,
          'final_amount': header.finalAmount,
          'created_by_user_id': header.createdByUserId,
          'updated_by_user_id': header.updatedByUserId,
          'created_at': header.createdAt,
          'updated_at': header.updatedAt,
          'updated_by_device_id': header.updatedByDeviceId,
          'deleted_at': header.deletedAt,
          'lines': [
            for (final l in lines)
              {
                'id': l.id,
                'line_no': l.lineNo,
                'item_id': l.itemId,
                'uom': l.uom,
                'sale_mode': l.saleMode,
                'bag_count': l.bagCount,
                'bag_weight_g': l.bagWeightG,
                'total_weight_g': l.totalWeightG,
                'quantity': l.quantity,
                'rate_paisa': l.ratePaisa,
                'rate_base_weight_g': l.rateBaseWeightG,
                'overridden_total': l.overriddenTotal,
              },
          ],
        };
      default:
        return null; // not wired up to sync yet (print_log, ...)
    }
  }

  Future<void> _applyPulledRow(BackendPullRow row) async {
    final data = row.data;
    switch (row.table) {
      case 'items':
        await db
            .into(db.items)
            .insertOnConflictUpdate(
              ItemsCompanion(
                id: Value(row.id),
                firmId: Value(ctx.firmId),
                name: Value(data['name'] as String),
                nameNormalized: Value(data['name_normalized'] as String),
                defaultBagWeightG: Value(data['default_bag_weight_g'] as int?),
                defaultRateBaseWeightG: Value(
                  data['default_rate_base_weight_g'] as int?,
                ),
                defaultUom: Value(data['default_uom'] as String),
                trackStock: Value(data['track_stock'] as bool),
                createdByUserId: Value(data['created_by_user_id'] as String),
                createdAt: Value(data['created_at'] as int),
                updatedAt: Value(data['updated_at'] as int),
                updatedByDeviceId: Value(
                  data['updated_by_device_id'] as String,
                ),
                deletedAt: Value(data['deleted_at'] as int?),
              ),
            );
        return;
      case 'customers':
        await db.transaction(() async {
          // A merge points the local copy at the pulled row before that row
          // is written, so the foreign-key check waits for the commit.
          await db.customStatement('PRAGMA defer_foreign_keys = ON');
          await _settlePhoneClash(row.id, data);
          await db
              .into(db.customers)
              .insertOnConflictUpdate(
                CustomersCompanion(
                  id: Value(row.id),
                  firmId: Value(ctx.firmId),
                  name: Value(data['name'] as String),
                  nameNormalized: Value(data['name_normalized'] as String),
                  phone: Value(data['phone'] as String?),
                  phoneNormalized: Value(data['phone_normalized'] as String?),
                  notes: Value(data['notes'] as String?),
                  createdByUserId: Value(data['created_by_user_id'] as String),
                  mergedIntoId: Value(data['merged_into_id'] as String?),
                  needsReview: Value(data['needs_review'] as bool),
                  createdAt: Value(data['created_at'] as int),
                  updatedAt: Value(data['updated_at'] as int),
                  updatedByDeviceId: Value(
                    data['updated_by_device_id'] as String,
                  ),
                  deletedAt: Value(data['deleted_at'] as int?),
                ),
              );
        });
        return;
      case 'transactions':
        await db.transaction(() async {
          await db
              .into(db.transactions)
              .insertOnConflictUpdate(
                TransactionsCompanion(
                  id: Value(row.id),
                  firmId: Value(ctx.firmId),
                  customerId: Value(data['customer_id'] as String?),
                  deviceShortCode: Value(data['device_short_code'] as String),
                  displaySeq: Value(data['display_seq'] as int),
                  type: Value(data['type'] as String),
                  entryDate: Value(data['entry_date'] as String),
                  description: Value(data['description'] as String?),
                  version: Value(data['version'] as int),
                  calculatedTotal: Value(data['calculated_total'] as int),
                  overriddenTotal: Value(data['overridden_total'] as int?),
                  overriddenTotalBasis: Value(
                    data['overridden_total_basis'] as int?,
                  ),
                  finalAmount: Value(data['final_amount'] as int),
                  createdByUserId: Value(data['created_by_user_id'] as String),
                  updatedByUserId: Value(data['updated_by_user_id'] as String),
                  createdAt: Value(data['created_at'] as int),
                  updatedAt: Value(data['updated_at'] as int),
                  updatedByDeviceId: Value(
                    data['updated_by_device_id'] as String,
                  ),
                  deletedAt: Value(data['deleted_at'] as int?),
                ),
              );
          // A bill's lines are always replaced wholesale, never diffed —
          // same rule as the server (docs/design-spec.md Section 2).
          await (db.delete(
            db.transactionLines,
          )..where((l) => l.transactionId.equals(row.id))).go();
          for (final raw
              in (data['lines'] as List).cast<Map<String, dynamic>>()) {
            await db
                .into(db.transactionLines)
                .insertOnConflictUpdate(
                  TransactionLinesCompanion(
                    id: Value(raw['id'] as String),
                    firmId: Value(ctx.firmId),
                    transactionId: Value(row.id),
                    lineNo: Value(raw['line_no'] as int),
                    itemId: Value(raw['item_id'] as String),
                    uom: Value(raw['uom'] as String),
                    saleMode: Value(raw['sale_mode'] as String),
                    bagCount: Value(raw['bag_count'] as int?),
                    bagWeightG: Value(raw['bag_weight_g'] as int?),
                    totalWeightG: Value(raw['total_weight_g'] as int?),
                    quantity: Value(raw['quantity'] as int?),
                    ratePaisa: Value(raw['rate_paisa'] as int),
                    rateBaseWeightG: Value(raw['rate_base_weight_g'] as int?),
                    overriddenTotal: Value(raw['overridden_total'] as int?),
                  ),
                );
          }
        });
        return;
      default:
        return; // not wired up to sync yet
    }
  }
}
