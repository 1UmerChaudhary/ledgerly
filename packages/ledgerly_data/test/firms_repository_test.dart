import 'package:drift/native.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late DeviceContext ctx;
  var clock = 1000;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    ctx = DeviceContext(
      firmId: '11111111-1111-4111-8111-111111111111',
      deviceId: '22222222-2222-4222-8222-222222222222',
      deviceShortCode: 'A3F9',
      userId: '33333333-3333-4333-8333-333333333333',
      hlc: Hlc(clock: () => clock++),
    );
    await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
  });
  tearDown(() => db.close());

  test('get returns the firm with defaults', () async {
    final firm = await FirmsRepository(db, ctx).get();
    expect(firm.name, 'Mill');
    expect(firm.showPaisa, isFalse);
    expect(firm.grouping, NumberGrouping.pakistani);
    expect(firm.defaultCountryCode, '92');
  });

  test('update changes details and display settings, stamps the row and queues it for sync', () async {
    final repo = FirmsRepository(db, ctx);
    await repo.update(
      name: 'Al-Madina Oil Mills',
      address: 'Main Road, Sahiwal',
      showPaisa: true,
      grouping: NumberGrouping.western,
    );
    final firm = await repo.get();
    expect(firm.name, 'Al-Madina Oil Mills');
    expect(firm.address, 'Main Road, Sahiwal');
    expect(firm.showPaisa, isTrue);
    expect(firm.grouping, NumberGrouping.western);
    expect(firm.contactNumber, '0300'); // untouched
    final outbox = await db
        .customSelect(
          "SELECT queued_updated_at FROM sync_outbox WHERE target_table = 'firms'",
        )
        .getSingle();
    expect(outbox.read<int>('queued_updated_at'), greaterThan(1000));
  });
}
