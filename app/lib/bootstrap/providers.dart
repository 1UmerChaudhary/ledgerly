import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../features/encryption/encryption_service.dart';
import 'app_paths.dart';
import 'global_prefs.dart';

/// Riverpod providers are the app's dependency injection, the same idea as
/// FastAPI's Depends(): a screen asks for what it needs and never builds it.
/// Tests override the leaves (prefs, database opener) and the whole app runs.

final globalPrefsProvider = Provider<GlobalPrefs>(
  (ref) =>
      throw UnimplementedError('globalPrefsProvider is overridden in main()'),
);

final appPathsProvider = Provider<AppPaths>(
  (ref) => throw UnimplementedError('appPathsProvider is overridden in main()'),
);

/// The current session's master key, held in memory only and never persisted:
/// set at unlock time, read by the database opener and by backups.
final firmMasterKeyProvider = StateProvider<Uint8List?>((ref) => null);

typedef DatabaseOpener = Future<AppDatabase> Function(String firmId);

/// `PRAGMA key` must run before drift touches anything else. No key set for
/// this session means an unencrypted firm, which opens exactly as before.
///
/// Built here, at the top level, and never inline in the provider below:
/// createInBackground sends this closure to another isolate, and a closure
/// written inside the provider captures that scope's `ref` along with the key.
/// Riverpod's Ref is unsendable, so Isolate.spawn throws before the database
/// ever opens. Capturing nothing but the hex string keeps it sendable.
DatabaseSetup? _keyedSetup(Uint8List? masterKey) {
  if (masterKey == null) return null;
  final hex = masterKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return (rawDb) => rawDb.execute('PRAGMA key = "x\'$hex\'";');
}

final databaseOpenerProvider = Provider<DatabaseOpener>((ref) {
  final paths = ref.watch(appPathsProvider);
  return (firmId) async => AppDatabase(
    NativeDatabase.createInBackground(
      paths.firmDatabase(firmId),
      setup: _keyedSetup(ref.read(firmMasterKeyProvider)),
    ),
  );
});

/// Everything a screen needs once a firm's database is open.
class OpenFirm {
  OpenFirm({
    required this.db,
    required this.ctx,
    required this.firmName,
    required this.contactNumber,
  });

  final AppDatabase db;
  final DeviceContext ctx;
  final String firmName;
  final String contactNumber;

  late final customers = CustomersRepository(db, ctx);
  late final items = ItemsRepository(db, ctx);
  late final bills = BillsRepository(db, ctx);
}

final encryptionServiceProvider = Provider<EncryptionService>(
  (ref) => EncryptionService(paths: ref.watch(appPathsProvider)),
);

/// Whether this device's firm can be opened right now, and if not, why not.
/// Everything that decides where the app starts reads this — the router, and
/// [openFirmProvider] itself, which must not so much as open a connection to
/// an encrypted file with no key in hand.
enum FirmGate {
  /// No firm on this device yet: first launch.
  noFirm,

  /// Encrypted, and this session has no master key: the unlock screen.
  locked,

  /// A migration was interrupted and its database could not be classified as
  /// either plaintext or ciphertext. Opening it would surface as an opaque
  /// SQLite failure minutes later; say so plainly instead.
  unverifiable,

  /// Plaintext, or encrypted and already unlocked.
  ready,
}

/// [FirmGate] plus, when there is one, what went wrong on the way to it — so
/// the screen that reports it can say more than "something".
class FirmGateStatus {
  const FirmGateStatus(this.gate, {this.failure, this.warning});
  final FirmGate gate;

  /// Why the firm is [FirmGate.unverifiable] and was not opened.
  final Object? failure;

  /// Something the user should know about a firm that DID open — today, only
  /// that a plaintext copy of the ledger is still sitting on disk.
  final Object? warning;
}

