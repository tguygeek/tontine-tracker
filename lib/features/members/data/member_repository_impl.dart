import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/guards.dart';
import '../domain/member.dart';
import '../domain/member_repository.dart';
import 'member_dto.dart';
import 'members_local_data_source.dart';
import 'members_remote_data_source.dart';

/// Même stratégie que TontineRepositoryImpl : réseau d'abord, repli cache ;
/// écriture optimiste + outbox pour la création.
class MemberRepositoryImpl implements MemberRepository {
  MemberRepositoryImpl({required this._remote, required this._local});

  final MembersRemoteDataSource _remote;
  final MembersLocalDataSource _local;

  @override
  Future<List<Member>> getMembers(String tontineId) => guardFailure(() async {
    try {
      final remoteData = await _remote.fetchForTontine(tontineId);
      await _local.cacheAll(remoteData);
      return remoteData.map((d) => d.toEntity()).toList();
    } on NetworkException {
      final cached = await _local.getCached(tontineId);
      if (cached.isEmpty) throw const NetworkFailure();
      return cached;
    }
  });

  @override
  Future<Member> addMember({
    required String tontineId,
    required String displayName,
    required int position,
    String role = 'member',
  }) async {
    final dto = MemberDto(
      id: const Uuid().v4(),
      tontineId: tontineId,
      displayName: displayName,
      role: role,
      position: position,
      status: 'active',
    );

    await _local.cacheOne(dto);
    await _local.enqueueCreate(entityId: dto.id, payload: dto.toInsertJson());
    await syncOutbox();

    return dto.toEntity();
  }

  @override
  Future<void> syncOutbox() async {
    final pending = await _local.pendingOutbox();
    for (final item in pending) {
      try {
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;
        switch (item.operation) {
          case 'insert':
            final created = await _remote.create(payload);
            await _local.cacheOne(created);
          default:
            break;
        }
        await _local.removeOutbox(item.id);
      } on NetworkException {
        continue;
      } on AppException catch (e) {
        await _local.markOutboxFailure(item.id, e.message ?? e.toString());
      }
    }
  }
}
