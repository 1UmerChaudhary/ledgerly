import 'package:drift/drift.dart';
import 'package:ledgerly_core/ledgerly_core.dart';

import '../db/app_database.dart';
import '../device_context.dart';
import '../ids.dart';
import '../outbox.dart';

class ItemsRepository {
  ItemsRepository(this.db, this.ctx);

  final AppDatabase db;
  final DeviceContext ctx;

  Future<Item> create({
    required String name,
    Weight? defaultBagWeight,
    Weight? defaultRateBase,
    Uom defaultUom = Uom.kg,
  }) {
    return db.transaction(() async {
      final now = ctx.stamp();
      final id = newId();
      await db
          .into(db.items)
          .insert(
            ItemsCompanion.insert(
              id: id,
              firmId: ctx.firmId,
              name: name,
              nameNormalized: normalizeName(name),
              defaultBagWeightG: Value(defaultBagWeight?.grams),
              defaultRateBaseWeightG: Value(defaultRateBase?.grams),
              defaultUom: Value(defaultUom.name),
              createdByUserId: ctx.userId,
              createdAt: now,
              updatedAt: now,
              updatedByDeviceId: ctx.deviceId,
            ),
          );
      await enqueueOutbox(db, 'items', id, now);
      return Item(
        id: id,
        name: name,
        defaultBagWeight: defaultBagWeight,
        defaultRateBase: defaultRateBase,
        defaultUom: defaultUom,
      );
    });
  }

  Future<List<Item>> all() async {
    final rows =
        await (db.select(db.items)
              ..where((i) => i.deletedAt.isNull())
              ..orderBy([(i) => OrderingTerm.asc(i.nameNormalized)]))
            .get();
    return rows
        .map(
          (r) => Item(
            id: r.id,
            name: r.name,
            defaultBagWeight: r.defaultBagWeightG == null
                ? null
                : Weight(r.defaultBagWeightG!),
            defaultRateBase: r.defaultRateBaseWeightG == null
                ? null
                : Weight(r.defaultRateBaseWeightG!),
            defaultUom: Uom.values.byName(r.defaultUom),
          ),
        )
        .toList();
  }
}
