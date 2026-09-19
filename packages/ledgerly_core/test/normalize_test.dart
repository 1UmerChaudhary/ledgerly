import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeName', () {
    test('lowercases, trims and strips punctuation', () {
      expect(normalizeName('  Rashid  Traders. '), 'rashid traders');
      expect(normalizeName('Ahmed & Sons'), 'ahmed and sons');
    });

    test('collapses common transliteration variants', () {
      expect(normalizeName('Mohammad Ali'), normalizeName('Muhammad Ali'));
      expect(normalizeName('Hussein Bros'), normalizeName('Hussain Brothers'));
      expect(normalizeName('Ahmad Traders'), normalizeName('Ahmed Traders'));
    });
  });

  group('normalizePhone', () {
    test(
      'reduces every local spelling to one digit string with country code',
      () {
        expect(normalizePhone('0300-1234567'), '923001234567');
        expect(normalizePhone('03001234567'), '923001234567');
        expect(normalizePhone('+92 300 1234567'), '923001234567');
        expect(normalizePhone('0092 300 1234567'), '923001234567');
        expect(normalizePhone('92 300 1234567'), '923001234567');
      },
    );

    test('honours a different default country code', () {
      expect(
        normalizePhone('050 123 4567', defaultCountryCode: '971'),
        '971501234567',
      );
    });

    test('returns null for blanks and too-short numbers', () {
      expect(normalizePhone(''), isNull);
      expect(normalizePhone('12345'), isNull);
      expect(normalizePhone('abc'), isNull);
    });
  });

  group('fuzzy customer search', () {
    final names = [
      'Rashid Traders',
      'Rasheed Bros',
      'Ahmed & Sons',
      'Bilal Oil Depot',
      'Karim Store',
    ];

    test('finds a misspelt name and ranks the closest first', () {
      final hits = fuzzySearch('rashd', names).map((h) => h.value).toList();
      expect(hits.first, 'Rashid Traders');
      expect(hits, contains('Rasheed Bros'));
      expect(hits, isNot(contains('Karim Store')));
    });

    test('two prefix matches rank by closeness of the whole word, deterministically', () {
      for (var i = 0; i < 20; i++) {
        final hits = fuzzySearch('rash', [
          'Rasheed Bros',
          'Rashid Traders',
          'Rashida Mills',
        ]);
        expect(hits.map((h) => h.value).toList(), [
          'Rashid Traders',
          'Rasheed Bros',
          'Rashida Mills',
        ]);
      }
    });

    test(
      'a word that contains the query matches, ranked below a prefix match',
      () {
        final hits = fuzzySearch('cake', [
          'Oil',
          'Oilcake',
          'Cake Mix',
        ]).map((h) => h.value).toList();
        expect(hits, ['Cake Mix', 'Oilcake']);
      },
    );

    test('matches on any word, not only the first', () {
      expect(fuzzySearch('depot', names).first.value, 'Bilal Oil Depot');
    });

    test('an empty query returns everything in the given order', () {
      expect(fuzzySearch('', names).map((h) => h.value), names);
    });

    test('similarity is 1 for identical and 0 for unrelated strings', () {
      expect(similarity('rashid', 'rashid'), 1.0);
      expect(similarity('rashid', 'xyzqw'), lessThan(0.3));
    });
  });
}
