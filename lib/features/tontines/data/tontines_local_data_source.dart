import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/tontine.dart';
import 'tontine_dto.dart';

/// Isole l'accès à Drift : le repository ne connaît pas le SQL, et cette
/// classe peut être mockée dans les tests (pas besoin d'une vraie DB).
class TontinesLocalDataSource {
  TontinesLocalDataSource(this._db);

  final AppDatabase _db;

  Future<List<Tontine>> getCached() async {
    final rows = await _db.getCachedTontines();
    return rows.map((r) => r.toEntity()).toList();
  }

  Future<void> cacheAll(List<TontineDto> tontines) =>
      _db.upsertTontines(tontines.map((t) => t.toCompanion()).toList());

  Future<void> cacheOne(TontineDto tontine) => _db.upsertTontine(tontine.toCompanion());

  Future<void> enqueueCreate({
    required String entityId,
    required Map<String, dynamic> payload,
  }) =>
      _db.enqueueOutbox(OutboxTableCompanion.insert(
        id: const Uuid().v4(),
        entityTable: 'tontines',
        entityId: entityId,
        operation: 'insert',
        payload: jsonEncode(payload),
        createdAt: DateTime.now(),
      ));

  Future<List<OutboxTableData>> pendingOutbox() => _db.pendingOutbox('tontines');

  Future<void> removeOutbox(String id) => _db.deleteOutbox(id);

  Future<void> markOutboxFailure(String id, String error) =>
      _db.markOutboxFailure(id, error);
}
