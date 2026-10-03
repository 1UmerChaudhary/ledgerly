import 'package:drift/native.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:test/test.dart';

/// The server assigns the owner's user id when the cloud account is created,
/// and its foreign keys refuse any row "created by" an id it never issued --
/// which every row a device made before signing up is. Until the device
/// adopts the server's id, every push is rejected as "invalid".
void main() {
  const serverUserId = '99999999-9999-4999-8999-999999999999';

  test('adoptUserId moves the owner and everything they made to the '
      "server's user id, and the foreign keys still hold", () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final ctx = DeviceContext(
      firmId: '11111111-1111-4111-8111-111111111111',
      deviceId: '22222222-2222-4222-8222-222222222222',
      deviceShortCode: 'A3F9',
      userId: '33333333-3333-4333-8333-333333333333',
      hlc: Hlc(clock: () => 1000),
    );
    await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
    final customer = await CustomersRepository(
      db,
      ctx,
    ).create(name: 'Ali', phone: '0300-1234567');
    await ItemsRepository(db, ctx).create(name: 'Oil');
    await BillsRepository(db, ctx).saveNew(
      Bill(
        id: newId(),
        customerId: customer.id,
        type: TransactionType.openingBalance,
        entryDate: '2026-10-03',
        typedAmount: Money.rupees(500),
      ),
    );

    await adoptUserId(db, ctx, serverUserId);

    Future<List<String>> ids(String sql) async => [
      for (final r in await db.customSelect(sql).get())
        r.data.values.single as String,
    ];
    expect(await ids('SELECT id FROM users'), [serverUserId]);
    expect(await ids('SELECT user_id FROM firm_members'), [serverUserId]);
    for (final sql in [
      'SELECT DISTINCT created_by_user_id FROM customers',
      'SELECT DISTINCT created_by_user_id FROM items',
      'SELECT DISTINCT created_by_user_id FROM transactions',
      'SELECT DISTINCT updated_by_user_id FROM transactions',
    ]) {
      expect(await ids(sql), [serverUserId], reason: sql);
    }
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);

    // And what's created next is the server's user's too.
    expect(ctx.userId, serverUserId);
    await ItemsRepository(db, ctx).create(name: 'Sugar');
    expect(await ids('SELECT DISTINCT created_by_user_id FROM items'), [
      serverUserId,
    ]);
  });

  test('adopting the id the device already has changes nothing', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final ctx = DeviceContext(
      firmId: '11111111-1111-4111-8111-111111111111',
      deviceId: '22222222-2222-4222-8222-222222222222',
      deviceShortCode: 'A3F9',
      userId: serverUserId,
      hlc: Hlc(clock: () => 1000),
    );
    await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');

    await adoptUserId(db, ctx, serverUserId);

    final users = await db.customSelect('SELECT id FROM users').get();
    expect(users.map((r) => r.data['id']), [serverUserId]);
  });
}
