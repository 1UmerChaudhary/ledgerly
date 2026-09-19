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
  late CustomersRepository customers;
  late ItemsRepository items;
  late BillsRepository bills;
  var clock = 1000;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    ctx = DeviceContext(
      firmId: firmId,
      deviceId: deviceId,
      deviceShortCode: 'A3F9',
      userId: ownerId,
      hlc: Hlc(clock: () => clock++),
    );
    await FirmSetup(db, ctx).createFirm(
      name: 'Al-Madina Oil Mills',
      contactNumber: '0300-1234567',
      address: 'Main Road, Sahiwal',
    );
    customers = CustomersRepository(db, ctx);
    items = ItemsRepository(db, ctx);
    bills = BillsRepository(db, ctx);
  });
  tearDown(() => db.close());

  group('slipFor', () {
    test(
      'assembles firm, customer, lines and the balance before/after',
      () async {
        final rashid = await customers.create(
          name: 'Rashid Traders',
          phone: '0300-9876543',
        );
        final oil = await items.create(name: 'Oil');
        await bills.saveNew(
          Bill(
            id: newId(),
            customerId: rashid.id,
            type: TransactionType.openingBalance,
            entryDate: '2026-09-01',
            typedAmount: Money.rupees(620000),
          ),
        );
        final sale = await bills.saveNew(
          Bill(
            id: newId(),
            customerId: rashid.id,
            type: TransactionType.sale,
            entryDate: '2026-09-18',
            lines: [
              BillLine(
                id: newId(),
                lineNo: 1,
                itemId: oil.id,
                saleMode: SaleMode.byBags,
                bagCount: 20,
                bagWeight: Weight.kg(16),
                totalWeight: Weight.kg(320),
                rate: Money.rupees(9000),
                rateBase: RateBase.maund,
              ),
            ],
          ),
        );

        final slip = await bills.slipFor(sale.id, printedAt: 5000);
        expect(slip.firmName, 'Al-Madina Oil Mills');
        expect(slip.firmContact, '0300-1234567');
        expect(slip.firmAddress, 'Main Road, Sahiwal');
        expect(slip.displayNo, sale.displayNo);
        expect(slip.customerName, 'Rashid Traders');
        expect(slip.lines.single.itemName, 'Oil');
        expect(slip.lines.single.amount, const Money(7716215));
        expect(slip.total, const Money(7716215));
        expect(slip.previousBalance, Money.rupees(620000));
        expect(slip.newBalance, Money.rupees(620000) + const Money(7716215));
        expect(slip.edited, isFalse);
        expect(slip.printedAt, 5000);
        expect(slip.deviceCode, 'A3F9');
      },
    );

    test('two bills on the same entry_date are still ordered correctly by creation time', () async {
      final rashid = await customers.create(name: 'Rashid Traders');
      final oil = await items.create(name: 'Oil');
      final morning = await bills.saveNew(
        Bill(
          id: newId(),
          customerId: rashid.id,
          type: TransactionType.cashIn,
          entryDate: '2026-09-18',
          typedAmount: Money.rupees(100),
        ),
      );
      final afternoon = await bills.saveNew(
        Bill(
          id: newId(),
          customerId: rashid.id,
          type: TransactionType.sale,
          entryDate: '2026-09-18',
          lines: [
            BillLine(
              id: newId(),
              lineNo: 1,
              itemId: oil.id,
              saleMode: SaleMode.byWeight,
              totalWeight: Weight.kg(10),
              rate: Money.rupees(500),
              rateBase: Weight.kg(10),
            ),
          ],
        ),
      );
      // The morning entry was created first, so it must not see the
      // afternoon one in its "previous balance" — and the afternoon one must.
      final morningSlip = await bills.slipFor(morning.id, printedAt: 1);
      expect(morningSlip.previousBalance, Money.zero);
      final afternoonSlip = await bills.slipFor(afternoon.id, printedAt: 1);
      expect(afternoonSlip.previousBalance, Money.rupees(-100));
    });

    test(
      'a walk-in sale has no customer name and a zero previous balance',
      () async {
        final oil = await items.create(name: 'Oil');
        final sale = await bills.saveNew(
          Bill(
            id: newId(),
            customerId: null,
            type: TransactionType.sale,
            entryDate: '2026-09-18',
            lines: [
              BillLine(
                id: newId(),
                lineNo: 1,
                itemId: oil.id,
                saleMode: SaleMode.byWeight,
                totalWeight: Weight.kg(10),
                rate: Money.rupees(500),
                rateBase: Weight.kg(10),
              ),
            ],
          ),
        );
        final slip = await bills.slipFor(sale.id, printedAt: 1);
        expect(slip.customerName, isNull);
        expect(slip.previousBalance, isNull);
        expect(slip.newBalance, isNull);
      },
    );

    test('an edited bill is flagged', () async {
      final rashid = await customers.create(name: 'Rashid Traders');
      final oil = await items.create(name: 'Oil');
      final sale = await bills.saveNew(
        Bill(
          id: newId(),
          customerId: rashid.id,
          type: TransactionType.sale,
          entryDate: '2026-09-18',
          lines: [
            BillLine(
              id: newId(),
              lineNo: 1,
              itemId: oil.id,
              saleMode: SaleMode.byWeight,
              totalWeight: Weight.kg(10),
              rate: Money.rupees(500),
              rateBase: Weight.kg(10),
            ),
          ],
        ),
      );
      await bills.edit(sale.copyWith(description: 'fixed'));
      final slip = await bills.slipFor(sale.id, printedAt: 1);
      expect(slip.edited, isTrue);
    });
  });

  group('ledgerPrintFor', () {
    test(
      'opening balance, rows and closing balance for a date range',
      () async {
        final rashid = await customers.create(name: 'Rashid Traders');
        await bills.saveNew(
          Bill(
            id: newId(),
            customerId: rashid.id,
            type: TransactionType.openingBalance,
            entryDate: '2026-09-01',
            typedAmount: Money.rupees(220000),
          ),
        );
        await bills.saveNew(
          Bill(
            id: newId(),
            customerId: rashid.id,
            type: TransactionType.cashIn,
            entryDate: '2026-09-10',
            typedAmount: Money.rupees(100000),
          ),
        );
        await bills.saveNew(
          Bill(
            id: newId(),
            customerId: rashid.id,
            type: TransactionType.cashIn,
            entryDate: '2026-09-18',
            typedAmount: Money.rupees(20000),
          ),
        );

        final print = await bills.ledgerPrintFor(
          rashid.id,
          fromDate: '2026-09-15',
          toDate: '2026-09-30',
          printedAt: 9,
        );
        expect(print.customerName, 'Rashid Traders');
        expect(
          print.openingBalance,
          Money.rupees(120000),
        ); // 2,20,000 - 1,00,000 before the range
        expect(print.rows.map((r) => r.credit), [Money.rupees(20000)]);
        expect(print.closingBalance, Money.rupees(100000));
        expect(print.printedAt, 9);
      },
    );

    test(
      'with no range, opening balance is zero and everything is included',
      () async {
        final rashid = await customers.create(name: 'Rashid Traders');
        await bills.saveNew(
          Bill(
            id: newId(),
            customerId: rashid.id,
            type: TransactionType.openingBalance,
            entryDate: '2026-09-01',
            typedAmount: Money.rupees(50000),
          ),
        );
        final print = await bills.ledgerPrintFor(rashid.id, printedAt: 1);
        expect(print.openingBalance, Money.zero);
        expect(print.rows.length, 1);
        expect(print.closingBalance, Money.rupees(50000));
      },
    );
  });

  test('logPrint writes an insert-only print_log row', () async {
    final rashid = await customers.create(name: 'Rashid Traders');
    final oil = await items.create(name: 'Oil');
    final sale = await bills.saveNew(
      Bill(
        id: newId(),
        customerId: rashid.id,
        type: TransactionType.sale,
        entryDate: '2026-09-18',
        lines: [
          BillLine(
            id: newId(),
            lineNo: 1,
            itemId: oil.id,
            saleMode: SaleMode.byWeight,
            totalWeight: Weight.kg(10),
            rate: Money.rupees(500),
            rateBase: Weight.kg(10),
          ),
        ],
      ),
    );
    await bills.logPrint(
      kind: 'slip',
      transactionId: sale.id,
      customerId: rashid.id,
      printedAt: 10,
      printedBalanceAfter: Money.rupees(500),
    );
    final rows = await db
        .customSelect('SELECT kind, printed_balance_after FROM print_log')
        .get();
    expect(rows.single.read<String>('kind'), 'slip');
    expect(rows.single.read<int>('printed_balance_after'), 50000);
  });
}
