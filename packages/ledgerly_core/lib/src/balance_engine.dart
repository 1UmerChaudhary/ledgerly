import 'money.dart';

enum TransactionType {
  sale,
  purchase,
  cashIn,
  cashOut,
  openingBalance,
  adjustment,
}

/// The single place the sign of a transaction is decided. Mirrors the
/// `signed_amount` generated column's CASE in the database; a test checks the
/// two agree. Positive balance = customer owes the firm (receivable),
/// negative = firm owes the customer (giveable).
Money signedAmountFor(TransactionType type, Money finalAmount) {
  switch (type) {
    case TransactionType.adjustment:
      if (finalAmount.isZero) {
        throw ArgumentError.value(
          finalAmount,
          'finalAmount',
          'adjustment must be non-zero',
        );
      }
      return finalAmount;
    case TransactionType.sale:
    case TransactionType.cashOut:
    case TransactionType.openingBalance:
      _requirePositive(finalAmount);
      return finalAmount;
    case TransactionType.purchase:
    case TransactionType.cashIn:
      _requirePositive(finalAmount);
      return -finalAmount;
  }
}

void _requirePositive(Money amount) {
  if (!amount.isPositive) {
    throw ArgumentError.value(amount, 'finalAmount', 'must be positive');
  }
}

/// Which transaction type can hold a starting balance of this sign, for
/// onboarding a firm's existing customers. `opening_balance` can only be
/// positive (the database enforces this: a firm can't "owe money from day
/// one" via that type) — a starting giveable needs `adjustment` instead,
/// which allows any non-zero sign. Zero needs no transaction at all.
TransactionType? openingEntryTypeFor(Money balance) {
  if (balance.isZero) return null;
  return balance.isPositive
      ? TransactionType.openingBalance
      : TransactionType.adjustment;
}

Money applyTransaction(
  Money balance,
  TransactionType type,
  Money finalAmount,
) => balance + signedAmountFor(type, finalAmount);

Money receivable(Money balance) => balance.isPositive ? balance : Money.zero;

Money giveable(Money balance) => balance.isNegative ? -balance : Money.zero;

/// Running balance after each entry, in the order given. The caller supplies
/// entries already ordered by (entry_date, created_at, id).
Iterable<Money> runningBalances(Iterable<Money> signedAmounts) sync* {
  var running = Money.zero;
  for (final amount in signedAmounts) {
    running += amount;
    yield running;
  }
}
