import 'package:drift/drift.dart';
import 'package:ledgerly_core/ledgerly_core.dart';

import '../db/app_database.dart';
import '../device_context.dart';
import '../outbox.dart';

class FirmsRepository {
  FirmsRepository(this.db, this.ctx);

  final AppDatabase db;
  final DeviceContext ctx;

  Future<Firm> get() async {
    final r = await (db.select(
      db.firms,
    )..where((f) => f.id.equals(ctx.firmId))).getSingle();
    return Firm(
      id: r.id,
      name: r.name,
      contactNumber: r.contactNumber,
      address: r.address,
      showPaisa: r.showPaisa,
      grouping: r.numberGrouping == 'western'
          ? NumberGrouping.western
          : NumberGrouping.pakistani,
      defaultCountryCode: r.defaultCountryCode,
    );
  }

  /// Only the fields passed change; the row is stamped and queued for sync.
  Future<void> update({
    String? name,
    String? contactNumber,
    String? address,
    bool clearAddress = false,
    bool? showPaisa,
    NumberGrouping? grouping,
    String? defaultCountryCode,
  }) {
    return db.transaction(() async {
      final now = ctx.stamp();
      await (db.update(db.firms)..where((f) => f.id.equals(ctx.firmId))).write(
        FirmsCompanion(
          name: name == null ? const Value.absent() : Value(name),
          contactNumber: contactNumber == null
              ? const Value.absent()
              : Value(contactNumber),
          address: clearAddress
              ? const Value(null)
              : (address == null ? const Value.absent() : Value(address)),
          showPaisa: showPaisa == null
              ? const Value.absent()
              : Value(showPaisa),
          numberGrouping: grouping == null
              ? const Value.absent()
              : Value(grouping == NumberGrouping.western ? 'western' : 'pk'),
          defaultCountryCode: defaultCountryCode == null
              ? const Value.absent()
              : Value(defaultCountryCode),
          updatedAt: Value(now),
          updatedByDeviceId: Value(ctx.deviceId),
        ),
      );
      await enqueueOutbox(db, 'firms', ctx.firmId, now);
    });
  }
}
