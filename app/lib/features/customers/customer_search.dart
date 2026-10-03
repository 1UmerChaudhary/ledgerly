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
/// but people type them the local way ("0300 123..."). A query is matched
/// the way it was typed:
/// - "00..." is international: the rest must start the stored number;
/// - "0..." is local: the rest must start the national part, right after a
///   1-3 digit country code -- anywhere else would let "0222" match
///   0333-2222222 just because "222" appears in it;
/// - anything else ("+92 300...", "9876") may appear anywhere.
bool _phoneMatches(String? stored, String digits) {
  if (stored == null) return false;
  if (digits.startsWith('00')) return stored.startsWith(digits.substring(2));
  if (digits.startsWith('0')) {
    final national = digits.substring(1);
    for (var codeLength = 1; codeLength <= 3; codeLength++) {
      if (stored.length > codeLength &&
          stored.substring(codeLength).startsWith(national)) {
        return true;
      }
    }
    return false;
  }
  return stored.contains(digits);
}
