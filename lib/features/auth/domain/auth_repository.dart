import 'app_user.dart';

/// Contrat de la couche domain. Les erreurs sont des [Failure].
abstract interface class AuthRepository {
  Future<AppUser> register({
    required String email,
    required String password,
    String? fullName,
  });

  Future<AppUser> login({required String email, required String password});

  /// Toujours réussi côté local, même hors-ligne.
  Future<void> logout();

  /// Lit la session locale, sans réseau (démarrage hors-ligne possible).
  Future<AppUser?> restoreSession();
}
