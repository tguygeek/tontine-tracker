import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/contribution.dart';
import 'contribution_dto.dart';

class ContributionsLocalDataSource {
  ContributionsLocalDataSource(this._db);

  final AppDatabase _db;

  Future<List<Contribution>> getCached(String roundId) async {
    final rows = await _db.getCachedContributions(roundId);
    return rows.map((r) => r.toEntity()).toList();
  }

  Future<void> cacheAll(List<ContributionDto> contributions) => _db
      .upsertContributions(contributions.map((c) => c.toCompanion()).toList());

  Future<void> cacheOne(ContributionDto contribution) =>
      _db.upsertContribution(contribution.toCompanion());

  Future<void> enqueueCreate({
    required String entityId,
    required Map<String, dynamic> payload,
  }) =>
      _db.enqueueOutbox(OutboxTableCompanion.insert(
        id: const Uuid().v4(),
        entityTable: 'contributions',
        entityId: entityId,
        operation: 'insert',
        payload: jsonEncode(payload),
        createdAt: DateTime.now(),
      ));

  Future<List<OutboxTableData>> pendingOutbox() =>
      _db.pendingOutbox('contributions');

  Future<void> removeOutbox(String id) => _db.deleteOutbox(id);

  Future<void> markOutboxFailure(String id, String error) =>
      _db.markOutboxFailure(id, error);
}
