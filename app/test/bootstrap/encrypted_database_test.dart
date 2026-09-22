import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:test/test.dart';

/// Proves empirically that the SQLite this build ships is SQLCipher-capable and
/// behaves the way the encryption design assumes: a raw hex key is accepted via
/// `PRAGMA key`, and a wrong key genuinely fails on the first read rather than
/// silently returning plaintext rows.
void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('encrypted_db_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('a database keyed at creation can only be reopened with the same raw '
      'key', () async {
    final dbFile = File('${tmp.path}/test.db');
    final key = Uint8List.fromList(List.generate(32, (i) => i));
    final keyHex = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    // Create + key it.
    final db = raw.sqlite3.open(dbFile.path);
    db.execute('PRAGMA key = "x\'$keyHex\'";');
    db.execute('CREATE TABLE t (id INTEGER)');
    db.execute('INSERT INTO t VALUES (1)');
    db.close();

    // The file on disk must not be readable plaintext SQLite: without this the
    // two checks below would both pass against an unencrypted database.
    final header = dbFile.readAsBytesSync().sublist(0, 16);
    expect(String.fromCharCodes(header), isNot(startsWith('SQLite format 3')));

    // Reopening with the SAME key and reading must succeed.
    final reopened = raw.sqlite3.open(dbFile.path);
    reopened.execute('PRAGMA key = "x\'$keyHex\'";');
    final rows = reopened.select('SELECT * FROM t');
    expect(rows.length, 1);
    reopened.close();

    // Reopening with a WRONG key must fail on the first real read, not
    // silently succeed -- PRAGMA key never rejects a wrong key by itself.
    final wrongKeyHex = List.generate(
      32,
      (i) => 255 - i,
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final wrongOpen = raw.sqlite3.open(dbFile.path);
    wrongOpen.execute('PRAGMA key = "x\'$wrongKeyHex\'";');
    expect(() => wrongOpen.select('SELECT * FROM t'), throwsA(anything));
    wrongOpen.close();
  });
}
