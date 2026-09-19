import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:test/test.dart';

void main() {
  group('openingEntryTypeFor', () {
    test('positive → opening_balance (receivable), negative → adjustment, zero → nothing', () {
      expect(
        openingEntryTypeFor(Money.rupees(1000)),
        TransactionType.openingBalance,
      );
      expect(
        openingEntryTypeFor(Money.rupees(-1000)),
        TransactionType.adjustment,
      );
      expect(openingEntryTypeFor(Money.zero), isNull);
    });
  });

  group('parseOpeningBalancesCsv', () {
    test('parses name,phone,balance rows, skipping a header row', () {
      final result = parseOpeningBalancesCsv('''
name,phone,balance
Rashid Traders,0300-9876543,620000
Ahmed & Sons,,-100000
''');
      expect(result.errors, isEmpty);
      expect(result.rows.length, 2);
      expect(result.rows[0].name, 'Rashid Traders');
      expect(result.rows[0].phone, '0300-9876543');
      expect(result.rows[0].balance, Money.rupees(620000));
      expect(result.rows[1].name, 'Ahmed & Sons');
      expect(result.rows[1].phone, isNull);
      expect(result.rows[1].balance, Money.rupees(-100000));
    });

    test('works without a header row and tolerates blank lines', () {
      final result = parseOpeningBalancesCsv(
        'Karim Store,,0\n\nBilal Depot,0333-1,50000\n',
      );
      expect(result.rows.map((r) => r.name), ['Karim Store', 'Bilal Depot']);
    });

    test(
      'accepts grouped or plain numbers via the same parser as everywhere else',
      () {
        final result = parseOpeningBalancesCsv('Rashid,,"6,20,000"');
        expect(result.rows.single.balance, Money.rupees(620000));
      },
    );

    test(
      'a comma inside a quoted name is not mistaken for a column separator',
      () {
        final result = parseOpeningBalancesCsv('"Ali, Traders",0300-9,1000');
        expect(result.rows.single.name, 'Ali, Traders');
        expect(result.rows.single.phone, '0300-9');
      },
    );

    test(
      'collects errors per line instead of throwing, and keeps the good rows',
      () {
        final result = parseOpeningBalancesCsv('''
Good One,0300-1,1000
,0300-2,1000
Bad Amount,0300-3,notanumber
Missing Column,0300-4
''');
        expect(result.rows.map((r) => r.name), ['Good One']);
        expect(result.errors.length, 3);
        expect(result.errors[0].line, 2);
        expect(result.errors[0].message, contains('name'));
        expect(result.errors[1].line, 3);
        expect(result.errors[1].message, contains('balance'));
        expect(result.errors[2].line, 4);
        expect(result.errors[2].message, contains('3 columns'));
      },
    );
  });
}