/// Answering [FirmGate] is also the one place every firm-open passes through,
/// whatever route it came by — a fresh unlock, a relaunch, a passphrase
/// change, a migration — which is what makes it the right home for the two
/// repairs Task 6 could not perform for itself:
///
/// * [EncryptionService.recoverInterruptedMigration] runs on every open, not
///   only inside a migration that is already under way. A firm that crashed
///   mid-migration and is never migrated again would otherwise stay stranded.
/// * [EncryptionService.retirePreEncryptionCopy] runs on every open that has
///   a key, not just the one right after a migration. A crash between the
///   database swap and the envelope promotion leaves a complete PLAINTEXT
///   copy of the ledger on disk, and keyless recovery deliberately cannot
///   remove it; this is the first (and every subsequent) moment the app holds
///   the key that can. It no-ops when there is nothing to retire.
///
/// Every failure in here is caught and returned as
/// [FirmGate.unverifiable] rather than left to fail the provider: this is the
/// one thing the router reads before it can route anywhere at all, and an
/// error state there surfaces as an unexplained exception from inside
/// go_router's redirect instead of a screen that says what is wrong. Catching
/// it also makes the choice explicit, and the choice is not the same for the
/// two ways retiring a plaintext copy can fail:
///
/// * The live database would not VERIFY under this key — the firm is not
///   opened. Something is wrong with the database itself, and a complete
///   unprotected copy of the ledger is sitting beside it; opening anyway
///   would leave both of those in place and say nothing.
/// * The database verified and only the DELETE failed
///   ([PlaintextCopyNotRetired]) — an antivirus holding the file, a read-only
///   volume, a full disk. The firm opens, with a warning in Settings naming
///   the file still on disk. Refusing here would brick a ledger that is
///   provably sound for a reason that has nothing to do with it, and the next
///   open retries the delete anyway.
final firmGateProvider = FutureProvider<FirmGateStatus>((ref) async {
  final firmId = ref.watch(globalPrefsProvider).lastFirmId;
  if (firmId == null) return const FirmGateStatus(FirmGate.noFirm);
  final encryption = ref.watch(encryptionServiceProvider);
  final masterKey = ref.watch(firmMasterKeyProvider);
  try {
    if (await encryption.recoverInterruptedMigration(firmId) ==
        RecoveryOutcome.indeterminate) {
      return const FirmGateStatus(FirmGate.unverifiable);
    }
    if (masterKey == null) {
      return await encryption.isEncrypted(firmId)
          ? const FirmGateStatus(FirmGate.locked)
          : const FirmGateStatus(FirmGate.ready);
    }
    await encryption.retirePreEncryptionCopy(firmId, masterKey);
  } on PlaintextCopyNotRetired catch (e) {
    // The live database verified under this key -- that check is what runs
    // BEFORE the delete -- and only removing the leftover plaintext copy
    // failed: a file an antivirus has open, a read-only volume, a full disk.
    // Refusing to open the firm over that would brick a healthy ledger for a
    // reason that has nothing to do with it, and the next open retries the
    // delete anyway. Open, and say what is still on disk.
    return FirmGateStatus(FirmGate.ready, warning: e);
  } on Object catch (e) {
    return FirmGateStatus(FirmGate.unverifiable, failure: e);
  }
  return const FirmGateStatus(FirmGate.ready);
});

/// Whether the open firm is encrypted, for the Settings section that offers
/// to turn it on or to change either secret. Recomputed whenever the gate is
/// — which covers enabling it, unlocking, and locking again.
final firmEncryptedProvider = FutureProvider<bool>((ref) async {
  final firmId = ref.watch(globalPrefsProvider).lastFirmId;
  if (firmId == null) return false;
  await ref.watch(firmGateProvider.future);
  return ref.watch(encryptionServiceProvider).isEncrypted(firmId);
});

/// Set after a recovery-code unlock: the forgotten passphrase is presumed
/// compromised, so a replacement is required before the rest of the app is
/// reachable. The router enforces it; only the new-passphrase screen clears
/// it.
final passphraseResetRequiredProvider = StateProvider<bool>((ref) => false);

/// Ends the unlocked session: the key is zeroed in place before it is
/// dropped, so a copy someone else still holds a reference to is no longer a
/// usable key either, and the firm falls back through [FirmGate.locked] to
/// the unlock screen.
void lockFirm(WidgetRef ref) {
  final key = ref.read(firmMasterKeyProvider);
  if (key != null) key.fillRange(0, key.length, 0);
  ref.read(firmMasterKeyProvider.notifier).state = null;
}

