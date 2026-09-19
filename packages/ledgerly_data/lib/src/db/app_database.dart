import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// One database file per firm. The schema lives in `schema.drift` (SQL) because
/// generated columns, CHECK rules and partial indexes are clearer in SQL than in
/// Dart annotations, and the same text is the reference for the Postgres side.
///
/// Schema rules (docs/design-spec.md, Section 2): money in paisa and weight in
/// grams, both INTEGER; ids are lowercase uuid text; every syncable row carries
/// firm_id and the sync columns; balances are never stored; per-line arithmetic
/// is a generated column so the database, not application code, owns the number.
@DriftDatabase(include: {'schema.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      // SQLite ships with foreign keys OFF; every connection must turn them on
      // or cascades and parent checks silently do nothing.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
