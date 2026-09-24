import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/member.dart';
import 'member_dto.dart';

class MembersLocalDataSource {
  MembersLocalDataSource(this._db);

  final AppDatabase _db;

  Future<List<Member>> getCached(String tontineId) async {
    final rows = await _db.getCachedMembers(tontineId);
    return rows.map((r) => r.toEntity()).toList();
  }

  Future<void> cacheAll(List<MemberDto> members) =>
      _db.upsertMembers(members.map((m) => m.toCompanion()).toList());

  Future<void> cacheOne(MemberDto member) => _db.upsertMember(member.toCompanion());

  Future<void> enqueueCreate({
    required String entityId,
    required Map<String, dynamic> payload,
  }) =>
      _db.enqueueOutbox(OutboxTableCompanion.insert(
        id: const Uuid().v4(),
        entityTable: 'memberships',
        entityId: entityId,
        operation: 'insert',
        payload: jsonEncode(payload),
        createdAt: DateTime.now(),
      ));

  Future<List<OutboxTableData>> pendingOutbox() => _db.pendingOutbox('memberships');

  Future<void> removeOutbox(String id) => _db.deleteOutbox(id);

  Future<void> markOutboxFailure(String id, String error) =>
      _db.markOutboxFailure(id, error);
}
