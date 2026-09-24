import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/round.dart';
import 'round_dto.dart';

class RoundsLocalDataSource {
  RoundsLocalDataSource(this._db);

  final AppDatabase _db;

  Future<List<Round>> getCached(String tontineId) async {
    final rows = await _db.getCachedRounds(tontineId);
    return rows.map((r) => r.toEntity()).toList();
  }

  Future<void> cacheAll(List<RoundDto> rounds) =>
      _db.upsertRounds(rounds.map((r) => r.toCompanion()).toList());

  Future<void> cacheOne(RoundDto round) => _db.upsertRound(round.toCompanion());

  Future<void> enqueueCreate({
    required String entityId,
    required Map<String, dynamic> payload,
  }) =>
      _db.enqueueOutbox(OutboxTableCompanion.insert(
        id: const Uuid().v4(),
        entityTable: 'rounds',
        entityId: entityId,
        operation: 'insert',
        payload: jsonEncode(payload),
        createdAt: DateTime.now(),
      ));

  Future<List<OutboxTableData>> pendingOutbox() => _db.pendingOutbox('rounds');

  Future<void> removeOutbox(String id) => _db.deleteOutbox(id);

  Future<void> markOutboxFailure(String id, String error) =>
      _db.markOutboxFailure(id, error);
}
