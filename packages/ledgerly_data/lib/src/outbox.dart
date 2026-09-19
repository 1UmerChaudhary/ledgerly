import 'db/app_database.dart';

/// Records that a row changed and has not been pushed. Upsert, so a second
/// edit before a sync replaces the queued stamp; the ack later clears the row
/// only if the stamp still matches (see design spec, Section 4 step 4).
Future<void> enqueueOutbox(
  AppDatabase db,
  String table,
  String rowId,
  int stamp,
) => db
    .into(db.syncOutbox)
    .insertOnConflictUpdate(
      SyncOutboxCompanion.insert(
        targetTable: table,
        rowId: rowId,
        queuedUpdatedAt: stamp,
      ),
    );
