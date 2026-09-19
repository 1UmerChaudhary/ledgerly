import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:test/test.dart';

void main() {
  group('Weight value', () {
    test('is stored as integer grams', () {
      expect(const Weight(37324).grams, 37324);
      expect(Weight.kg(40).grams, 40000);
      expect(Weight.kg(16.5).grams, 16500);
    });

    test('multiplies by a bag count exactly', () {
      expect(Weight.kg(50) * 40, const Weight(2000000));
    });

    test('has the standard rate bases as named constants', () {
      expect(RateBase.maund.grams, 37324);
      expect(RateBase.forty.grams, 40000);
      expect(RateBase.presets.map((w) => w.grams), [30000, 34000, 37324, 40000, 56000]);
    });
  });

  group('formatKg', () {
    test('always shows three decimals so columns line up', () {
      expect(formatKg(const Weight(37324)), '37.324');
      expect(formatKg(Weight.kg(16)), '16.000');
      expect(formatKg(const Weight(2000000)), '2,000.000');
    });

    test('can trim zeros for prose', () {
      expect(formatKg(Weight.kg(40), trim: true), '40');
      expect(formatKg(const Weight(16500), trim: true), '16.5');
    });
  });

  group('parseKg', () {
    test('accepts kilograms with up to three decimals and an optional unit', () {
      expect(parseKg('37.324'), const Weight(37324));
      expect(parseKg('40'), Weight.kg(40));
      expect(parseKg('16.5 kg'), const Weight(16500));
      expect(parseKg('2,000'), const Weight(2000000));
    });

    test('rejects a fourth decimal, negatives and garbage', () {
      expect(parseKg('1.2345'), isNull);
      expect(parseKg('-5'), isNull);
      expect(parseKg(''), isNull);
      expect(parseKg('ten'), isNull);
    });
  });
}
