import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/guards.dart';
import '../domain/tontine.dart';
import '../domain/tontine_repository.dart';
import 'tontine_dto.dart';
import 'tontines_local_data_source.dart';
import 'tontines_remote_data_source.dart';

class TontineRepositoryImpl implements TontineRepository {
  TontineRepositoryImpl({
    required this._remote,
    required this._local,
    required this._currentUserId,
  });

  final TontinesRemoteDataSource _remote;
  final TontinesLocalDataSource _local;
  final String Function() _currentUserId;

  @override
  Future<List<Tontine>> getTontines() => guardFailure(() async {
        try {
          final remoteData = await _remote.fetchAll();
          await _local.cacheAll(remoteData);
          return remoteData.map((d) => d.toEntity()).toList();
        } on NetworkException {
          // Hors-ligne : repli sur le cache. On ne lève une Failure que si
          // le cache est lui aussi vide (rien à montrer à l'utilisateur).
          final cached = await _local.getCached();
          if (cached.isEmpty) throw const NetworkFailure();
          return cached;
        }
      });

  @override
  Future<Tontine> createTontine({
    required String name,
    required double contributionAmount,
    required String frequency,
    String currency = 'XAF',
    String rotationMode = 'fixed',
  }) async {
    final now = DateTime.now().toUtc();
    final dto = TontineDto(
      id: const Uuid().v4(),
      name: name,
      currency: currency,
      contributionAmount: contributionAmount,
      frequency: frequency,
      rotationMode: rotationMode,
      createdBy: _currentUserId(),
      createdAt: now,
      updatedAt: now,
    );

    // Écriture optimiste : visible immédiatement, même hors-ligne.
    await _local.cacheOne(dto);
    await _local.enqueueCreate(entityId: dto.id, payload: dto.toInsertJson());

    // Tentative de synchro immédiate ; en cas d'échec l'outbox reste en
    // attente et sera rejouée par syncOutbox() (ex: au retour du réseau).
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
            await _local.cacheOne(created); // remplace la version optimiste
          default:
            // v1 : seul 'insert' est géré. Une opération inconnue est
            // retirée pour ne pas bloquer la file indéfiniment.
            break;
        }
        await _local.removeOutbox(item.id);
      } on NetworkException {
        // Toujours pas de réseau : on la laisse en file, on tente la suivante.
        continue;
      } on AppException catch (e) {
        // Erreur serveur définitive (ex: validation) : marquée pour
        // diagnostic, mais on continue avec le reste de la file.
        await _local.markOutboxFailure(item.id, e.message ?? e.toString());
      }
    }
  }
}
