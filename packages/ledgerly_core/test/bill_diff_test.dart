import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:test/test.dart';

BillLine line(String id, int no, {int rate = 200000, int bags = 40}) =>
    BillLine(
      id: id,
      lineNo: no,
      itemId: 'cake',
      saleMode: SaleMode.byBags,
      bagCount: bags,
      bagWeight: Weight.kg(50),
      totalWeight: Weight.kg(50 * bags),
      rate: Money(rate),
      rateBase: RateBase.forty,
    );

void main() {
  final v1 = Bill(
    id: 'b',
    customerId: 'c',
    type: TransactionType.sale,
    entryDate: '2026-09-12',
    description: 'Oil + oilcake',
    lines: [line('l1', 1)],
  );

  test(
    'a changed line rate is reported once, with item, old and new values',
    () {
      final v2 = v1.copyWith(lines: [line('l1', 1, rate: 240000)]);
      final changes = diffBills(v1, v2, itemNames: {'cake': 'Oilcake'});
      expect(changes.map((c) => (c.label, c.from, c.to)), [
        ('Oilcake rate', '2,000', '2,400'),
        ('Final', '1,00,000', '1,20,000'),
      ]);
    },
  );

  test('header changes and added or removed lines are reported', () {
    final v2 = v1.copyWith(
      description: 'changed',
      lines: [line('l1', 1), line('l2', 2, bags: 10)],
    );
    final labels = diffBills(
      v1,
      v2,
      itemNames: {'cake': 'Oilcake'},
    ).map((c) => c.label).toList();
    expect(
      labels,
      containsAll(['Description', 'Line added: Oilcake', 'Final']),
    );
    final back = diffBills(
      v2,
      v1,
      itemNames: {'cake': 'Oilcake'},
    ).map((c) => c.label).toList();
    expect(back, contains('Line removed: Oilcake'));
  });

  test('identical bills have no changes', () {
    expect(diffBills(v1, v1), isEmpty);
  });
}
