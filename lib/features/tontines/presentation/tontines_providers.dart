import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/tontine_repository_impl.dart';
import '../data/tontines_local_data_source.dart';
import '../data/tontines_remote_data_source.dart';
import '../domain/tontine.dart';
import '../domain/tontine_repository.dart';

final tontineRepositoryProvider = Provider<TontineRepository>((ref) {
  return TontineRepositoryImpl(
    remote: TontinesRemoteDataSource(ref.watch(dioProvider)),
    local: TontinesLocalDataSource(ref.watch(appDatabaseProvider)),
    currentUserId: () => ref.read(authControllerProvider).value?.id ?? '',
  );
});

/// Liste des tontines. build() charge (réseau puis repli cache),
/// refresh() relance ce chargement, create() ajoute puis relit la liste.
class TontinesController extends AsyncNotifier<List<Tontine>> {
  TontineRepository get _repo => ref.read(tontineRepositoryProvider);

  @override
  Future<List<Tontine>> build() => _repo.getTontines();

  Future<void> refresh() async {
    state = const AsyncLoading<List<Tontine>>();
    state = await AsyncValue.guard(() => _repo.getTontines());
  }

  Future<void> create({
    required String name,
    required double contributionAmount,
    required String frequency,
  }) async {
    await _repo.createTontine(
      name: name,
      contributionAmount: contributionAmount,
      frequency: frequency,
    );
    await refresh();
  }

  Future<void> syncOutbox() async {
    await _repo.syncOutbox();
    await refresh();
  }
}

final tontinesControllerProvider =
    AsyncNotifierProvider<TontinesController, List<Tontine>>(
      TontinesController.new,
    );
