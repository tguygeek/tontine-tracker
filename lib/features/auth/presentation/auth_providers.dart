import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/auth_remote_data_source.dart';
import '../data/auth_repository_impl.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: AuthRemoteDataSource(ref.watch(bareDioProvider)),
    storage: ref.watch(sessionStorageProvider),
  );
});

/// État : AsyncData(user) = connecté, AsyncData(null) = déconnecté.
class AuthController extends AsyncNotifier<AppUser?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AppUser?> build() async {
    // L'intercepteur signale une session morte -> on repasse en déconnecté.
    final sub = ref.read(sessionEventsProvider).expired.listen((_) {
      state = const AsyncData(null);
    });
    ref.onDispose(sub.cancel);

    return _repo.restoreSession();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<AppUser?>(
      () => _repo.login(email: email, password: password),
    );
  }

  Future<void> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<AppUser?>(
      () => _repo.register(email: email, password: password, fullName: fullName),
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);
