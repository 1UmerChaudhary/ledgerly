/// Spellings that mean the same name in Urdu-to-Latin transliteration. Applied
/// word by word after lowercasing, so "Mohammad" and "Muhammad" collide.
const Map<String, String> _nameVariants = {
  'mohammad': 'muhammad',
  'mohammed': 'muhammad',
  'muhammed': 'muhammad',
  'mohd': 'muhammad',
  'hussein': 'hussain',
  'husain': 'hussain',
  'hussain': 'hussain',
  'ahmad': 'ahmed',
  'bros': 'brothers',
  'and': 'and',
  '&': 'and',
  'co': 'company',
};

/// Lowercase, punctuation-free, single-spaced, variant-collapsed form used for
/// search and for the "similar customer exists" warning.
String normalizeName(String name) {
  final words = name
      .toLowerCase()
      .replaceAll('&', ' and ')
      .replaceAll(RegExp(r'[^a-z0-9؀-ۿ\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => _nameVariants[w] ?? w);
  return words.join(' ');
}

/// Digits-only phone with the country code applied, the key used to block
/// duplicate customers. "0300-1234567", "03001234567" and "+92 300 1234567"
/// all become "923001234567". Null when it cannot be a phone number.
String? normalizePhone(String input, {String defaultCountryCode = '92'}) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.startsWith('0')) digits = defaultCountryCode + digits.substring(1);
  if (digits.length < 9 + defaultCountryCode.length - 1) return null;
  if (!digits.startsWith(defaultCountryCode) && digits.length <= 10) {
    digits = defaultCountryCode + digits;
  }
  return digits;
}

class FuzzyHit<T> {
  const FuzzyHit(this.value, this.score);
  final T value;
  final double score;
}

/// Ranks [candidates] against [query]. A word that starts with the query
/// outranks one that merely contains it, which outranks a misspelling match;
/// within a tier the word closest to the query as a whole wins, then the
/// shorter label, then alphabetical, so the order is the same every time
/// (Dart's sort is not stable on its own).
/// Firms have hundreds or a few thousand customers, so this runs in memory.
List<FuzzyHit<String>> fuzzySearch(
  String query,
  Iterable<String> candidates, {
  double threshold = 0.55,
}) {
  final q = normalizeName(query);
  if (q.isEmpty) return candidates.map((c) => FuzzyHit(c, 1.0)).toList();
  // Rank tiers: 2 = a word starts with the query, 1 = a word contains it,
  // 0 = merely similar (misspelling). Within a tier, whole-word closeness.
  final ranked = <(String, int, double)>[];
  for (final c in candidates) {
    var tier = 0;
    var best = 0.0;
    for (final w in normalizeName(c).split(' ')) {
      final int t;
      final double score;
      if (w.startsWith(q)) {
        t = 2;
        score = similarity(q, w);
      } else if (w.contains(q)) {
        t = 1;
        score = similarity(q, w);
      } else {
        t = 0;
        score = similarity(
          q,
          w.length > q.length + 2 ? w.substring(0, q.length + 2) : w,
        );
      }
      if (t > tier || (t == tier && score > best)) {
        tier = t;
        best = score;
      }
    }
    if (tier > 0 || best >= threshold) ranked.add((c, tier, best));
  }
  ranked.sort((a, b) {
    if (a.$2 != b.$2) return b.$2.compareTo(a.$2);
    if (a.$3 != b.$3) return b.$3.compareTo(a.$3);
    if (a.$1.length != b.$1.length) return a.$1.length.compareTo(b.$1.length);
    return a.$1.compareTo(b.$1);
  });
  return [for (final r in ranked) FuzzyHit(r.$1, r.$2 > 0 ? 1.0 : r.$3)];
}

/// 1.0 for identical strings, falling towards 0 with each edit (insert, delete,
/// substitute, or swap of adjacent characters — the Damerau variant, because
/// "rahsid" for "rashid" is one typing slip, not two).
double similarity(String a, String b) {
  if (a == b) return 1.0;
  if (a.isEmpty || b.isEmpty) return 0.0;
  final d = _damerauLevenshtein(a, b);
  final longest = a.length > b.length ? a.length : b.length;
  return 1.0 - d / longest;
}

int _damerauLevenshtein(String s, String t) {
  final m = s.length, n = t.length;
  final d = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
  for (var i = 0; i <= m; i++) {
    d[i][0] = i;
  }
  for (var j = 0; j <= n; j++) {
    d[0][j] = j;
  }
  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      final cost = s[i - 1] == t[j - 1] ? 0 : 1;
      var v = d[i - 1][j] + 1;
      if (d[i][j - 1] + 1 < v) v = d[i][j - 1] + 1;
      if (d[i - 1][j - 1] + cost < v) v = d[i - 1][j - 1] + cost;
      if (i > 1 &&
          j > 1 &&
          s[i - 1] == t[j - 2] &&
          s[i - 2] == t[j - 1] &&
          d[i - 2][j - 2] + 1 < v) {
        v = d[i - 2][j - 2] + 1;
      }
      d[i][j] = v;
    }
  }
  return d[m][n];
}
