import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Cache local des tontines : miroir simplifié de la table Supabase
/// "tontines", et source de vérité pour le mode hors-ligne.
class TontinesTable extends Table {
  @override
  String get tableName => 'tontines';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get currency => text()();
  RealColumn get contributionAmount => real()();
  TextColumn get frequency => text()();
  TextColumn get rotationMode => text()();
  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// File d'attente des écritures faites hors-ligne (pattern outbox).
/// Chaque ligne = une opération à rejouer vers Supabase au retour du réseau.
class OutboxTable extends Table {
  @override
  String get tableName => 'outbox';

  TextColumn get id => text()(); // uuid de l'opération elle-même
  TextColumn get entityTable => text()(); // ex: 'tontines', 'memberships'
  TextColumn get entityId => text()(); // id de la ligne concernée
  TextColumn get operation => text()(); // 'insert' | 'update'
  TextColumn get payload => text()(); // corps JSON à envoyer tel quel
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cache local des membres : miroir simplifié de la table Supabase
/// "memberships" (colonnes utiles à l'affichage seulement).
class MembersTable extends Table {
  @override
  String get tableName => 'memberships';

  TextColumn get id => text()();
  TextColumn get tontineId => text()();
  TextColumn get displayName => text()();
  TextColumn get role => text()();
  IntColumn get position => integer()();
  TextColumn get status => text()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cache local des tours : miroir simplifié de la table Supabase "rounds".
class RoundsTable extends Table {
  @override
  String get tableName => 'rounds';

  TextColumn get id => text()();
  TextColumn get tontineId => text()();
  IntColumn get number => integer()();
  TextColumn get beneficiaryId => text()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get status => text()(); // 'upcoming' | 'current' | 'closed'
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cache local des cotisations : miroir simplifié de la table Supabase
/// "contributions".
class ContributionsTable extends Table {
  @override
  String get tableName => 'contributions';

  TextColumn get id => text()();
  TextColumn get tontineId => text()();
  TextColumn get roundId => text()();
  TextColumn get membershipId => text()();
  RealColumn get amount => real()();
  TextColumn get method => text()(); // 'cash' | 'momo_mtn' | 'momo_orange'
  TextColumn get status => text()(); // 'pending' | 'confirmed' | 'late'
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    TontinesTable,
    OutboxTable,
    MembersTable,
    RoundsTable,
    ContributionsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Constructeur pour les tests : base en mémoire, jamais écrite sur disque.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() =>
      driftDatabase(name: 'tontine_tracker');

  // ---- Tontines -----------------------------------------------------

  Stream<List<TontinesTableData>> watchTontines() => (select(tontinesTable)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .watch();

  Future<List<TontinesTableData>> getCachedTontines() =>
      (select(tontinesTable)..where((t) => t.deletedAt.isNull())).get();

  Future<void> upsertTontines(List<TontinesTableCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(tontinesTable, rows));

  Future<void> upsertTontine(TontinesTableCompanion row) =>
      into(tontinesTable).insertOnConflictUpdate(row);

  // ---- Outbox ---------------------------------------------------------

  Future<void> enqueueOutbox(OutboxTableCompanion row) =>
      into(outboxTable).insert(row);

  /// IMPORTANT : filtré par table. Sans ce filtre, le repository "tontines"
  /// rejouerait aussi les écritures en attente pour "memberships" (et
  /// inversement), en les envoyant au mauvais endpoint.
  Future<List<OutboxTableData>> pendingOutbox(String entityTable) =>
      (select(outboxTable)
            ..where((t) => t.entityTable.equals(entityTable))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<void> deleteOutbox(String id) =>
      (delete(outboxTable)..where((t) => t.id.equals(id))).go();

  Future<void> markOutboxFailure(String id, String error) async {
    final row =
        await (select(outboxTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    await (update(outboxTable)..where((t) => t.id.equals(id))).write(
      OutboxTableCompanion(
        attempts: Value(row.attempts + 1),
        lastError: Value(error),
      ),
    );
  }

  // ---- Members ----------------------------------------------------------

  Future<List<MembersTableData>> getCachedMembers(String tontineId) =>
      (select(membersTable)
            ..where((t) => t.tontineId.equals(tontineId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();

  Future<void> upsertMembers(List<MembersTableCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(membersTable, rows));

  Future<void> upsertMember(MembersTableCompanion row) =>
      into(membersTable).insertOnConflictUpdate(row);

  // ---- Rounds -------------------------------------------------------

  Future<List<RoundsTableData>> getCachedRounds(String tontineId) =>
      (select(roundsTable)
            ..where((t) => t.tontineId.equals(tontineId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.number)]))
          .get();

  Future<void> upsertRounds(List<RoundsTableCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(roundsTable, rows));

  Future<void> upsertRound(RoundsTableCompanion row) =>
      into(roundsTable).insertOnConflictUpdate(row);

  // ---- Contributions --------------------------------------------------

  Future<List<ContributionsTableData>> getCachedContributions(String roundId) =>
      (select(contributionsTable)
            ..where((t) => t.roundId.equals(roundId) & t.deletedAt.isNull()))
          .get();

  Future<void> upsertContributions(List<ContributionsTableCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(contributionsTable, rows));

  Future<void> upsertContribution(ContributionsTableCompanion row) =>
      into(contributionsTable).insertOnConflictUpdate(row);
}
