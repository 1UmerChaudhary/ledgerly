import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:test/test.dart';

void main() {
  group('Money value', () {
    test('is stored as integer paisa', () {
      expect(Money.rupees(1250).paisa, 125000);
      expect(const Money(125050).paisa, 125050);
    });

    test('adds and subtracts exactly', () {
      expect(const Money(10) + const Money(20), const Money(30));
      expect(const Money(10) - const Money(20), const Money(-10));
      expect(-const Money(5), const Money(-5));
    });

    test('compares', () {
      expect(const Money(5) < const Money(6), isTrue);
      expect(const Money(6).isPositive, isTrue);
      expect(const Money(-6).isNegative, isTrue);
      expect(Money.zero.isZero, isTrue);
    });
  });

  group('formatMoney', () {
    test('groups the Pakistani way and hides paisa by default', () {
      expect(formatMoney(Money.rupees(1234567)), 'Rs 12,34,567');
      expect(formatMoney(Money.rupees(100000)), 'Rs 1,00,000');
      expect(formatMoney(Money.rupees(999)), 'Rs 999');
      expect(formatMoney(Money.rupees(0)), 'Rs 0');
    });

    test('rounds half-up to whole rupees when paisa are hidden', () {
      expect(formatMoney(const Money(60283572)), 'Rs 6,02,836');
      expect(formatMoney(const Money(150)), 'Rs 2');
      expect(formatMoney(const Money(149)), 'Rs 1');
    });

    test('shows two paisa digits when asked', () {
      expect(
        formatMoney(const Money(60283572), showPaisa: true),
        'Rs 6,02,835.72',
      );
      expect(formatMoney(const Money(500), showPaisa: true), 'Rs 5.00');
    });

    test('supports western grouping per firm setting', () {
      expect(
        formatMoney(Money.rupees(1234567), grouping: NumberGrouping.western),
        'Rs 1,234,567',
      );
    });

    test('marks negatives with a leading minus and can drop the symbol', () {
      expect(formatMoney(Money.rupees(-1500)), '-Rs 1,500');
      expect(formatMoney(Money.rupees(1500), symbol: false), '1,500');
    });
  });

  group('parseMoneyExpression', () {
    test('adds and subtracts amounts typed into one box', () {
      expect(parseMoneyExpression('10000+500'), Money.rupees(10500));
      expect(parseMoneyExpression('10000-250'), Money.rupees(9750));
      expect(parseMoneyExpression('10000 + 500 - 100'), Money.rupees(10400));
      expect(parseMoneyExpression('1,00,000+2,500.50'), const Money(10250050));
      expect(parseMoneyExpression('Rs 10,000 + Rs 500'), Money.rupees(10500));
    });

    test('a plain number still parses exactly as parseMoney does', () {
      for (final typed in ['1,25,000', '125000', 'Rs 1,250.50', '-500']) {
        expect(parseMoneyExpression(typed), parseMoney(typed), reason: typed);
      }
    });

    test('adds in paisa, so decimals never drift', () {
      expect(parseMoneyExpression('0.10+0.20'), const Money(30));
    });

    test('is null while half-typed or not a sum of amounts', () {
      for (final typed in ['', '10000+', '+', '10000++500', '10000*2', 'abc']) {
        expect(parseMoneyExpression(typed), isNull, reason: typed);
      }
    });
  });

  group('moneySumText', () {
    test('turns a typed sum into the number it comes to', () {
      expect(moneySumText('10000+500'), '10,500');
      expect(moneySumText('10000.50+0.25'), '10,000.75');
    });

    test('leaves anything that is not a finished sum alone', () {
      for (final typed in ['10500', '10,500', '10000+', '', 'abc']) {
        expect(moneySumText(typed), isNull, reason: typed);
      }
    });
  });

  group('parseMoney', () {
    test('accepts grouped, plain and symbol-prefixed input', () {
      expect(parseMoney('1,25,000'), Money.rupees(125000));
      expect(parseMoney('125000'), Money.rupees(125000));
      expect(parseMoney('Rs 1,250.50'), const Money(125050));
      expect(parseMoney(' 1,234,567 '), Money.rupees(1234567));
      expect(parseMoney('-500'), Money.rupees(-500));
    });

    test('rounds a third decimal and rejects garbage', () {
      expect(parseMoney('1.235'), const Money(124));
      expect(parseMoney(''), isNull);
      expect(parseMoney('abc'), isNull);
      expect(parseMoney('1.2.3'), isNull);
    });
  });
}
