import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('envelope_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  KeyEnvelope makeEnvelope({int variant = 1}) => KeyEnvelope(
    byPassphrase: WrappedKey(
      nonce: [1 + variant, 2 + variant, 3 + variant],
      cipherText: [4 + variant, 5 + variant, 6 + variant],
      mac: [7 + variant, 8 + variant, 9 + variant],
    ),
    passphraseSalt: [10 + variant, 11 + variant, 12 + variant],
    byRecoveryCode: WrappedKey(
      nonce: [13 + variant, 14 + variant],
      cipherText: [15 + variant, 16 + variant],
      mac: [17 + variant, 18 + variant],
    ),
    recoveryCodeSalt: [19 + variant, 20 + variant],
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
    expect(readBack.byRecoveryCode.cipherText, envelope.byRecoveryCode.cipherText);
    expect(readBack.byRecoveryCode.mac, envelope.byRecoveryCode.mac);
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
    final envelopeA = makeEnvelope(variant: 1);
    final envelopeB = makeEnvelope(variant: 2);

    await store.write(envelopeA);
    await store.write(envelopeB);

    // Verify .bak file exists
    expect(File('${tmp.path}/firm.key.json.bak').existsSync(), isTrue);

    // Verify .bak contains the old envelope (A), not the new one (B)
    final backup = KeyEnvelopeStore(File('${tmp.path}/firm.key.json.bak'));
    final backedUpEnvelope = await backup.read();
    expect(backedUpEnvelope, isNotNull);
    expect(backedUpEnvelope!.byPassphrase.nonce, envelopeA.byPassphrase.nonce);
    expect(backedUpEnvelope.byPassphrase.cipherText, envelopeA.byPassphrase.cipherText);
  });

  test('a crash between backup and final rename leaves old envelope readable', () async {
    final store = KeyEnvelopeStore(File('${tmp.path}/firm.key.json'));
    final envelopeA = makeEnvelope(variant: 1);
    final envelopeB = makeEnvelope(variant: 2);
    final envelopeC = makeEnvelope(variant: 3);

    // Real write 1: creates canonical file with envelopeA
    await store.write(envelopeA);

    // Simulate the exact intermediate state that exists between step 2 (copy to .bak)
    // and step 3 (rename .tmp to path) of a second write: a .tmp file holds the new
    // envelope's JSON, but hasn't been renamed into place yet. The canonical path
    // still holds the old envelope (never touched by copy-based backup).
    final tmpFile = File('${tmp.path}/firm.key.json.tmp');
    await tmpFile.writeAsString(
      jsonEncode(envelopeB.toJson()),
      flush: true,
    );

    // read() should still return envelopeA from the canonical file,
    // NOT null, because path was never moved or deleted by the backup step
    final readBack = await store.read();
    expect(readBack, isNotNull);
    expect(readBack!.byPassphrase.nonce, envelopeA.byPassphrase.nonce);
    expect(readBack.byPassphrase.cipherText, envelopeA.byPassphrase.cipherText);
    expect(readBack.byPassphrase.mac, envelopeA.byPassphrase.mac);

    // Bonus: a subsequent real write should complete normally despite the stray .tmp,
    // proving that leftover .tmp from a previous crash doesn't wedge future writes
    await store.write(envelopeC);
    final readAfterRecover = await store.read();
    expect(readAfterRecover, isNotNull);
    expect(readAfterRecover!.byPassphrase.nonce, envelopeC.byPassphrase.nonce);
  });
}
