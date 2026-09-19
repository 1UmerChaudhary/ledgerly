import 'package:drift/native.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late CustomersRepository customers;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final ctx = DeviceContext(
      firmId: '11111111-1111-4111-8111-111111111111',
      deviceId: '22222222-2222-4222-8222-222222222222',
      deviceShortCode: 'A3F9',
      userId: '33333333-3333-4333-8333-333333333333',
      hlc: Hlc(clock: () => 1000),
    );
    await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
    customers = CustomersRepository(db, ctx);
  });
  tearDown(() => db.close());

  test('a second customer with the same phone, spelt differently, is blocked and names the owner', () async {
    await customers.create(name: 'Rashid Traders', phone: '0300-9876543');
    expect(
      () => customers.create(name: 'Rashid Trader', phone: '+92 300 9876543'),
      throwsA(
        isA<DuplicatePhoneException>().having(
          (e) => e.existing.name,
          'existing',
          'Rashid Traders',
        ),
      ),
    );
  });

  test('a deleted customer frees the phone number', () async {
    final first = await customers.create(
      name: 'Old Shop',
      phone: '0301-1111111',
    );
    await customers.softDelete(first.id);
    final second = await customers.create(
      name: 'New Shop',
      phone: '0301 1111111',
    );
    expect(second.phoneNormalized, '923011111111');
  });

  test('customers without a phone never collide', () async {
    await customers.create(name: 'Walk-in Regular');
    await customers.create(name: 'Another Regular');
    expect((await customers.all()).length, 2);
  });

  test('search is fuzzy on name and exact on phone digits', () async {
    await customers.create(name: 'Rashid Traders', phone: '0300-9876543');
    await customers.create(name: 'Ahmed & Sons', phone: '0333-2222222');
    await customers.create(name: 'Karim Store');
    expect(
      (await customers.search('rashd')).map((c) => c.name).first,
      'Rashid Traders',
    );
    expect(
      (await customers.search('ahmd')).map((c) => c.name).first,
      'Ahmed & Sons',
    );
    expect((await customers.search('3332222')).map((c) => c.name), [
      'Ahmed & Sons',
    ]);
    expect((await customers.search('')).length, 3);
  });

  test('similarNames warns about close spellings before creating', () async {
    await customers.create(name: 'Muhammad Ali Traders');
    expect(
      (await customers.similarNames('Mohammad Ali Trader')).map((c) => c.name),
      ['Muhammad Ali Traders'],
    );
    expect(await customers.similarNames('Zubair Steel'), isEmpty);
  });
}
