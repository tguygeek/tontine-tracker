import 'dart:convert';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/guards.dart';
import '../domain/round.dart';
import '../domain/round_repository.dart';
import 'round_dto.dart';
import 'rounds_local_data_source.dart';
import 'rounds_remote_data_source.dart';

class RoundRepositoryImpl implements RoundRepository {
  RoundRepositoryImpl({required this._remote, required this._local});

  final RoundsRemoteDataSource _remote;
  final RoundsLocalDataSource _local;

  @override
  Future<List<Round>> getRounds(String tontineId) => guardFailure(() async {
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
  Future<void> createRounds(List<Round> rounds) async {
    for (final r in rounds) {
      final dto = RoundDto(
        id: r.id,
        tontineId: r.tontineId,
        number: r.number,
        beneficiaryId: r.beneficiaryId,
        dueDate: r.dueDate,
        status: r.status,
      );
      await _local.cacheOne(dto);
      await _local.enqueueCreate(entityId: dto.id, payload: dto.toInsertJson());
    }
    await syncOutbox();
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
