import 'package:drift/native.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:test/test.dart';

const firmId = '11111111-1111-4111-8111-111111111111';
const deviceId = '22222222-2222-4222-8222-222222222222';
const ownerId = '33333333-3333-4333-8333-333333333333';

void main() {
  late AppDatabase db;
  late DeviceContext ctx;
  late int clock;
  late BillsRepository bills;
  late String rashid;
  late String oil;
  late String cake;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    clock = 1000;
    ctx = DeviceContext(
      firmId: firmId,
      deviceId: deviceId,
      deviceShortCode: 'A3F9',
      userId: ownerId,
      hlc: Hlc(clock: () => clock),
    );
    await FirmSetup(
      db,
      ctx,
    ).createFirm(name: 'Al-Madina Oil Mills', contactNumber: '0300-1234567');
    rashid = (await CustomersRepository(
      db,
      ctx,
    ).create(name: 'Rashid Traders', phone: '0300-9876543')).id;
    oil = (await ItemsRepository(db, ctx).create(name: 'Oil')).id;
    cake = (await ItemsRepository(db, ctx).create(name: 'Oilcake')).id;
    bills = BillsRepository(db, ctx);
  });
  tearDown(() => db.close());

  BillLine oilLine() => BillLine(
    id: newId(),
    lineNo: 1,
    itemId: oil,
    saleMode: SaleMode.byBags,
    bagCount: 20,
    bagWeight: Weight.kg(16),
    totalWeight: Weight.kg(320),
    rate: Money.rupees(9000),
    rateBase: RateBase.maund,
  );
  BillLine cakeLine() => BillLine(
    id: newId(),
    lineNo: 2,
    itemId: cake,
    saleMode: SaleMode.byBags,
    bagCount: 40,
    bagWeight: Weight.kg(50),
    totalWeight: Weight.kg(2000),
    rate: Money.rupees(2400),
    rateBase: RateBase.forty,
  );
  Bill sale({String date = '2026-09-18'}) => Bill(
    id: newId(),
    customerId: rashid,
    type: TransactionType.sale,
    entryDate: date,
    lines: [oilLine(), cakeLine()],
    description: 'Sept supply',
  );

  group('saveNew', () {
    test('stores header and lines, numbers the bill for this device, queues one outbox row', () async {
      final saved = await bills.saveNew(sale());
      expect(saved.displayNo, 'A3F9-1');
      expect(saved.version, 1);
      expect(saved.finalAmount, const Money(7716215 + 12000000));

      final again = await bills.saveNew(sale());
      expect(again.displayNo, 'A3F9-2');

      final lines = await db
          .customSelect('SELECT count(*) AS c FROM transaction_lines')
          .getSingle();
      expect(lines.read<int>('c'), 4);

      final outbox = await db
          .customSelect(
            'SELECT target_table, row_id FROM sync_outbox ORDER BY row_id',
          )
          .get();
      expect(outbox.map((r) => r.read<String>('target_table')).toSet(), {
        'transactions',
        'customers',
        'items',
        'firms',
        'users',
        'devices',
        'firm_members',
      });
      expect(
        outbox
            .where((r) => r.read<String>('target_table') == 'transactions')
            .length,
        2,
      );
    });

    test('a cash entry has no lines and a typed amount', () async {
      final saved = await bills.saveNew(
        Bill(
          id: newId(),
          customerId: rashid,
          type: TransactionType.cashIn,
          entryDate: '2026-09-18',
          typedAmount: Money.rupees(100000),
        ),
      );
      expect(saved.finalAmount, Money.rupees(100000));
      expect(saved.lines, isEmpty);
    });

    test(
      'is all-or-nothing: a bad line leaves no header, no outbox row',
      () async {
        final bad = sale().copyWith(
          lines: [oilLine().copyWith(rate: Money.zero)],
        );
        await expectLater(bills.saveNew(bad), throwsA(anything));
        final headers = await db
            .customSelect('SELECT count(*) AS c FROM transactions')
            .getSingle();
        expect(headers.read<int>('c'), 0);
        final outbox = await db
            .customSelect(
              "SELECT count(*) AS c FROM sync_outbox WHERE target_table = 'transactions'",
            )
            .getSingle();
        expect(outbox.read<int>('c'), 0);
      },
    );
  });

  group('ledger and balances', () {
    test(
      'ledgerFor returns rows in date order with a running balance',
      () async {
        await bills.saveNew(sale(date: '2026-09-10'));
        clock += 10;
        await bills.saveNew(
          Bill(
            id: newId(),
            customerId: rashid,
            type: TransactionType.cashIn,
            entryDate: '2026-09-12',
            typedAmount: Money.rupees(100000),
          ),
        );
        clock += 10;
        await bills.saveNew(
          Bill(
            id: newId(),
            customerId: rashid,
            type: TransactionType.openingBalance,
            entryDate: '2026-09-01',
            typedAmount: Money.rupees(50000),
          ),
        );
        final ledger = await bills.ledgerFor(rashid);
        expect(ledger.map((e) => e.bill.type), [
          TransactionType.openingBalance,
          TransactionType.sale,
          TransactionType.cashIn,
        ]);
        expect(ledger.map((e) => e.runningBalance.paisa), [
          5000000,
          5000000 + 19716215,
          5000000 + 19716215 - 10000000,
        ]);
      },
    );

    test(
      'balances lists customers by signed balance, computed from transactions',
      () async {
        await bills.saveNew(sale());
        final list = await bills.balances();
        expect(list.single.customerId, rashid);
        expect(list.single.balance, const Money(19716215));
      },
    );
  });

  group('edit', () {
    test('writes a history snapshot, bumps version, replaces lines, requeues the bill', () async {
      final saved = await bills.saveNew(sale());
      clock += 5;
      final edited = await bills.edit(
        saved.copyWith(
          lines: [
            saved.lines.first,
            saved.lines.last.copyWith(rate: Money.rupees(2500)),
          ],
          description: 'Sept supply (rate fixed)',
        ),
      );
      expect(edited.version, 2);
      expect(edited.finalAmount, const Money(7716215 + 12500000));

      final history = await db
          .customSelect(
            'SELECT version, reason, snapshot FROM transaction_history',
          )
          .get();
      expect(history.single.read<int>('version'), 1);
      expect(history.single.read<String>('reason'), 'edit');
      expect(
        history.single.read<String>('snapshot'),
        contains('"description":"Sept supply"'),
      );

      final lines = await db
          .customSelect(
            "SELECT rate_paisa FROM transaction_lines WHERE transaction_id = '${saved.id}' ORDER BY line_no",
          )
          .get();
      expect(lines.map((r) => r.read<int>('rate_paisa')), [900000, 250000]);

      final outbox = await db
          .customSelect(
            "SELECT queued_updated_at FROM sync_outbox WHERE row_id = '${saved.id}'",
          )
          .getSingle();
      expect(outbox.read<int>('queued_updated_at'), 1005);
    });

    test(
      'keeps a bill-level override but flags it when lines change',
      () async {
        final saved = await bills.saveNew(sale());
        final rounded = await bills.edit(
          saved.copyWith(
            overriddenTotal: Money.rupees(197000),
            overriddenTotalBasis: saved.calculatedTotal,
          ),
        );
        expect(rounded.overrideIsStale, isFalse);
        final changed = await bills.edit(
          rounded.copyWith(
            lines: [
              rounded.lines.first,
              rounded.lines.last.copyWith(rate: Money.rupees(2500)),
            ],
          ),
        );
        expect(changed.overrideIsStale, isTrue);
        expect(changed.finalAmount, Money.rupees(197000));
      },
    );
  });

  group('delete and restore', () {
    test(
      'delete soft-deletes with a history row and drops it from the ledger',
      () async {
        final saved = await bills.saveNew(sale());
        await bills.delete(saved.id);
        expect(await bills.ledgerFor(rashid), isEmpty);
        final reasons = await db
            .customSelect('SELECT reason FROM transaction_history')
            .get();
        expect(reasons.map((r) => r.read<String>('reason')), ['delete']);
      },
    );

    test('restoreVersion applies an old snapshot as a new version', () async {
      final v1 = await bills.saveNew(sale());
      clock += 5;
      final v2 = await bills.edit(v1.copyWith(description: 'changed'));
      clock += 5;
      final v3 = await bills.restoreVersion(v2.id, version: 1);
      expect(v3.version, 3);
      expect(v3.description, 'Sept supply');
      final reasons = await db
          .customSelect(
            'SELECT reason FROM transaction_history ORDER BY changed_at',
          )
          .get();
      expect(reasons.map((r) => r.read<String>('reason')), ['edit', 'restore']);
    });
  });
}
