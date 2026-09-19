import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:test/test.dart';

void main() {
  group('device short code', () {
    test('is four base32 characters derived from the device uuid', () {
      final code = deviceShortCode('7f3a9c2e-1b4d-4e8f-9a6b-0c1d2e3f4a5b');
      expect(code, matches(RegExp(r'^[A-Z2-7]{4}$')));
    });

    test('is stable for the same uuid and differs for another', () {
      const a = '7f3a9c2e-1b4d-4e8f-9a6b-0c1d2e3f4a5b';
      const b = '7f3a9c2e-1b4d-4e8f-9a6b-0c1d2e3f4a5c';
      expect(deviceShortCode(a), deviceShortCode(a));
      expect(deviceShortCode(a), isNot(deviceShortCode(b)));
    });
  });

  group('bill numbers', () {
    test('render as code-seq', () {
      expect(renderDisplayNo('A3F9', 1044), 'A3F9-1044');
    });

    test('next sequence is max + 1, starting at 1, as an integer', () {
      expect(nextDisplaySeq(null), 1);
      expect(nextDisplaySeq(9), 10);
    });
  });
}