/// Null means no firm exists on this device yet → first-launch setup, or a
/// firm that must not be opened yet (locked, or unverifiable). The router
/// reads [firmGateProvider] first and so tells those three apart; nothing
/// else needs to.
final openFirmProvider = FutureProvider<OpenFirm?>((ref) async {
  if ((await ref.watch(firmGateProvider.future)).gate != FirmGate.ready) {
    return null;
  }
  final prefs = ref.watch(globalPrefsProvider);
  final firmId = prefs.lastFirmId;
  if (firmId == null) return null;
  final db = await ref.watch(databaseOpenerProvider)(firmId);
  ref.onDispose(db.close);
  return _openFirm(db, firmId: firmId, deviceId: prefs.deviceId);
});

Future<OpenFirm> _openFirm(
  AppDatabase db, {
  required String firmId,
  required String deviceId,
}) async {
  final firm = await (db.select(
    db.firms,
  )..where((f) => f.id.equals(firmId))).getSingle();
  final owner =
      await (db.select(db.firmMembers)..where(
            (m) =>
                m.firmId.equals(firmId) &
                m.role.equals('owner') &
                m.deletedAt.isNull(),
          ))
          .getSingle();
  final device = await (db.select(
    db.devices,
  )..where((d) => d.id.equals(deviceId))).getSingleOrNull();
  // Seed the clock from the newest stamp in the database so a restored or
  // restarted machine never issues a stamp below one it already stores.
  final newest = await db
      .customSelect(
        'SELECT MAX(updated_at) AS m FROM (SELECT updated_at FROM transactions UNION ALL SELECT updated_at FROM customers UNION ALL SELECT updated_at FROM items)',
      )
      .getSingle();
  final ctx = DeviceContext(
    firmId: firmId,
    deviceId: deviceId,
    deviceShortCode: device?.shortCode ?? deviceShortCode(deviceId),
    userId: owner.userId,
    hlc: Hlc(
      clock: () => DateTime.now().millisecondsSinceEpoch,
      seed: (newest.data['m'] as int?) ?? 0,
    ),
  );
  return OpenFirm(
    db: db,
    ctx: ctx,
    firmName: firm.name,
    contactNumber: firm.contactNumber,
  );
}

/// First launch: create the firm's database and make it the open firm.
final firmCreatorProvider = Provider<FirmCreator>(FirmCreator.new);

class FirmCreator {
  FirmCreator(this._ref);
  final Ref _ref;

  Future<void> create({
    required String name,
    required String contactNumber,
    String? address,
    String? firmId,
  }) => createFirstFirm(
    _ref,
    name: name,
    contactNumber: contactNumber,
    address: address,
    firmId: firmId,
  );
}

/// [firmId] is normally minted here. The first-launch encryption path is the
/// exception: it has to write the firm's key envelope and put the master key
/// in this session BEFORE the database file is created, so that the very
/// first byte written to it is already ciphertext. That means knowing the id
/// first, so it passes the one it enrolled.
Future<void> createFirstFirm(
  Ref ref, {
  required String name,
  required String contactNumber,
  String? address,
  String? firmId,
}) async {
  final prefs = ref.read(globalPrefsProvider);
  firmId ??= newId();
  final db = await ref.read(databaseOpenerProvider)(firmId);
  final ctx = DeviceContext(
    firmId: firmId,
    deviceId: prefs.deviceId,
    deviceShortCode: deviceShortCode(prefs.deviceId),
    userId: newId(),
    hlc: Hlc(clock: () => DateTime.now().millisecondsSinceEpoch),
  );
  await FirmSetup(
    db,
    ctx,
  ).createFirm(name: name, contactNumber: contactNumber, address: address);
  await prefs.setLastFirmId(firmId);
  // lastFirmId is plain mutable state, not a provider, so nothing recomputes
  // off it by itself. The gate is upstream of openFirmProvider, so it goes
  // first.
  ref.invalidate(firmGateProvider);
  ref.invalidate(openFirmProvider);
}
