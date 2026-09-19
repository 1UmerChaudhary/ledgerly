import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:test/test.dart';

void main() {
  group('lineTotalByWeight', () {
    test('rate Rs 9,000 per 40 kg on 2,500 kg is exact', () {
      final total = lineTotalByWeight(
        rate: Money.rupees(9000),
        totalWeight: Weight.kg(2500),
        rateBase: RateBase.forty,
      );
      expect(total, Money.rupees(562500));
    });

    test('rate Rs 9,000 per maund (37.324 kg) rounds half-up to the paisa', () {
      final total = lineTotalByWeight(
        rate: Money.rupees(9000),
        totalWeight: Weight.kg(2500),
        rateBase: RateBase.maund,
      );
      expect(total, const Money(60282928)); // 60,282,927.87… → .88
    });

    test('exactly one half rounds up, never to even', () {
      final total = lineTotalByWeight(
        rate: const Money(1),
        totalWeight: const Weight(1),
        rateBase: const Weight(2),
      );
      expect(total, const Money(1));
    });

    test('matches the SQL expression (a*b + c/2) / c on many inputs', () {
      // The database computes the same column with this integer expression;
      // if the two ever disagreed, device and server could differ by a paisa.
      for (var rate = 1; rate < 200000; rate += 7919) {
        for (final base in RateBase.presets) {
          final w = Weight(rate * 37 % 500000 + 1);
          final sql = (rate * w.grams + base.grams ~/ 2) ~/ base.grams;
          expect(
            lineTotalByWeight(rate: Money(rate), totalWeight: w, rateBase: base).paisa,
            sql,
          );
        }
      }
    });

    test('rejects a zero or negative base', () {
      expect(
        () => lineTotalByWeight(rate: Money.rupees(1), totalWeight: Weight.kg(1), rateBase: const Weight(0)),
        throwsArgumentError,
      );
    });
  });

  test('totalWeightForBags multiplies count by bag weight', () {
    expect(totalWeightForBags(bagCount: 20, bagWeight: Weight.kg(16)), Weight.kg(320));
  });

  test('lineTotalByCount is rate times quantity', () {
    expect(lineTotalByCount(rate: Money.rupees(4200), quantity: 12), Money.rupees(50400));
  });
}
