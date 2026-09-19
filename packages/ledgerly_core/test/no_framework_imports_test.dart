import 'dart:io';

import 'package:test/test.dart';

// The core package must stay pure Dart so it can run in tests in milliseconds
// and be reused by any future Dart consumer (CLI tools, a Dart server).
void main() {
  test('core never imports flutter, drift or sqlite', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      for (final line in f.readAsLinesSync()) {
        if (RegExp(r"^import 'package:(flutter|drift|sqlite3)").hasMatch(line)) {
          offenders.add('${f.path}: $line');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
