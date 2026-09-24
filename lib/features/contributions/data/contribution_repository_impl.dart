import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/guards.dart';
import '../domain/contribution.dart';
import '../domain/contribution_repository.dart';
import 'contribution_dto.dart';
import 'contributions_local_data_source.dart';
import 'contributions_remote_data_source.dart';

/// Même stratégie que les repositories tontines/membres/tours :
/// réseau d'abord + repli cache en lecture, optimiste + outbox en écriture.
/// C'est ici que ça compte le plus : recorder() est appelé en pleine
/// réunion de tontine, potentiellement sans réseau.
class ContributionRepositoryImpl implements ContributionRepository {
  ContributionRepositoryImpl({required this._remote, required this._local});

  final ContributionsRemoteDataSource _remote;
  final ContributionsLocalDataSource _local;

  @override
  Future<List<Contribution>> getForRound(String roundId) =>
      guardFailure(() async {
        try {
          final remoteData = await _remote.fetchForRound(roundId);
          await _local.cacheAll(remoteData);
          return remoteData.map((d) => d.toEntity()).toList();
        } on NetworkException {
          final cached = await _local.getCached(roundId);
          if (cached.isEmpty) throw const NetworkFailure();
          return cached;
        }
      });

  @override
  Future<Contribution> record({
    required String tontineId,
    required String roundId,
    required String membershipId,
    required double amount,
    String method = 'cash',
  }) async {
    final dto = ContributionDto(
      id: const Uuid().v4(),
      tontineId: tontineId,
      roundId: roundId,
      membershipId: membershipId,
      amount: amount,
      method: method,
      status: 'pending',
    );

    // Écriture optimiste : le trésorier voit la cotisation cochée tout de
    // suite, même sans réseau en pleine réunion.
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
