import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/round_repository_impl.dart';
import '../data/rounds_local_data_source.dart';
import '../data/rounds_remote_data_source.dart';
import '../domain/round.dart';
import '../domain/round_repository.dart';

final roundRepositoryProvider = Provider<RoundRepository>((ref) {
  return RoundRepositoryImpl(
    remote: RoundsRemoteDataSource(ref.watch(dioProvider)),
    local: RoundsLocalDataSource(ref.watch(appDatabaseProvider)),
  );
});

final roundsProvider =
    FutureProvider.family<List<Round>, String>((ref, tontineId) {
  return ref.watch(roundRepositoryProvider).getRounds(tontineId);
});
