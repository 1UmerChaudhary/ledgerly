import 'dart:io';
import 'dart:typed_data';

import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('envelope_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  KeyEnvelope makeEnvelope() => KeyEnvelope(
    byPassphrase: const WrappedKey(nonce: [1, 2, 3], cipherText: [4, 5, 6], mac: [7, 8, 9]),
    passphraseSalt: [10, 11, 12],
    byRecoveryCode: const WrappedKey(nonce: [13, 14], cipherText: [15, 16], mac: [17, 18]),
    recoveryCodeSalt: [19, 20],
  );

  test('a written envelope reads back with identical field values', () async {
    final store = KeyEnvelopeStore(File('${tmp.path}/firm.key.json'));
    final envelope = makeEnvelope();

    await store.write(envelope);
    final readBack = await store.read();

    expect(readBack, isNotNull);
    expect(readBack!.byPassphrase.nonce, envelope.byPassphrase.nonce);
    expect(readBack.byPassphrase.cipherText, envelope.byPassphrase.cipherText);
    expect(readBack.byPassphrase.mac, envelope.byPassphrase.mac);
    expect(readBack.passphraseSalt, envelope.passphraseSalt);
    expect(readBack.byRecoveryCode.nonce, envelope.byRecoveryCode.nonce);
    expect(readBack.recoveryCodeSalt, envelope.recoveryCodeSalt);
  });

  test('reading a path with no envelope file returns null, not an exception', () async {
    final store = KeyEnvelopeStore(File('${tmp.path}/nothing-here.key.json'));
    expect(await store.read(), isNull);
  });

  test('writing twice replaces the file cleanly (no leftover .tmp)', () async {
    final store = KeyEnvelopeStore(File('${tmp.path}/firm.key.json'));
    await store.write(makeEnvelope());
    await store.write(makeEnvelope());
    final leftovers = tmp.listSync().where((f) => f.path.endsWith('.tmp'));
    expect(leftovers, isEmpty);
  });

  test('a previous envelope is preserved as a .bak file after a second write', () async {
    final store = KeyEnvelopeStore(File('${tmp.path}/firm.key.json'));
    await store.write(makeEnvelope());
    await store.write(makeEnvelope());
    expect(File('${tmp.path}/firm.key.json.bak').existsSync(), isTrue);
  });
}
