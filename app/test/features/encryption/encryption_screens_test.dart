import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/bootstrap/providers.dart';
import 'package:ledgerly/features/dashboard/dashboard_screen.dart';
import 'package:ledgerly/features/encryption/encryption_service.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../../support/pump_app.dart';

/// Every screen here is wiring over logic that is already proven against real
/// files and real crypto in `encryption_service_test.dart` and
/// `encryption_migration_test.dart`. What these tests hold to account is the
/// wiring itself: which service method the UI calls, with which arguments,
/// and what it does with the answer — including the three obligations earlier
/// tasks deliberately left for this one (retiring a crashed migration's
/// plaintext copy, reacting to an unverifiable database, and never leaving a
/// session key in memory after a lock).
Future<void> seed(AppDatabase db, DeviceContext ctx) async {
  await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
  await CustomersRepository(db, ctx).create(name: 'Rashid Traders');
}

Future<void> type(WidgetTester tester, Key key, String text) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(key), text);
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

String shownRecoveryCode(WidgetTester tester) => tester
    .widget<SelectableText>(find.byKey(const Key('encryption.recoveryCode')))
    .data!;

void main() {
  testWidgets(
    'setting up encryption requires typing the recovery code back before enabling',
    (tester) async {
      final encryption = FakeEncryptionService();
      final container = await pumpLedgerly(
        tester,
        seed: seed,
        encryption: encryption,
      );

      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await tap(tester, const Key('encryption.enableSection'));
      expect(find.byKey(const Key('encryption.setupWizard')), findsOneWidget);

      await type(
        tester,
        const Key('encryption.passphrase'),
        'a good passphrase',
      );
      await type(
        tester,
        const Key('encryption.passphraseConfirm'),
        'a good passphrase',
      );
      await tap(tester, const Key('encryption.generate'));

      // An existing firm with rows in it is migrated, never merely wrapped in
      // an envelope over a still-plaintext file.
      expect(encryption.migrations, [testFirmId]);
      final code = shownRecoveryCode(tester);
      expect(code, isNotEmpty);

      // The file on disk is ciphertext the moment the migration returns, so
      // the session holds its key from here -- see the Esc test below for
      // why waiting until the type-back is not an option. What the type-back
      // gates is the WIZARD finishing, never whether the key works.
      expect(container.read(firmMasterKeyProvider), isNotNull);

      // The wizard does not finish until the printed code has been typed
      // back: the button is there, and tapping it does nothing.
      await tap(tester, const Key('encryption.confirmEnable'));
      expect(find.byKey(const Key('encryption.enabled')), findsNothing);
      expect(find.byKey(const Key('encryption.setupWizard')), findsOneWidget);

      // A near miss is still a miss.
      await type(
        tester,
        const Key('encryption.recoveryCodeConfirm'),
        '${code.substring(0, code.length - 1)}X',
      );
      await tap(tester, const Key('encryption.confirmEnable'));
      expect(find.byKey(const Key('encryption.enabled')), findsNothing);

      await type(tester, const Key('encryption.recoveryCodeConfirm'), code);
      await tap(tester, const Key('encryption.confirmEnable'));

      expect(await encryption.isEncrypted(testFirmId), isTrue);
      expect(container.read(firmMasterKeyProvider), isNotNull);
      expect(find.byKey(const Key('encryption.enabled')), findsOneWidget);
    },
    variant: windowsOnly,
  );

  testWidgets(
    'leaving the wizard while the recovery code is on screen lands on a '
    'working dashboard, not on a firm whose connection was closed under it',
    (tester) async {
      final encryption = FakeEncryptionService();
      final container = await pumpLedgerly(
        tester,
        seed: seed,
        encryption: encryption,
      );
      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await tap(tester, const Key('encryption.enableSection'));
      await type(tester, const Key('encryption.passphrase'), 'a passphrase');
      await type(
        tester,
        const Key('encryption.passphraseConfirm'),
        'a passphrase',
      );
      await tap(tester, const Key('encryption.generate'));
      expect(find.byKey(const Key('encryption.recoveryCode')), findsOneWidget);

      // This route sits inside the app shell: the navigation rail is live and
      // Esc goes to the dashboard. The migration has already closed the
      // firm's connection, so unless the key reached the session the instant
      // the migration returned, this keypress arrives at a screen querying a
      // database nobody can open.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape, platform: 'windows');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dashboard.search')), findsOneWidget);
      // The dashboard's own query, against whatever connection the firm is
      // holding right now -- the one thing that tells a live connection from
      // a closed one.
      expect(
        container.read(dashboardRowsProvider).hasError,
        isFalse,
        reason:
            'the dashboard queried the connection the migration closed: '
            '${container.read(dashboardRowsProvider).error}',
      );
      expect(container.read(firmMasterKeyProvider), isNotNull);
      expect(
        find.byKey(const Key('encryption.unlockScreen')),
        findsNothing,
        reason: 'the firm is unlocked in this session, not locked out of it',
      );
    },
    variant: windowsOnly,
  );

  testWidgets(
    'the wizard states the consequence of losing both secrets before the '
    'commit button is ever reachable',
    (tester) async {
      await pumpLedgerly(tester, seed: seed);
      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await tap(tester, const Key('encryption.enableSection'));
      expect(
        find.textContaining('cannot be recovered by anyone'),
        findsOneWidget,
      );
    },
    variant: windowsOnly,
  );

  testWidgets(
    'once a migrated firm is showing its recovery code, the wizard says '
    'encryption is already on rather than promising to turn it on',
    (tester) async {
      final encryption = FakeEncryptionService();
      await pumpLedgerly(tester, seed: seed, encryption: encryption);
      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await tap(tester, const Key('encryption.enableSection'));
      await type(tester, const Key('encryption.passphrase'), 'pass phrase');
      await type(
        tester,
        const Key('encryption.passphraseConfirm'),
        'pass phrase',
      );
      await tap(tester, const Key('encryption.generate'));

      // The database is ciphertext by now, so copy that implies otherwise
      // would send a user away without writing the one thing down.
      expect(await encryption.isEncrypted(testFirmId), isTrue);
      final message = tester
          .widget<Text>(find.byKey(const Key('encryption.codeShownMessage')))
          .data!;
      expect(message, contains('Encryption is now ON'));
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('encryption.confirmEnable')),
            )
            .child,
        isA<Text>().having(
          (t) => t.data,
          'label',
          "I've written it down — continue",
        ),
      );
    },
    variant: windowsOnly,
  );

  testWidgets(
    'migrating an existing firm offers, but does not force, deleting the '
    'plaintext backups it leaves behind',
    (tester) async {
      final encryption = FakeEncryptionService();
      final cleaner = FakePlaintextBackupCleaner(
        files: ['/backups/a.db', '/backups/b.db', '/usb/a.db'],
      );
      await pumpLedgerly(
        tester,
        seed: seed,
        encryption: encryption,
        backupCleaner: cleaner,
      );

      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await tap(tester, const Key('encryption.enableSection'));
      await type(tester, const Key('encryption.passphrase'), 'pass phrase');
      await type(
        tester,
        const Key('encryption.passphraseConfirm'),
        'pass phrase',
      );
      await tap(tester, const Key('encryption.generate'));
      await type(
        tester,
        const Key('encryption.recoveryCodeConfirm'),
        shownRecoveryCode(tester),
      );
      await tap(tester, const Key('encryption.confirmEnable'));

      expect(find.textContaining('3 plaintext backup'), findsOneWidget);
      expect(cleaner.deleteCalls, 0); // offered, never automatic
      await tap(tester, const Key('encryption.deleteOldBackups'));
      expect(cleaner.deleteCalls, 1);
    },
    variant: windowsOnly,
  );

  testWidgets(
    'a wrong passphrase on the unlock screen shows an error and does not '
    'navigate away; the right one opens the firm',
    (tester) async {
      final encryption = FakeEncryptionService()
        ..encryptNow(testFirmId, passphrase: 'right one');
      final container = await pumpLedgerly(
        tester,
        seed: seed,
        encryption: encryption,
      );

      expect(find.byKey(const Key('encryption.unlockScreen')), findsOneWidget);

      await type(tester, const Key('encryption.unlockPassphrase'), 'wrong one');
      await tap(tester, const Key('encryption.unlock'));

      expect(find.byKey(const Key('encryption.unlockScreen')), findsOneWidget);
      expect(find.byKey(const Key('encryption.unlockError')), findsOneWidget);
      expect(container.read(firmMasterKeyProvider), isNull);

      await type(tester, const Key('encryption.unlockPassphrase'), 'right one');
      await tap(tester, const Key('encryption.unlock'));

      expect(find.byKey(const Key('encryption.unlockScreen')), findsNothing);
      expect(container.read(firmMasterKeyProvider), isNotNull);
      expect(find.byKey(const Key('dashboard.search')), findsOneWidget);
    },
  );

  testWidgets(
    'a recovery code typed in the case and spacing a human would use still '
    'unlocks, and a new passphrase is then required before anything else',
    (tester) async {
      final encryption = FakeEncryptionService();
      final code = encryption.encryptNow(testFirmId, passphrase: 'forgotten');
      final container = await pumpLedgerly(
        tester,
        seed: seed,
        encryption: encryption,
      );

      await tap(tester, const Key('encryption.forgotPassphrase'));
      await type(
        tester,
        const Key('encryption.recoveryCodeInput'),
        code.toLowerCase().replaceAll('-', ' '),
      );
      await tap(tester, const Key('encryption.recoverySubmit'));

      expect(container.read(firmMasterKeyProvider), isNotNull);
      expect(
        find.byKey(const Key('encryption.newPassphraseScreen')),
        findsOneWidget,
      );

      // Not skippable: neither Esc nor the system back gesture leaves it.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await systemBack(tester);
      expect(
        find.byKey(const Key('encryption.newPassphraseScreen')),
        findsOneWidget,
      );

      await type(tester, const Key('encryption.passphrase'), 'a new one');
      await type(
        tester,
        const Key('encryption.passphraseConfirm'),
        'a new one',
      );
      await tap(tester, const Key('encryption.setNewPassphrase'));

      expect(
        find.byKey(const Key('encryption.newPassphraseScreen')),
        findsNothing,
      );
      expect(find.byKey(const Key('dashboard.search')), findsOneWidget);
      // The replacement passphrase is the one that unlocks now.
      expect(
        await encryption.unlockWithPassphrase(testFirmId, 'a new one'),
        isNotNull,
      );
    },
  );

  testWidgets(
    'a recovery code that fails its check symbol is rejected without ever '
    'reaching the service',
    (tester) async {
      final encryption = FakeEncryptionService()
        ..encryptNow(testFirmId, passphrase: 'forgotten');
      final container = await pumpLedgerly(
        tester,
        seed: seed,
        encryption: encryption,
      );

      await tap(tester, const Key('encryption.forgotPassphrase'));
      await type(
        tester,
        const Key('encryption.recoveryCodeInput'),
        'XXXX-XXXX-XXXX',
      );
      await tap(tester, const Key('encryption.recoverySubmit'));

      expect(find.byKey(const Key('encryption.unlockError')), findsOneWidget);
      expect(container.read(firmMasterKeyProvider), isNull);
    },
  );

  testWidgets(
    'opening a firm retires the plaintext copy an interrupted migration left '
    'behind, using the key the unlock just produced',
    (tester) async {
      final encryption = FakeEncryptionService()
        ..encryptNow(testFirmId, passphrase: 'open sesame');
      await pumpLedgerly(tester, seed: seed, encryption: encryption);

      // Locked: nothing holds the key yet, so nothing can retire anything.
      expect(encryption.retiredCopies, isEmpty);

      await type(
        tester,
        const Key('encryption.unlockPassphrase'),
        'open sesame',
      );
      await tap(tester, const Key('encryption.unlock'));

      expect(encryption.retiredCopies, isNotEmpty);
      expect(encryption.retiredCopies.first.firmId, testFirmId);
      expect(
        encryption.retiredCopies.first.masterKey,
        encryption.masterKeyOf(testFirmId),
      );
      // And the interrupted-migration check runs at firm-open time, not only
      // inside a migration that is already under way.
      expect(encryption.recoveryChecks, contains(testFirmId));
    },
  );

  testWidgets(
    'a firm whose database cannot be classified gets a plain error, not the '
    'dashboard and not an opaque SQLite failure later',
    (tester) async {
      final encryption = FakeEncryptionService()
        ..recoveryOutcome = RecoveryOutcome.indeterminate;
      await pumpLedgerly(tester, seed: seed, encryption: encryption);

      expect(find.byKey(const Key('encryption.unverifiable')), findsOneWidget);
      expect(find.textContaining('could not be verified'), findsOneWidget);
      expect(find.byKey(const Key('dashboard.search')), findsNothing);
    },
  );

  testWidgets(
    'a firm whose plaintext copy cannot be retired is not opened either — it '
    'stops with the reason on screen',
    (tester) async {
      // Deliberately fail-closed: the app holds the key, there is a complete
      // plaintext copy of this ledger on disk, and it cannot prove the
      // encrypted file it would open instead is sound. Opening anyway would
      // leave both problems in place and say nothing.
      final encryption = FakeEncryptionService()
        ..encryptNow(testFirmId, passphrase: 'open sesame')
        ..retireFailure = StateError('failed its cipher integrity check');
      await pumpLedgerly(tester, seed: seed, encryption: encryption);
      await type(
        tester,
        const Key('encryption.unlockPassphrase'),
        'open sesame',
      );
      await tap(tester, const Key('encryption.unlock'));

      expect(find.byKey(const Key('encryption.unverifiable')), findsOneWidget);
      expect(find.textContaining('cipher integrity check'), findsOneWidget);
      expect(find.byKey(const Key('dashboard.search')), findsNothing);
    },
  );

  testWidgets(
    'a plaintext copy that cannot be deleted does NOT block the firm — it '
    'opens, and Settings says what is still on disk',
    (tester) async {
      // The live database verified under the key; only unlinking the leftover
      // failed (antivirus, read-only volume, full disk). Refusing to open a
      // ledger that was just proved sound, for that, would be a worse bug
      // than the one it is guarding against.
      final encryption = FakeEncryptionService()
        ..encryptNow(testFirmId, passphrase: 'open sesame')
        ..retireFailure = const PlaintextCopyNotRetired(
          '/firms/firm.db.pre-encryption',
          'Operation not permitted',
        );
      await pumpLedgerly(tester, seed: seed, encryption: encryption);
      await type(
        tester,
        const Key('encryption.unlockPassphrase'),
        'open sesame',
      );
      await tap(tester, const Key('encryption.unlock'));

      expect(find.byKey(const Key('encryption.unverifiable')), findsNothing);
      expect(find.byKey(const Key('dashboard.search')), findsOneWidget);

      await pressCtrl(tester, LogicalKeyboardKey.comma);
      expect(
        find.byKey(const Key('encryption.plaintextCopyWarning')),
        findsOneWidget,
      );
      expect(find.textContaining('.pre-encryption'), findsOneWidget);
    },
    variant: windowsOnly,
  );

  testWidgets(
    'locking drops the session key and sends the app back to the unlock screen',
    (tester) async {
      final encryption = FakeEncryptionService()
        ..encryptNow(testFirmId, passphrase: 'open sesame');
      final container = await pumpLedgerly(
        tester,
        seed: seed,
        encryption: encryption,
      );
      await type(
        tester,
        const Key('encryption.unlockPassphrase'),
        'open sesame',
      );
      await tap(tester, const Key('encryption.unlock'));
      final key = container.read(firmMasterKeyProvider)!;

      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await tap(tester, const Key('encryption.lock'));

      expect(container.read(firmMasterKeyProvider), isNull);
      expect(find.byKey(const Key('encryption.unlockScreen')), findsOneWidget);
      // Not merely dropped from the provider — the bytes themselves are gone,
      // so nothing that kept a reference to them still holds a usable key.
      expect(key.every((b) => b == 0), isTrue);
    },
    variant: windowsOnly,
  );

  testWidgets(
    'changing the passphrase needs the current one, and never reuses the '
    'session key held in memory',
    (tester) async {
      final encryption = FakeEncryptionService()
        ..encryptNow(testFirmId, passphrase: 'old one');
      await pumpLedgerly(tester, seed: seed, encryption: encryption);
      await type(tester, const Key('encryption.unlockPassphrase'), 'old one');
      await tap(tester, const Key('encryption.unlock'));

      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await tap(tester, const Key('encryption.changePassphrase'));
      await type(
        tester,
        const Key('encryption.currentPassphrase'),
        'not the old one',
      );
      await type(tester, const Key('encryption.newPassphrase'), 'new one');
      await type(
        tester,
        const Key('encryption.newPassphraseConfirm'),
        'new one',
      );
      await tap(tester, const Key('encryption.changePassphraseSubmit'));

      expect(
        find.byKey(const Key('encryption.passphraseError')),
        findsOneWidget,
      );
      expect(
        await encryption.unlockWithPassphrase(testFirmId, 'old one'),
        isNotNull,
      );

      await type(tester, const Key('encryption.currentPassphrase'), 'old one');
      await tap(tester, const Key('encryption.changePassphraseSubmit'));

      expect(
        await encryption.unlockWithPassphrase(testFirmId, 'old one'),
        isNull,
      );
      expect(
        await encryption.unlockWithPassphrase(testFirmId, 'new one'),
        isNotNull,
      );
    },
    variant: windowsOnly,
  );

  testWidgets(
    'a failure inside changePassphrase is shown next to the field, not '
    'thrown into the void',
    (tester) async {
      final encryption = FakeEncryptionService()
        ..encryptNow(testFirmId, passphrase: 'old one')
        ..changePassphraseFailure = StateError('the envelope is gone');
      await pumpLedgerly(tester, seed: seed, encryption: encryption);
      await type(tester, const Key('encryption.unlockPassphrase'), 'old one');
      await tap(tester, const Key('encryption.unlock'));

      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await tap(tester, const Key('encryption.changePassphrase'));
      await type(tester, const Key('encryption.currentPassphrase'), 'old one');
      await type(tester, const Key('encryption.newPassphrase'), 'new one');
      await type(
        tester,
        const Key('encryption.newPassphraseConfirm'),
        'new one',
      );
      await tap(tester, const Key('encryption.changePassphraseSubmit'));

      expect(
        find.byKey(const Key('encryption.passphraseError')),
        findsOneWidget,
      );
      expect(find.textContaining('the envelope is gone'), findsOneWidget);
      expect(
        find.byKey(const Key('encryption.changePassphraseDialog')),
        findsOneWidget,
      );
    },
    variant: windowsOnly,
  );

  testWidgets(
    'generating a new recovery code shows the new one and retires the old',
    (tester) async {
      final encryption = FakeEncryptionService();
      final oldCode = encryption.encryptNow(testFirmId, passphrase: 'open up');
      await pumpLedgerly(tester, seed: seed, encryption: encryption);
      await type(tester, const Key('encryption.unlockPassphrase'), 'open up');
      await tap(tester, const Key('encryption.unlock'));

      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await tap(tester, const Key('encryption.rotateRecoveryCode'));
      await type(tester, const Key('encryption.currentPassphrase'), 'open up');
      await tap(tester, const Key('encryption.rotateRecoveryCodeSubmit'));

      final newCode = shownRecoveryCode(tester);
      expect(newCode, isNot(oldCode));
      expect(
        await encryption.unlockWithRecoveryCode(testFirmId, oldCode),
        isNull,
      );
      expect(
        await encryption.unlockWithRecoveryCode(testFirmId, newCode),
        isNotNull,
      );
    },
    variant: windowsOnly,
  );

  testWidgets(
    'the rotation dialog will not close until the new code has been typed '
    'back, and offers another one to anyone who cannot match it',
    (tester) async {
      final encryption = FakeEncryptionService();
      encryption.encryptNow(testFirmId, passphrase: 'open up');
      await pumpLedgerly(tester, seed: seed, encryption: encryption);
      await type(tester, const Key('encryption.unlockPassphrase'), 'open up');
      await tap(tester, const Key('encryption.unlock'));

      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await tap(tester, const Key('encryption.rotateRecoveryCode'));
      await type(tester, const Key('encryption.currentPassphrase'), 'open up');
      await tap(tester, const Key('encryption.rotateRecoveryCodeSubmit'));
      final firstCode = shownRecoveryCode(tester);

      // Advisory, not a gate on the rotation -- the old code died the moment
      // this returned. What it catches is a miscopy, here, rather than a year
      // from now when this code is the only way in.
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('encryption.rotateRecoveryCodeDone')),
            )
            .onPressed,
        isNull,
      );
      await type(
        tester,
        const Key('encryption.recoveryCodeConfirm'),
        '${firstCode.substring(0, firstCode.length - 1)}X',
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('encryption.rotateRecoveryCodeDone')),
            )
            .onPressed,
        isNull,
      );

      // The escape hatch: a rotation cannot be undone, so someone who cannot
      // reproduce the code has to be able to get a different one.
      await tap(tester, const Key('encryption.rotateRecoveryCodeAgain'));
      final secondCode = shownRecoveryCode(tester);
      expect(secondCode, isNot(firstCode));
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('encryption.recoveryCodeConfirm')),
            )
            .controller!
            .text,
        isEmpty,
        reason:
            'what was typed against the previous code proves nothing '
            'about this one',
      );
      expect(
        await encryption.unlockWithRecoveryCode(testFirmId, firstCode),
        isNull,
      );

      await type(
        tester,
        const Key('encryption.recoveryCodeConfirm'),
        secondCode,
      );
      await tap(tester, const Key('encryption.rotateRecoveryCodeDone'));
      expect(
        find.byKey(const Key('encryption.rotateRecoveryCodeDialog')),
        findsNothing,
      );
      expect(
        await encryption.unlockWithRecoveryCode(testFirmId, secondCode),
        isNotNull,
      );
    },
    variant: windowsOnly,
  );

  testWidgets(
    'the recovery code is shown with the firm it opens and the date it was '
    'issued, so a hand-copied one is not interchangeable with another '
    "firm's",
    (tester) async {
      final encryption = FakeEncryptionService();
      await pumpLedgerly(tester, seed: seed, encryption: encryption);
      await pressCtrl(tester, LogicalKeyboardKey.comma);
      await tap(tester, const Key('encryption.enableSection'));
      await type(tester, const Key('encryption.passphrase'), 'a passphrase');
      await type(
        tester,
        const Key('encryption.passphraseConfirm'),
        'a passphrase',
      );
      await tap(tester, const Key('encryption.generate'));

      final identity = tester
          .widget<SelectableText>(
            find.byKey(const Key('encryption.recoveryCodeIdentity')),
          )
          .data!;
      expect(identity, contains('Mill'));
      expect(identity, contains('${DateTime.now().year}'));
      // Nothing prints this code; the copy must not claim otherwise.
      expect(find.textContaining('print it'), findsNothing);
    },
    variant: windowsOnly,
  );

  testWidgets(
    'the first-launch encryption panel fits a phone: it scrolls, and the '
    'irreversibility warning and the code are both reachable',
    (tester) async {
      // A RenderFlex overflow fails this test on its own. What it is really
      // guarding is that the two things a user must be able to read on the
      // smallest screen -- the warning and the code they can never see again
      // -- are not the parts that get clipped off the bottom.
      final encryption = FakeEncryptionService();
      final container = await pumpLedgerly(
        tester,
        encryption: encryption,
        viewSize: const Size(400, 700),
      );
      await type(tester, const Key('setup.firmName'), 'Al-Madina Oil Mills');
      await type(tester, const Key('setup.contact'), '03001234567');
      await tap(tester, const Key('setup.enableEncryption'));
      await tester.ensureVisible(find.byKey(const Key('encryption.warning')));
      await tester.pumpAndSettle();

      await type(tester, const Key('encryption.passphrase'), 'a passphrase');
      await type(
        tester,
        const Key('encryption.passphraseConfirm'),
        'a passphrase',
      );
      await tap(tester, const Key('encryption.generate'));

      await tester.ensureVisible(
        find.byKey(const Key('encryption.recoveryCode')),
      );
      await tester.pumpAndSettle();
      await type(
        tester,
        const Key('encryption.recoveryCodeConfirm'),
        shownRecoveryCode(tester),
      );
      await tester.ensureVisible(find.byKey(const Key('encryption.warning')));
      await tap(tester, const Key('encryption.confirmEnable'));

      final firmId = container.read(globalPrefsProvider).lastFirmId;
      expect(firmId, isNotNull);
      expect(await encryption.isEncrypted(firmId!), isTrue);
    },
    variant: phoneOnly,
  );

  testWidgets(
    'a firm created at first launch can be encrypted from birth, with the key '
    'in hand before its database file is ever written',
    (tester) async {
      final encryption = FakeEncryptionService();
      final container = await pumpLedgerly(tester, encryption: encryption);
      expect(find.byKey(const Key('setup.firmName')), findsOneWidget);

      await type(tester, const Key('setup.firmName'), 'Al-Madina Oil Mills');
      await type(tester, const Key('setup.contact'), '03001234567');
      await tap(tester, const Key('setup.enableEncryption'));
      await type(tester, const Key('encryption.passphrase'), 'a passphrase');
      await type(
        tester,
        const Key('encryption.passphraseConfirm'),
        'a passphrase',
      );
      await tap(tester, const Key('encryption.generate'));
      await type(
        tester,
        const Key('encryption.recoveryCodeConfirm'),
        shownRecoveryCode(tester),
      );
      await tap(tester, const Key('encryption.confirmEnable'));

      final firmId = container.read(globalPrefsProvider).lastFirmId;
      expect(firmId, isNotNull);
      expect(await encryption.isEncrypted(firmId!), isTrue);
      expect(container.read(firmMasterKeyProvider), isNotNull);
      // A brand-new firm has no plaintext file to rewrite, so the migration
      // path is exactly what it must NOT have taken.
      expect(encryption.migrations, isEmpty);
      expect(find.text('Al-Madina Oil Mills'), findsWidgets);
    },
    variant: windowsOnly,
  );
}
