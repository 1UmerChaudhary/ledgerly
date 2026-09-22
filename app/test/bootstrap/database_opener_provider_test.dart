import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/bootstrap/app_paths.dart';
import 'package:ledgerly/bootstrap/providers.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

/// Exercises the real [databaseOpenerProvider] body. The widget-test harness in
/// test/support/pump_app.dart replaces this provider with a fake opener, so
/// without this file nothing proves that the actual hex-encoding + `PRAGMA key`
/// closure runs, nor that leaving the session key null still opens a firm the
/// way it did before encryption existed.
///
/// This one cannot be a plain `dart test` the way the sibling SQLCipher proof
/// is: providers.dart imports flutter_riverpod, which pulls in dart:ui. It is
/// still a plain `test()` rather than a `testWidgets()`, so its real file I/O
/// never goes near the widget tester that would wedge on it.
void main() {
  late Directory tmp;
  late AppPaths paths;
  late ProviderContainer container;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('database_opener_test');
    paths = AppPaths(tmp);
    paths.firms.createSync(recursive: true);
    container = ProviderContainer(
      overrides: [appPathsProvider.overrideWithValue(paths)],
    );
  });

  tearDown(() {
    container.dispose();
    tmp.deleteSync(recursive: true);
  });

  test('no session key opens a firm exactly as an unencrypted firm', () async {
    expect(container.read(firmMasterKeyProvider), isNull);

    final db = await container.read(databaseOpenerProvider)('plain-firm');
    await db.customStatement('CREATE TABLE probe (id INTEGER)');
    await db.customStatement('INSERT INTO probe VALUES (7)');
    final rows = await db.customSelect('SELECT id FROM probe').get();
    expect(rows.single.data['id'], 7);
    await db.close();

    // The whole point of the null branch: still a plain readable database, so
    // every firm created before encryption keeps opening.
    expect(_headerOf(paths.firmDatabase('plain-firm')), 'SQLite format 3');
  });

  test('a session key opens a firm that only that key can read', () async {
    final key = Uint8List.fromList(List.generate(32, (i) => (i * 7) % 256));
    container.read(firmMasterKeyProvider.notifier).state = key;

    final db = await container.read(databaseOpenerProvider)('keyed-firm');
    await db.customStatement('CREATE TABLE probe (id INTEGER)');
    await db.customStatement('INSERT INTO probe VALUES (7)');
    await db.close();

    final file = paths.firmDatabase('keyed-firm');
    expect(_headerOf(file), isNot('SQLite format 3'));

    // Reopening through the same provider, with the same session key, reads
    // it back -- the round trip runs through the real closure both times.
    final reopened = await container.read(databaseOpenerProvider)('keyed-firm');
    final rows = await reopened.customSelect('SELECT id FROM probe').get();
    expect(rows.single.data['id'], 7);
    await reopened.close();

    // A different key must fail on the first real read. `PRAGMA key` itself
    // never rejects a wrong key, so opening alone proves nothing.
    final wrongHex = List.generate(
      32,
      (i) => 255 - i,
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final wrong = raw.sqlite3.open(file.path);
    wrong.execute('PRAGMA key = "x\'$wrongHex\'";');
    expect(() => wrong.select('SELECT id FROM probe'), throwsA(anything));
    wrong.close();
  });
}

String _headerOf(File file) =>
    String.fromCharCodes(file.readAsBytesSync().sublist(0, 15));
