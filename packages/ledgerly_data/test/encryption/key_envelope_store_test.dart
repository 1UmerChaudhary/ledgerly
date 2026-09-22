import 'dart:async';
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
    expect(
      readBack.byRecoveryCode.cipherText,
      envelope.byRecoveryCode.cipherText,
    );
    expect(readBack.byRecoveryCode.mac, envelope.byRecoveryCode.mac);
    expect(readBack.recoveryCodeSalt, envelope.recoveryCodeSalt);
  });

  test(
    'reading a path with no envelope file returns null, not an exception',
    () async {
      final store = KeyEnvelopeStore(File('${tmp.path}/nothing-here.key.json'));
      expect(await store.read(), isNull);
    },
  );

  test('writing twice replaces the file cleanly (no leftover .tmp)', () async {
    final store = KeyEnvelopeStore(File('${tmp.path}/firm.key.json'));
    await store.write(makeEnvelope());
    await store.write(makeEnvelope());
    final leftovers = tmp.listSync().where((f) => f.path.endsWith('.tmp'));
    expect(leftovers, isEmpty);
  });

  test('retireBackup removes the superseded .bak once the new envelope reads '
      'back as the one just written', () async {
    final path = File('${tmp.path}/firm.key.json');
    final store = KeyEnvelopeStore(path);
    await store.write(makeEnvelope(variant: 1));
    final rotated = makeEnvelope(variant: 2);
    await store.write(rotated);
    expect(File('${path.path}.bak').existsSync(), isTrue);

    await store.retireBackup(rotated);

    expect(File('${path.path}.bak').existsSync(), isFalse);
    // The live envelope is untouched: this removes the retired one, never
    // the one in use.
    expect((await store.read())!.passphraseSalt, rotated.passphraseSalt);
  });

  test('retireBackup keeps .bak when the canonical file is not what was just '
      'written -- the only copy that still opens the firm', () async {
    final path = File('${tmp.path}/firm.key.json');
    final store = KeyEnvelopeStore(path);
    await store.write(makeEnvelope(variant: 1));
    await store.write(makeEnvelope(variant: 2));
    // A write that did not land the way the caller believes: the canonical
    // file holds something else entirely.
    await path.writeAsString(jsonEncode(makeEnvelope(variant: 9).toJson()));

    await expectLater(
      store.retireBackup(makeEnvelope(variant: 2)),
      throwsA(isA<StateError>()),
    );
    expect(File('${path.path}.bak').existsSync(), isTrue);
  });

  test(
    'a previous envelope is preserved as a .bak file after a second write',
    () async {
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
      expect(
        backedUpEnvelope!.byPassphrase.nonce,
        envelopeA.byPassphrase.nonce,
      );
      expect(
        backedUpEnvelope.byPassphrase.cipherText,
        envelopeA.byPassphrase.cipherText,
      );
    },
  );

  test(
    'a crash between backup and final rename leaves the old envelope readable',
    () async {
      final store = KeyEnvelopeStore(File('${tmp.path}/firm.key.json'));
      final envelopeA = makeEnvelope(variant: 1);
      final envelopeB = makeEnvelope(variant: 2);

      // Real write 1: create canonical file with envelopeA
      await store.write(envelopeA);

      // Coordinate reading during a real second write's crash window
      final readMidSecondWrite = Completer<KeyEnvelope?>();
      store.afterBackupHook = () async {
        // At this exact point in a real second write(): backup copy has
        // completed, final rename has NOT happened yet. This is the crash
        // window under test.
        readMidSecondWrite.complete(await store.read());
      };

      // Real second write: triggers the hook at the crash boundary
      await store.write(envelopeB);
      final duringCrashWindow = await readMidSecondWrite.future;

      // If write() still used the old buggy rename(), path would have been
      // renamed away at this point and read() would return null. With the
      // fixed copy(), path still holds envelopeA here.
      expect(duringCrashWindow, isNotNull);
      expect(
        duringCrashWindow!.byPassphrase.nonce,
        envelopeA.byPassphrase.nonce,
      );
      expect(
        duringCrashWindow.byPassphrase.cipherText,
        envelopeA.byPassphrase.cipherText,
      );
      expect(duringCrashWindow.byPassphrase.mac, envelopeA.byPassphrase.mac);
    },
  );
}
