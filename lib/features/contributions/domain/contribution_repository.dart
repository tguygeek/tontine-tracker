import 'contribution.dart';

abstract interface class ContributionRepository {
  /// Réseau d'abord ; repli sur le cache si le réseau est indisponible.
  Future<List<Contribution>> getForRound(String roundId);

  /// Écrit en local immédiatement (optimiste) : c'est LE cas d'usage
  /// hors-ligne central (saisie en réunion, sans réseau).
  Future<Contribution> record({
    required String tontineId,
    required String roundId,
    required String membershipId,
    required double amount,
    String method,
  });

  Future<void> syncOutbox();
}
