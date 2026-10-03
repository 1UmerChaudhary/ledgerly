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

/// Ranks [candidates] against [query]; see [fuzzySearchBy].
List<FuzzyHit<String>> fuzzySearch(
  String query,
  Iterable<String> candidates, {
  double threshold = 0.55,
}) => fuzzySearchBy(query, candidates, (c) => c, threshold: threshold);

/// Ranks [items] by how well [labelOf] matches [query], returning the items
/// themselves -- never re-looked-up by label, because two customers can
/// share a name and a label-keyed map silently drops one of them.
///
/// Every word of the query must match some word of the label, in any order,
/// so a half-typed full name ("rashid trad") still finds "Rashid Traders".
/// Per query word: a label word starting with it outranks one merely
/// containing it, which outranks a misspelling match. A candidate ranks by
/// its weakest word; ties go to the closest overall, then the shorter label,
/// then alphabetical, then input order, so the order is the same every time
/// (Dart's sort is not stable on its own).
/// Firms have hundreds or a few thousand customers, so this runs in memory.
List<FuzzyHit<T>> fuzzySearchBy<T>(
  String query,
  Iterable<T> items,
  String Function(T) labelOf, {
  double threshold = 0.55,
}) {
  final queryWords = normalizeName(query)
      .split(' ')
      .where((w) => w.isNotEmpty)
      .toList();
  if (queryWords.isEmpty) return [for (final i in items) FuzzyHit(i, 1.0)];
  final ranked = <({T item, String label, int tier, double score, int at})>[];
  var at = 0;
  for (final item in items) {
    final label = labelOf(item);
    final labelWords = normalizeName(label).split(' ');
    var tier = 2;
    var total = 0.0;
    var matched = true;
    for (final q in queryWords) {
      final (t, score) = _bestWordMatch(q, labelWords);
      if (t == 0 && score < threshold) {
        matched = false;
        break;
      }
      if (t < tier) tier = t;
      total += score;
    }
    if (matched) {
      ranked.add((
        item: item,
        label: label,
        tier: tier,
        score: total / queryWords.length,
        at: at,
      ));
    }
    at++;
  }
  ranked.sort((a, b) {
    if (a.tier != b.tier) return b.tier.compareTo(a.tier);
    if (a.score != b.score) return b.score.compareTo(a.score);
    if (a.label.length != b.label.length) {
      return a.label.length.compareTo(b.label.length);
    }
    final byLabel = a.label.compareTo(b.label);
    return byLabel != 0 ? byLabel : a.at.compareTo(b.at);
  });
  return [for (final r in ranked) FuzzyHit(r.item, r.tier > 0 ? 1.0 : r.score)];
}

/// The best match of one query word [q] against a label's words, as
/// (tier, closeness). Tiers: 2 = a word starts with [q], 1 = a word
/// contains it, 0 = merely similar (misspelling).
(int, double) _bestWordMatch(String q, List<String> words) {
  var tier = 0;
  var best = 0.0;
  for (final w in words) {
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
  return (tier, best);
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
