import 'package:meta/meta.dart';

/// How digits are grouped for display. Firms in Pakistan read 12,34,567
/// (lakh/crore); international users read 1,234,567.
enum NumberGrouping { pakistani, western }

/// An amount of money in paisa. Integers only: floats cannot represent 0.1
/// exactly, and a ledger that drifts by one paisa is a ledger nobody trusts.
@immutable
class Money implements Comparable<Money> {
  const Money(this.paisa);

  factory Money.rupees(int rupees) => Money(rupees * 100);

  static const Money zero = Money(0);

  final int paisa;

  bool get isZero => paisa == 0;
  bool get isPositive => paisa > 0;
  bool get isNegative => paisa < 0;

  Money operator +(Money other) => Money(paisa + other.paisa);
  Money operator -(Money other) => Money(paisa - other.paisa);
  Money operator -() => Money(-paisa);
  bool operator <(Money other) => paisa < other.paisa;
  bool operator >(Money other) => paisa > other.paisa;
  Money abs() => Money(paisa.abs());

  @override
  int compareTo(Money other) => paisa.compareTo(other.paisa);

  @override
  bool operator ==(Object other) => other is Money && other.paisa == paisa;

  @override
  int get hashCode => paisa.hashCode;

  @override
  String toString() => 'Money($paisa paisa)';
}

/// Formats for screens and prints. Paisa are hidden by default because trading
/// firms talk in whole rupees; the stored value is never rounded, only the text.
String formatMoney(
  Money money, {
  NumberGrouping grouping = NumberGrouping.pakistani,
  bool showPaisa = false,
  bool symbol = true,
}) {
  final sign = money.isNegative ? '-' : '';
  final abs = money.paisa.abs();
  final String body;
  if (showPaisa) {
    final rupees = abs ~/ 100;
    final paisa = (abs % 100).toString().padLeft(2, '0');
    body = '${groupDigits(rupees, grouping)}.$paisa';
  } else {
    body = groupDigits((abs + 50) ~/ 100, grouping); // half-up to whole rupees
  }
  return '$sign${symbol ? 'Rs ' : ''}$body';
}

String groupDigits(int value, NumberGrouping grouping) {
  final digits = value.toString();
  if (digits.length <= 3) return digits;
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groupSize = grouping == NumberGrouping.pakistani ? 2 : 3;
  final parts = <String>[];
  while (rest.length > groupSize) {
    parts.insert(0, rest.substring(rest.length - groupSize));
    rest = rest.substring(0, rest.length - groupSize);
  }
  parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}

final RegExp _moneyPattern = RegExp(r'^(-?)(\d+)(?:\.(\d+))?$');

/// Accepts what a clerk types: "1,25,000", "125000", "Rs 1,250.50". Returns
/// null for anything that isn't a single number.
Money? parseMoney(String input) {
  final cleaned = input.replaceAll(RegExp(r'[Rr][Ss]\.?|[,\s]'), '');
  final m = _moneyPattern.firstMatch(cleaned);
  if (m == null) return null;
  final negative = m.group(1) == '-';
  final rupees = int.parse(m.group(2)!);
  final frac = (m.group(3) ?? '').padRight(3, '0').substring(0, 3);
  final paisa =
      rupees * 100 + (int.parse(frac) + 5) ~/ 10; // half-up on 3rd digit
  return Money(negative ? -paisa : paisa);
}
