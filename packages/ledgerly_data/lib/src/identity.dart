import 'db/app_database.dart';
import 'device_context.dart';

/// Re-keys the user [from] (the owner the device made for itself when the
/// firm was created) to [to] (the id the server assigned when the cloud
/// account was created), everywhere it appears, in one transaction.
///
/// Ids are made on the device -- except a user's, which the server assigns
/// (docs/design-spec.md Section 4, step 0). The server's foreign keys
/// refuse any row "created by" an id it never issued, so until the device
/// adopts the server's id, every customer, item and bill it pushes is
/// rejected as "invalid" and nothing ever reaches the server. Rows already
/// queued keep their outbox entries; they simply push with the new id.
///
/// [ctx] is updated last, so the firm's repositories -- which all share it
/// -- write every new row with the server's id too.
Future<void> adoptUserId(AppDatabase db, DeviceContext ctx, String to) async {
  final from = ctx.userId;
  if (from == to) return;
  await db.transaction(() async {
    // users.id is the parent of every column below; the checks wait for
    // the commit, by which point all of them point at the new id.
    await db.customStatement('PRAGMA defer_foreign_keys = ON');
    for (final sql in const [
      'UPDATE users SET id = ?1 WHERE id = ?2',
      'UPDATE firm_members SET user_id = ?1 WHERE user_id = ?2',
      'UPDATE items SET created_by_user_id = ?1 WHERE created_by_user_id = ?2',
      'UPDATE customers SET created_by_user_id = ?1 '
          'WHERE created_by_user_id = ?2',
      'UPDATE transactions SET created_by_user_id = ?1 '
          'WHERE created_by_user_id = ?2',
      'UPDATE transactions SET updated_by_user_id = ?1 '
          'WHERE updated_by_user_id = ?2',
      'UPDATE transaction_history SET changed_by_user_id = ?1 '
          'WHERE changed_by_user_id = ?2',
    ]) {
      await db.customStatement(sql, [to, from]);
    }
  });
  ctx.userId = to;
}
