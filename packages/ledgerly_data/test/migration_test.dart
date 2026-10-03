import 'dart:io';

import 'package:drift/native.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:test/test.dart';

import 'schema_test.dart' show firm, owner, device, seedFirmCustomerItem;

/// The v1 phone index, exactly as every install before schema 2 has it.
const _v1PhoneIndex =
    'CREATE UNIQUE INDEX idx_customers_phone ON customers '
    '(firm_id, phone_normalized) WHERE deleted_at IS NULL AND '
    'merged_into_id IS NULL AND phone_normalized IS NOT NULL';

Future<void> insertCustomer(
  AppDatabase db,
  String id, {
  required String name,
  required String phone,
  bool needsReview = false,
}) => db.customStatement(
  'INSERT INTO customers (id, firm_id, name, name_normalized, phone, '
  'phone_normalized, needs_review, created_by_user_id, created_at, '
  "updated_at, updated_by_device_id) VALUES ('$id','$firm','$name',"
  "'${name.toLowerCase()}','$phone','$phone',${needsReview ? 1 : 0},"
  "'$owner',1,1,'$device')",
);

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('ledgerly'));
  tearDown(() => dir.delete(recursive: true));

  test('a v1 database upgrades: customers the server flagged needs_review may '
      'share a phone, an ordinary duplicate is still refused', () async {
    final file = File('${dir.path}/firm.db');

    // Build a v1 database: today's schema with the v1 index and version.
    final v1 = AppDatabase(NativeDatabase(file));
    await seedFirmCustomerItem(v1);
    await v1.customStatement('DROP INDEX idx_customers_phone');
    await v1.customStatement(_v1PhoneIndex);
    await v1.customStatement('PRAGMA user_version = 1');
    await v1.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    await insertCustomer(
      db,
      '77777777-7777-4777-8777-000000000001',
      name: 'Ali',
      phone: '923001234567',
    );

    await insertCustomer(
      db,
      '77777777-7777-4777-8777-000000000002',
      name: 'Ali Khan',
      phone: '923001234567',
      needsReview: true,
    );
    expect(
      () => insertCustomer(
        db,
        '77777777-7777-4777-8777-000000000003',
        name: 'Ali Raza',
        phone: '923001234567',
      ),
      throwsA(isA<SqliteException>()),
    );
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, db.schemaVersion);
  });
}
