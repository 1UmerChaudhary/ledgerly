import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:test/test.dart';

BillLine bags() => const BillLine(
  id: 'l1',
  lineNo: 1,
  itemId: 'oil',
  saleMode: SaleMode.byBags,
  bagCount: 20,
  bagWeight: Weight(16000),
  totalWeight: Weight(320000),
  rate: Money(900000),
  rateBase: Weight(37324),
);
BillLine weight() => const BillLine(
  id: 'l2',
  lineNo: 1,
  itemId: 'oil',
  saleMode: SaleMode.byWeight,
  totalWeight: Weight(10000),
  rate: Money(50000),
  rateBase: Weight(40000),
);
BillLine unit() => const BillLine(
  id: 'l3',
  lineNo: 1,
  itemId: 'tin',
  uom: Uom.unit,
  saleMode: SaleMode.byCount,
  quantity: 12,
  rate: Money(420000),
);

void main() {
  group('lineQuantityDescription', () {
    test('by bags: bag count x bag weight = total, in kg', () {
      expect(lineQuantityDescription(bags()), '20 bg x 16.000 = 320.000 kg');
    });
    test('by weight: just the total, in kg', () {
      expect(lineQuantityDescription(weight()), '10.000 kg');
    });
    test('by count: quantity with a unit label', () {
      expect(lineQuantityDescription(unit()), '12 units');
    });
  });

  group('lineRateDescription', () {
    test('kg lines show rate per base weight', () {
      expect(lineRateDescription(bags()), '@ 9,000 / 37.324');
      expect(lineRateDescription(weight()), '@ 500 / 40');
    });
    test('unit lines show a flat rate', () {
      expect(lineRateDescription(unit()), '@ 4,200 each');
    });
  });
}
