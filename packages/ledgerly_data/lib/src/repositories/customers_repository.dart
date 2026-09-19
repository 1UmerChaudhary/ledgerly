import 'package:drift/drift.dart';
import 'package:ledgerly_core/ledgerly_core.dart';

import '../db/app_database.dart';
import '../device_context.dart';
import '../ids.dart';
import '../outbox.dart';

/// Thrown when a phone number already belongs to a live customer. Phone is the
/// duplicate key; names are only a warning (see design spec, Section 2).
class DuplicatePhoneException implements Exception {
  DuplicatePhoneException(this.existing);
  final Customer existing;
  @override
  String toString() => 'Phone already belongs to ${existing.name}';
}

class CustomersRepository {
  CustomersRepository(this.db, this.ctx);

  final AppDatabase db;
  final DeviceContext ctx;

  Future<Customer> create({
    required String name,
    String? phone,
    String? notes,
    String defaultCountryCode = '92',
  }) {
    return db.transaction(() async {
      final normalized = phone == null
          ? null
          : normalizePhone(phone, defaultCountryCode: defaultCountryCode);
      if (normalized != null) {
        final clash = await byPhone(normalized);
        if (clash != null) throw DuplicatePhoneException(clash);
      }
      final now = ctx.stamp();
      final id = newId();
      await db
          .into(db.customers)
          .insert(
            CustomersCompanion.insert(
              id: id,
              firmId: ctx.firmId,
              name: name,
              nameNormalized: normalizeName(name),
              phone: Value(phone),
              phoneNormalized: Value(normalized),
              notes: Value(notes),
              createdByUserId: ctx.userId,
              createdAt: now,
              updatedAt: now,
              updatedByDeviceId: ctx.deviceId,
            ),
          );
      await enqueueOutbox(db, 'customers', id, now);
      return Customer(
        id: id,
        name: name,
        phone: phone,
        phoneNormalized: normalized,
        notes: notes,
      );
    });
  }

  Future<Customer?> byPhone(String phoneNormalized) async {
    final row =
        await (db.select(db.customers)..where(
              (c) =>
                  c.phoneNormalized.equals(phoneNormalized) &
                  c.deletedAt.isNull() &
                  c.mergedIntoId.isNull(),
            ))
            .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  Future<Customer?> byId(String id) async {
    final row = await (db.select(
      db.customers,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  Future<List<Customer>> all() async {
    final rows =
        await (db.select(db.customers)
              ..where((c) => c.deletedAt.isNull() & c.mergedIntoId.isNull())
              ..orderBy([(c) => OrderingTerm.asc(c.nameNormalized)]))
            .get();
    return rows.map(_toEntity).toList();
  }

  Customer _toEntity(CustomerRow r) => Customer(
    id: r.id,
    name: r.name,
    phone: r.phone,
    phoneNormalized: r.phoneNormalized,
    notes: r.notes,
    needsReview: r.needsReview,
  );
}
