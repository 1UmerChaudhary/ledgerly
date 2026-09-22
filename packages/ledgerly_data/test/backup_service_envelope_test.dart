import 'dart:io';

import 'package:drift/native.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:test/test.dart';

/// The backup artifact for an ENCRYPTED firm is the `.db` file **and** its
/// `.key.json` envelope sidecar together, never the database alone. Both
/// wrapped copies of the master key live only in that sidecar: lose it to a
/// disk failure, a reinstall or a new machine and the backup cannot be
/// decrypted again by anyone, with the right passphrase AND the right printed
/// recovery code in hand. Everything in this file is about the pair
/// travelling together.
void main() {
  late Directory tmp;
  late DeviceContext ctx;

  final key = List.generate(32, (i) => i);
  String keyHex(List<int> k) =>
      k.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('backup_envelope_test');
    ctx = DeviceContext(
      firmId: '11111111-1111-4111-8111-111111111111',
      deviceId: '22222222-2222-4222-8222-222222222222',
      deviceShortCode: 'A3F9',
      userId: '33333333-3333-4333-8333-333333333333',
      hlc: Hlc(clock: () => 1000),
    );
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  File dbFile() => File(p.join(tmp.path, 'firms', 'firm.db'));
  File envelopeFile() => File(p.join(tmp.path, 'firms', 'firm.key.json'));
  Directory localBackups() => Directory(p.join(tmp.path, 'backups'));
  Directory userBackups() => Directory(p.join(tmp.path, 'usb'));

  Future<AppDatabase> keyedFirm() async {
    final file = dbFile();
    await file.parent.create(recursive: true);
    final seed = raw.sqlite3.open(file.path)
      ..execute('PRAGMA key = "x\'${keyHex(key)}\'";');
    final db = AppDatabase(NativeDatabase.opened(seed));
    await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
    await CustomersRepository(db, ctx).create(name: 'Rashid Traders');
    return db;
  }

  /// A real envelope's shape, without paying Argon2id twice per test: nothing
  /// in BackupService parses this file, it only ever has to travel with the
  /// database and arrive byte-identical.
  Future<void> writeEnvelope(File path, {required int marker}) async {
    WrappedKey wrapped(int seed) => WrappedKey(
      nonce: List.generate(12, (i) => (seed + i) % 256),
      cipherText: List.generate(48, (i) => (seed * 3 + i) % 256),
      mac: List.generate(16, (i) => (seed * 7 + i) % 256),
    );
    await KeyEnvelopeStore(path).write(
      KeyEnvelope(
        byPassphrase: wrapped(marker),
        passphraseSalt: List.generate(16, (i) => (marker + i) % 256),
        byRecoveryCode: wrapped(marker + 1),
        recoveryCodeSalt: List.generate(16, (i) => (marker * 2 + i) % 256),
      ),
    );
  }

  test('backing up an encrypted firm writes the envelope sidecar beside the '
      'database backup, in both the local and the user folder', () async {
    final db = await keyedFirm();
    await writeEnvelope(envelopeFile(), marker: 5);
    final service = BackupService(
      db: db,
      databaseFile: dbFile(),
      keyEnvelopeFile: envelopeFile(),
      localBackupDir: localBackups(),
      userBackupDir: userBackups(),
      masterKey: key,
    );

    final result = await service.backupNow();
    await db.close();

    final localEnvelope = BackupService.envelopeSidecarFor(result.localFile);
    expect(
      localEnvelope.existsSync(),
      isTrue,
      reason: 'without this the backup can never be decrypted again',
    );
    expect(localEnvelope.readAsStringSync(), envelopeFile().readAsStringSync());

    final userEnvelope = BackupService.envelopeSidecarFor(result.userCopy!);
    expect(userEnvelope.existsSync(), isTrue);
    expect(userEnvelope.readAsStringSync(), envelopeFile().readAsStringSync());
  });

  test(
    'an unencrypted firm gets no sidecar and is otherwise untouched',
    () async {
      final file = dbFile();
      await file.parent.create(recursive: true);
      final db = AppDatabase(NativeDatabase(file));
      await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
      final service = BackupService(
        db: db,
        databaseFile: file,
        keyEnvelopeFile: envelopeFile(),
        localBackupDir: localBackups(),
      );

      final result = await service.backupNow();
      await db.close();

      expect(
        BackupService.envelopeSidecarFor(result.localFile).existsSync(),
        isFalse,
      );
    },
  );

  test('the pre-restore safety copy carries the live envelope too', () async {
    final db = await keyedFirm();
    await writeEnvelope(envelopeFile(), marker: 5);
    final service = BackupService(
      db: db,
      databaseFile: dbFile(),
      keyEnvelopeFile: envelopeFile(),
      localBackupDir: localBackups(),
      masterKey: key,
    );
    final backup = (await service.backupNow()).localFile;
    await db.close();

    // A backup taken under a DIFFERENT key, with its own envelope beside it --
    // the cross-device / post-rotation case.
    final foreign = File(p.join(tmp.path, 'foreign.db'));
    backup.copySync(foreign.path);
    await writeEnvelope(BackupService.envelopeSidecarFor(foreign), marker: 9);

    final liveEnvelopeBefore = envelopeFile().readAsStringSync();
    final preRestore = await service.restoreFrom(foreign);

    // The safety copy is the whole pair, or "undo the restore" is a lie for
    // an encrypted firm.
    expect(
      BackupService.envelopeSidecarFor(preRestore).readAsStringSync(),
      liveEnvelopeBefore,
    );
    // ...and the restored backup's own envelope became the firm's, or the
    // firm is now a database nothing on disk holds a key for.
    expect(
      envelopeFile().readAsStringSync(),
      BackupService.envelopeSidecarFor(foreign).readAsStringSync(),
    );
  });

  test('pruning an old backup takes its envelope with it', () async {
    final db = await keyedFirm();
    await writeEnvelope(envelopeFile(), marker: 5);
    var tick = DateTime.utc(2026, 1, 1, 9);
    final service = BackupService(
      db: db,
      databaseFile: dbFile(),
      keyEnvelopeFile: envelopeFile(),
      localBackupDir: localBackups(),
      masterKey: key,
      keep: 1,
      now: () => tick,
    );

    final first = (await service.backupNow()).localFile;
    tick = tick.add(const Duration(hours: 1));
    await service.backupNow();
    await db.close();

    expect(first.existsSync(), isFalse);
    expect(
      BackupService.envelopeSidecarFor(first).existsSync(),
      isFalse,
      reason:
          'an orphan envelope outliving its backup is key material with '
          'nothing left to protect',
    );
  });
}
