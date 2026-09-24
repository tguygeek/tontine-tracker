/// Erreurs "métier" exposées à l'UI : chaque Failure porte un message lisible.
sealed class Failure implements Exception {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure()
      : super('Pas de connexion. Vérifie ton réseau et réessaie.');
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure() : super('Session expirée. Reconnecte-toi.');
}

final class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure() : super('Email ou mot de passe incorrect.');
}

final class EmailAlreadyUsedFailure extends Failure {
  const EmailAlreadyUsedFailure()
      : super('Un compte existe déjà avec cet email.');
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Le serveur a rencontré un problème. Réessaie dans un instant.',
  ]);
}

final class CacheFailure extends Failure {
  const CacheFailure() : super('Impossible de lire les données locales.');
}

final class UnknownFailure extends Failure {
  const UnknownFailure() : super('Une erreur inattendue est survenue.');
}
