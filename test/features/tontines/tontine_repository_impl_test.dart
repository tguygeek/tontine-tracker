import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tontine_tracker/core/errors/exceptions.dart';
import 'package:tontine_tracker/core/errors/failures.dart';
import 'package:tontine_tracker/core/storage/app_database.dart';
import 'package:tontine_tracker/features/tontines/data/tontine_dto.dart';
import 'package:tontine_tracker/features/tontines/data/tontine_repository_impl.dart';
import 'package:tontine_tracker/features/tontines/data/tontines_local_data_source.dart';
import 'package:tontine_tracker/features/tontines/data/tontines_remote_data_source.dart';

class MockRemote extends Mock implements TontinesRemoteDataSource {}

class MockLocal extends Mock implements TontinesLocalDataSource {}

void main() {
  late MockRemote remote;
  late MockLocal local;
  late TontineRepositoryImpl repo;

  final now = DateTime.utc(2026, 1, 1);
  final dto = TontineDto(
    id: 't1',
    name: 'Tontine Test',
    currency: 'XAF',
    contributionAmount: 10000,
    frequency: 'monthly',
    rotationMode: 'fixed',
    createdBy: 'u1',
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() {
    // Fallbacks requis par mocktail dès qu'un any() porte sur ces types.
    registerFallbackValue(<TontineDto>[]);
    registerFallbackValue(dto);
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    remote = MockRemote();
    local = MockLocal();
    repo = TontineRepositoryImpl(
      remote: remote,
      local: local,
      currentUserId: () => 'u1',
    );
  });

  group('getTontines', () {
    test('succès distant : renvoie les données et les met en cache', () async {
      when(() => remote.fetchAll()).thenAnswer((_) async => [dto]);
      when(() => local.cacheAll(any())).thenAnswer((_) async {});

      final result = await repo.getTontines();

      expect(result, [dto.toEntity()]);
      verify(() => local.cacheAll(any())).called(1);
      verifyNever(() => local.getCached());
    });

    test('échec réseau avec cache non vide : repli sur le cache, sans erreur',
        () async {
      when(() => remote.fetchAll()).thenThrow(const NetworkException());
      when(() => local.getCached()).thenAnswer((_) async => [dto.toEntity()]);

      final result = await repo.getTontines();

      expect(result, [dto.toEntity()]);
    });

    test('échec réseau avec cache vide : lève une NetworkFailure', () async {
      when(() => remote.fetchAll()).thenThrow(const NetworkException());
      when(() => local.getCached()).thenAnswer((_) async => []);

      expect(() => repo.getTontines(), throwsA(isA<NetworkFailure>()));
    });
  });

  group('syncOutbox', () {
    test('envoie chaque opération en attente et vide la file en cas de succès',
        () async {
      final pending = OutboxTableData(
        id: 'op1',
        entityTable: 'tontines',
        entityId: dto.id,
        operation: 'insert',
        payload: jsonEncode(dto.toInsertJson()),
        createdAt: now,
        attempts: 0,
        lastError: null,
      );

      when(() => local.pendingOutbox()).thenAnswer((_) async => [pending]);
      when(() => remote.create(any())).thenAnswer((_) async => dto);
      when(() => local.cacheOne(any())).thenAnswer((_) async {});
      when(() => local.removeOutbox('op1')).thenAnswer((_) async {});

      await repo.syncOutbox();

      verify(() => remote.create(any())).called(1);
      verify(() => local.cacheOne(any())).called(1);
      verify(() => local.removeOutbox('op1')).called(1);
      verifyNever(() => local.markOutboxFailure(any(), any()));
    });
  });
}
