import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:test/test.dart';

void main() {
  group('signedAmount — the one place the sign lives', () {
    test('sale, cash paid out and opening balance add to what the customer owes', () {
      expect(signedAmount(TransactionType.sale, Money.rupees(100)), Money.rupees(100));
      expect(signedAmount(TransactionType.cashOut, Money.rupees(100)), Money.rupees(100));
      expect(signedAmount(TransactionType.openingBalance, Money.rupees(100)), Money.rupees(100));
    });

    test('purchase and cash received subtract', () {
      expect(signedAmount(TransactionType.purchase, Money.rupees(100)), Money.rupees(-100));
      expect(signedAmount(TransactionType.cashIn, Money.rupees(100)), Money.rupees(-100));
    });

    test('adjustment passes its own sign through', () {
      expect(signedAmount(TransactionType.adjustment, Money.rupees(-30)), Money.rupees(-30));
      expect(signedAmount(TransactionType.adjustment, Money.rupees(30)), Money.rupees(30));
    });

    test('rejects amounts the database CHECK would reject', () {
      expect(() => signedAmount(TransactionType.sale, Money.zero), throwsArgumentError);
      expect(() => signedAmount(TransactionType.sale, Money.rupees(-1)), throwsArgumentError);
      expect(() => signedAmount(TransactionType.adjustment, Money.zero), throwsArgumentError);
    });
  });

  group('the four spec rules fall out of one signed balance', () {
    test('1. sale consumes a giveable first, remainder becomes receivable', () {
      final b = applyTransaction(Money.rupees(-5000), TransactionType.sale, Money.rupees(8000));
      expect(b, Money.rupees(3000));
      expect(receivable(b), Money.rupees(3000));
      expect(giveable(b), Money.zero);
    });

    test('2. purchase consumes a receivable first, remainder becomes giveable', () {
      final b = applyTransaction(Money.rupees(3000), TransactionType.purchase, Money.rupees(5000));
      expect(b, Money.rupees(-2000));
      expect(receivable(b), Money.zero);
      expect(giveable(b), Money.rupees(2000));
    });

    test('3. cash received with no receivable becomes an advance (giveable)', () {
      final b = applyTransaction(Money.zero, TransactionType.cashIn, Money.rupees(1000));
      expect(giveable(b), Money.rupees(1000));
    });

    test('4. cash paid beyond the giveable becomes a receivable', () {
      final b = applyTransaction(Money.rupees(-1000), TransactionType.cashOut, Money.rupees(1500));
      expect(receivable(b), Money.rupees(500));
    });
  });

  test('runningBalances replays a ledger in order', () {
    final entries = [
      (TransactionType.openingBalance, Money.rupees(220000)),
      (TransactionType.sale, Money.rupees(210000)),
      (TransactionType.cashIn, Money.rupees(100000)),
      (TransactionType.sale, Money.rupees(290000)),
    ];
    expect(
      runningBalances(entries.map((e) => signedAmount(e.$1, e.$2))).toList(),
      [Money.rupees(220000), Money.rupees(430000), Money.rupees(330000), Money.rupees(620000)],
    );
  });
}
