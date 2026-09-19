import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:test/test.dart';

BillLine oilLine({Money? override}) => BillLine(
  id: 'l1',
  lineNo: 1,
  itemId: 'oil',
  saleMode: SaleMode.byBags,
  bagCount: 20,
  bagWeight: Weight.kg(16),
  totalWeight: Weight.kg(320),
  rate: Money.rupees(9000),
  rateBase: RateBase.maund,
  overriddenTotal: override,
);

BillLine cakeLine() => BillLine(
  id: 'l2',
  lineNo: 2,
  itemId: 'cake',
  saleMode: SaleMode.byBags,
  bagCount: 40,
  bagWeight: Weight.kg(50),
  totalWeight: Weight.kg(2000),
  rate: Money.rupees(2400),
  rateBase: RateBase.forty,
);

void main() {
  group('BillLine totals', () {
    test('calculated total uses the shared rate formula', () {
      expect(
        oilLine().calculatedTotal,
        const Money(7716215),
      ); // 9,000 × 320 / 37.324 = 77,162.147… → .15
      expect(cakeLine().calculatedTotal, Money.rupees(120000));
    });

    test('final total is the override when present', () {
      expect(oilLine().finalTotal, const Money(7716215));
      expect(
        oilLine(override: Money.rupees(77000)).finalTotal,
        Money.rupees(77000),
      );
    });

    test('unit items multiply rate by quantity', () {
      final tins = BillLine(
        id: 'l3',
        lineNo: 3,
        itemId: 'tin',
        saleMode: SaleMode.byCount,
        uom: Uom.unit,
        quantity: 12,
        rate: Money.rupees(4200),
      );
      expect(tins.calculatedTotal, Money.rupees(50400));
    });
  });

  group('Bill totals', () {
    final bill = Bill(
      id: 'b1',
      customerId: 'c1',
      type: TransactionType.sale,
      entryDate: '2026-09-18',
      lines: [oilLine(), cakeLine()],
    );

    test('calculated total is the sum of line finals', () {
      expect(bill.calculatedTotal, const Money(7716215 + 12000000));
    });

    test('final amount honours a bill-level override', () {
      final rounded = bill.copyWith(
        overriddenTotal: Money.rupees(197000),
        overriddenTotalBasis: bill.calculatedTotal,
      );
      expect(rounded.finalAmount, Money.rupees(197000));
      expect(rounded.overrideIsStale, isFalse);
    });

    test('flags a bill-level override whose lines changed since', () {
      final rounded = bill.copyWith(
        overriddenTotal: Money.rupees(197000),
        overriddenTotalBasis: bill.calculatedTotal,
      );
      final edited = rounded.copyWith(
        lines: [
          oilLine(),
          cakeLine().copyWith(rate: Money.rupees(2500)),
        ],
      );
      expect(edited.overrideIsStale, isTrue);
      expect(edited.finalAmount, Money.rupees(197000)); // kept, but flagged
    });

    test('deleted defaults to false and copyWith can flip it', () {
      final b = Bill(
        id: 'b3',
        customerId: 'c1',
        type: TransactionType.sale,
        entryDate: '2026-09-18',
        typedAmount: Money.rupees(1),
      );
      expect(b.deleted, isFalse);
      expect(b.copyWith(deleted: true).deleted, isTrue);
    });

    test('a cash entry has no lines and its amount is typed directly', () {
      final cash = Bill(
        id: 'b2',
        customerId: 'c1',
        type: TransactionType.cashIn,
        entryDate: '2026-09-18',
        typedAmount: Money.rupees(100000),
      );
      expect(cash.lines, isEmpty);
      expect(cash.finalAmount, Money.rupees(100000));
      expect(cash.signedAmount, Money.rupees(-100000));
    });
  });
}
