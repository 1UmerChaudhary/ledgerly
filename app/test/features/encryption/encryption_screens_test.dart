import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/bootstrap/providers.dart';
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

      // Nothing is committed to this session until the printed code has been
      // typed back: the button is there, and tapping it does nothing.
      await tap(tester, const Key('encryption.confirmEnable'));
      expect(container.read(firmMasterKeyProvider), isNull);
      expect(find.byKey(const Key('encryption.setupWizard')), findsOneWidget);

      // A near miss is still a miss.
      await type(
        tester,
        const Key('encryption.recoveryCodeConfirm'),
        '${code.substring(0, code.length - 1)}X',
      );
      await tap(tester, const Key('encryption.confirmEnable'));
      expect(container.read(firmMasterKeyProvider), isNull);

      await type(tester, const Key('encryption.recoveryCodeConfirm'), code);
      await tap(tester, const Key('encryption.confirmEnable'));

      expect(await encryption.isEncrypted(testFirmId), isTrue);
      expect(container.read(firmMasterKeyProvider), isNotNull);
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
