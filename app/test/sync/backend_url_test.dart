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

    test('strips slashes from the path only, never from the scheme -- a '
        'half-typed "https://" stays recognisably half-typed', () {
      expect(normalizeBackendUrl('https://'), 'https://');
      expect(normalizeBackendUrl('http://'), 'http://');
      expect(
        normalizeBackendUrl('https://ledgerly.example.com/api/'),
        'https://ledgerly.example.com/api',
      );
      expect(
        normalizeBackendUrl('https://ledgerly.example.com:8443/'),
        'https://ledgerly.example.com:8443',
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

    test('a half-typed or mistyped address is refused after normalizing, '
        'which is what Settings actually checks', () {
      for (final typed in ['https://', 'http://', 'http:/host', 'https:host']) {
        expect(
          backendUrlProblem(normalizeBackendUrl(typed), isAndroid: false),
          contains('web address'),
          reason: typed,
        );
      }
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

  group('effectiveBackendUrl', () {
    const builtIn = 'https://ledgerly-backend-4fgopyhzqq-uc.a.run.app';

    test('nothing saved: the address built into the app', () {
      for (final stored in [null, '', '   ']) {
        expect(
          effectiveBackendUrl(stored, builtIn: builtIn, isAndroid: true),
          builtIn,
        );
      }
    });

    test('a saved address that cannot work here (localhost on a phone, '
        'saved by an older version) gives way to the built-in one', () {
      expect(
        effectiveBackendUrl(
          'http://localhost:8000',
          builtIn: builtIn,
          isAndroid: true,
        ),
        builtIn,
      );
    });

    test('a working saved address is kept -- a business can run its own '
        'server -- and so is localhost on a desktop, for development', () {
      expect(
        effectiveBackendUrl(
          'https://my-own-server.example.com/',
          builtIn: builtIn,
          isAndroid: true,
        ),
        'https://my-own-server.example.com',
      );
      expect(
        effectiveBackendUrl(
          'http://localhost:8000',
          builtIn: builtIn,
          isAndroid: false,
        ),
        'http://localhost:8000',
      );
    });

    test('with nothing built in, the saved address is all there is', () {
      expect(
        effectiveBackendUrl(
          'http://localhost:8000',
          builtIn: '',
          isAndroid: true,
        ),
        'http://localhost:8000',
      );
    });
  });
}
