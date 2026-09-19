import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../device_context.dart';
import '../outbox.dart';

/// First launch: one firm, its owner, this device, and the sync bookkeeping row,
/// written together so a half-created firm can never exist.
class FirmSetup {
  FirmSetup(this.db, this.ctx);

  final AppDatabase db;
  final DeviceContext ctx;

  Future<void> createFirm({
    required String name,
    required String contactNumber,
    String? address,
    String ownerName = 'Owner',
    String deviceName = 'This device',
    String platform = 'desktop',
  }) {
    return db.transaction(() async {
      final now = ctx.stamp();
      final memberId = ctx.firmId.replaceRange(
        0,
        8,
        'aaaaaaaa',
      ); // stable per firm
      await db
          .into(db.firms)
          .insert(
            FirmsCompanion.insert(
              id: ctx.firmId,
              name: name,
              contactNumber: contactNumber,
              address: Value(address),
              createdAt: now,
              updatedAt: now,
              updatedByDeviceId: ctx.deviceId,
            ),
          );
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: ctx.userId,
              name: ownerName,
              createdAt: now,
              updatedAt: now,
              updatedByDeviceId: ctx.deviceId,
            ),
          );
      await db
          .into(db.firmMembers)
          .insert(
            FirmMembersCompanion.insert(
              id: memberId,
              firmId: ctx.firmId,
              userId: ctx.userId,
              role: 'owner',
              createdAt: now,
              updatedAt: now,
              updatedByDeviceId: ctx.deviceId,
            ),
          );
      await db
          .into(db.devices)
          .insert(
            DevicesCompanion.insert(
              id: ctx.deviceId,
              firmId: ctx.firmId,
              name: deviceName,
              platform: platform,
              shortCode: ctx.deviceShortCode,
              createdAt: now,
              updatedAt: now,
              updatedByDeviceId: ctx.deviceId,
            ),
          );
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(deviceId: ctx.deviceId));
      await enqueueOutbox(db, 'firms', ctx.firmId, now);
      await enqueueOutbox(db, 'users', ctx.userId, now);
      await enqueueOutbox(db, 'firm_members', memberId, now);
      await enqueueOutbox(db, 'devices', ctx.deviceId, now);
    });
  }
}
