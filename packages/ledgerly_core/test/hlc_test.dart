import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:test/test.dart';

void main() {
  group('Hlc — timestamps that never go backwards on a device', () {
    test('follows the wall clock when it moves forward', () {
      var now = 1000;
      final hlc = Hlc(nowMs: () => now);
      expect(hlc.next(), 1000);
      now = 1500;
      expect(hlc.next(), 1500);
    });

    test('keeps ticking forward when the wall clock jumps backwards', () {
      var now = 5000;
      final hlc = Hlc(nowMs: () => now);
      hlc.next();
      now = 1000; // user set the clock back four seconds
      expect(hlc.next(), 5001);
      expect(hlc.next(), 5002);
    });

    test('applies the learned server offset', () {
      final hlc = Hlc(nowMs: () => 1000, offsetMs: 3600000);
      expect(hlc.next(), 3601000);
    });

    test('never issues a stamp at or below one seen from another device', () {
      final hlc = Hlc(nowMs: () => 1000);
      hlc.observe(9000); // pulled a row stamped 9000
      expect(hlc.next(), 9001);
    });

    test('is seeded from the newest stamp already in the database', () {
      final hlc = Hlc(nowMs: () => 1000, last: 7000);
      expect(hlc.next(), 7001);
    });

    test(
      'reseeding to server time after a skew rejection lowers the floor',
      () {
        final hlc = Hlc(nowMs: () => 1000, last: 99999999);
        hlc.reseed(2000);
        expect(hlc.next(), 2001);
      },
    );
  });
}
