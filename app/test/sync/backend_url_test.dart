import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/sync/backend_url.dart';

void main() {
  group('normalizeBackendUrl', () {
    test('trims spaces and trailing slashes -- "https://x/" + "/auth" would '
        'otherwise request "//auth" and 404', () {
      expect(
        normalizeBackendUrl('  https://ledgerly.example.com/// '),
        'https://ledgerly.example.com',
      );
    });

    test('adds https:// when the scheme was left off', () {
      expect(
        normalizeBackendUrl('ledgerly.example.com'),
        'https://ledgerly.example.com',
      );
    });
  });

  group('backendUrlProblem', () {
    test('a proper https address is fine everywhere', () {
      for (final android in [true, false]) {
        expect(
          backendUrlProblem(
            'https://ledgerly-backend.onrender.com',
            isAndroid: android,
          ),
          isNull,
        );
      }
    });

    test('an empty address asks for one', () {
      expect(
        backendUrlProblem('', isAndroid: true),
        contains("Enter your server's address"),
      );
    });

    test('localhost on a phone is the phone itself', () {
      expect(
        backendUrlProblem('http://localhost:8000', isAndroid: true),
        contains('this phone'),
      );
      expect(
        backendUrlProblem('https://127.0.0.1', isAndroid: true),
        contains('this phone'),
      );
    });

    test('plain http is blocked on Android but allowed on desktop (a server '
        'on the same machine or office network)', () {
      expect(
        backendUrlProblem('http://192.168.1.5:8000', isAndroid: true),
        contains('https://'),
      );
      expect(
        backendUrlProblem('http://192.168.1.5:8000', isAndroid: false),
        isNull,
      );
      expect(
        backendUrlProblem('http://localhost:8000', isAndroid: false),
        isNull,
      );
    });

    test('something that is not a web address says so', () {
      expect(
        backendUrlProblem('https://', isAndroid: false),
        contains('web address'),
      );
      expect(
        backendUrlProblem('ftp://ledgerly.example.com', isAndroid: false),
        contains('web address'),
      );
    });
  });
}
