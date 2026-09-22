import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

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

/// Null means no firm exists on this device yet → first-launch setup.
final openFirmProvider = FutureProvider<OpenFirm?>((ref) async {
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
  }) => createFirstFirm(
    _ref,
    name: name,
    contactNumber: contactNumber,
    address: address,
  );
}

Future<void> createFirstFirm(
  Ref ref, {
  required String name,
  required String contactNumber,
  String? address,
}) async {
  final prefs = ref.read(globalPrefsProvider);
  final firmId = newId();
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
  ref.invalidate(openFirmProvider);
}
