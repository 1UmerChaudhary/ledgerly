import 'money.dart';
import 'weight.dart';

/// Line total for weight-based items.
///
/// Mirrors the database's generated column exactly:
/// `(rate_paisa * total_weight_g + rate_base_weight_g / 2) / rate_base_weight_g`
/// in integer arithmetic. That expression is round-half-up; neither Dart's nor
/// SQLite's floating `round()` is used, so device and server can never disagree
/// by a paisa. Multiply before divide so rounding happens once.
Money lineTotalByWeight({
  required Money rate,
  required Weight totalWeight,
  required Weight rateBase,
}) {
  if (rateBase.grams <= 0) {
    throw ArgumentError.value(rateBase, 'rateBase', 'must be positive');
  }
  final base = rateBase.grams;
  return Money((rate.paisa * totalWeight.grams + base ~/ 2) ~/ base);
}

Money lineTotalByCount({required Money rate, required int quantity}) =>
    Money(rate.paisa * quantity);

Weight totalWeightForBags({required int bagCount, required Weight bagWeight}) =>
    bagWeight * bagCount;
