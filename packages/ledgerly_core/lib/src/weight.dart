import 'package:meta/meta.dart';

import 'money.dart';

/// A weight in grams. Integers only, for the same reason Money is in paisa:
/// 37.324 kg is exactly 37324 g, and bag counts multiply without drift.
@immutable
class Weight implements Comparable<Weight> {
  const Weight(this.grams);

  factory Weight.kg(num kg) => Weight((kg * 1000).round());

  final int grams;

  Weight operator *(int count) => Weight(grams * count);
  Weight operator +(Weight other) => Weight(grams + other.grams);

  @override
  int compareTo(Weight other) => grams.compareTo(other.grams);

  @override
  bool operator ==(Object other) => other is Weight && other.grams == grams;

  @override
  int get hashCode => grams.hashCode;

  @override
  String toString() => 'Weight($grams g)';
}

/// The base weights rates are quoted against in Pakistani commodity trade.
/// 37.324 kg is one maund; 40 kg is the "metric maund".
abstract final class RateBase {
  static const Weight thirty = Weight(30000);
  static const Weight thirtyFour = Weight(34000);
  static const Weight maund = Weight(37324);
  static const Weight forty = Weight(40000);
  static const Weight fiftySix = Weight(56000);

  /// Hotkeys 1–5 in the bill form pick these in this order.
  static const List<Weight> presets = [
    thirty,
    thirtyFour,
    maund,
    forty,
    fiftySix,
  ];
}

/// Always three decimals unless [trim] is set, so grid columns line up.
String formatKg(Weight weight, {bool trim = false}) {
  final kg = groupDigits(weight.grams ~/ 1000, NumberGrouping.western);
  var frac = (weight.grams % 1000).toString().padLeft(3, '0');
  if (trim) {
    frac = frac.replaceFirst(RegExp(r'0+$'), '');
    return frac.isEmpty ? kg : '$kg.$frac';
  }
  return '$kg.$frac';
}

final RegExp _kgPattern = RegExp(r'^(\d+)(?:\.(\d{1,3}))?$');

/// Accepts "37.324", "40", "16.5 kg", "2,000". Grams are the finest unit, so a
/// fourth decimal is rejected rather than silently rounded.
Weight? parseKg(String input) {
  final cleaned = input
      .replaceAll(RegExp(r'\s*kg\s*$', caseSensitive: false), '')
      .replaceAll(RegExp(r'[,\s]'), '');
  final m = _kgPattern.firstMatch(cleaned);
  if (m == null) return null;
  final frac = (m.group(2) ?? '').padRight(3, '0');
  return Weight(int.parse(m.group(1)!) * 1000 + int.parse(frac));
}
