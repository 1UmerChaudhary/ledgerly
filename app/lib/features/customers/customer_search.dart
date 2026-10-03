import 'package:ledgerly_core/ledgerly_core.dart';

/// Filters [items] to the customers matching [query] by phone or by name,
/// shared by the dashboard and the Customers screen so the two can't drift
/// apart again (the Customers screen once promised "name or phone" and
/// searched names only).
///
/// A query of only digits and phone punctuation, with at least 4 digits, is
/// a phone search; anything else is a fuzzy name search. Results are the
/// items themselves, so two customers sharing a name both stay listed.
List<T> searchCustomers<T>(
  String query,
  List<T> items,
  Customer Function(T) customerOf,
) {
  if (query.trim().isEmpty) return items;
  if (_phoneDigits(query) case final digits?) {
    return items
        .where((i) => _phoneMatches(customerOf(i).phoneNormalized, digits))
        .toList();
  }
  return [
    for (final hit in fuzzySearchBy(query, items, (i) => customerOf(i).name))
      hit.value,
  ];
}

String? _phoneDigits(String query) {
  final digits = query.replaceAll(RegExp(r'\D'), '');
  final withoutPunctuation = query.replaceAll(RegExp(r'[\s\-+()]'), '');
  return digits.length >= 4 && digits.length == withoutPunctuation.length
      ? digits
      : null;
}

/// Phones are stored country-code first with no trunk 0 ("923001234567"),
/// but people type them the local way ("0300 123...") -- so a typed number
/// also matches with its leading zeros dropped (which covers "0092..." too).
bool _phoneMatches(String? stored, String digits) {
  if (stored == null) return false;
  final withoutTrunk = digits.replaceFirst(RegExp('^0+'), '');
  return stored.contains(digits) ||
      (withoutTrunk.isNotEmpty && stored.contains(withoutTrunk));
}
