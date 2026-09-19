import 'balance_engine.dart';
import 'entities.dart';
import 'money.dart';
import 'weight.dart';

/// The one label for each transaction type, shared by the ledger screen and
/// every print template so paper and screen never disagree on the wording.
String transactionTypeLabel(TransactionType t) => switch (t) {
  TransactionType.sale => 'Sale',
  TransactionType.purchase => 'Purchase',
  TransactionType.cashIn => 'Cash in',
  TransactionType.cashOut => 'Cash out',
  TransactionType.openingBalance => 'Opening balance',
  TransactionType.adjustment => 'Adjustment',
};

/// How much was sold, in the words a slip prints: "20 bg x 16.000 = 320.000
/// kg" for bags, "10.000 kg" for a plain weight sale, "12 units" for a count.
String lineQuantityDescription(BillLine l) {
  switch (l.uom) {
    case Uom.unit:
      return '${l.quantity} units';
    case Uom.kg:
      switch (l.saleMode) {
        case SaleMode.byBags:
          return '${l.bagCount} bg x ${formatKg(l.bagWeight!)} = ${formatKg(l.totalWeight!)} kg';
        case SaleMode.byWeight:
        case SaleMode.byCount:
          return '${formatKg(l.totalWeight!)} kg';
      }
  }
}

/// How the price was quoted: "@ 9,000 / 37.324" for a rate-per-base-weight
/// line, "@ 4,200 each" for a flat per-unit line.
String lineRateDescription(BillLine l) => switch (l.uom) {
  Uom.kg =>
    '@ ${formatMoney(l.rate, symbol: false)} / ${formatKg(l.rateBase!, trim: true)}',
  Uom.unit => '@ ${formatMoney(l.rate, symbol: false)} each',
};
