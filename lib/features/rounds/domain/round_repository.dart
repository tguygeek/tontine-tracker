import 'round.dart';

abstract interface class RoundRepository {
  /// Réseau d'abord ; repli sur le cache si le réseau est indisponible.
  Future<List<Round>> getRounds(String tontineId);

  /// Écrit chaque tour en local immédiatement (optimiste), puis synchronise.
  /// Utilisé une seule fois, au démarrage d'une tontine.
  Future<void> createRounds(List<Round> rounds);

  Future<void> syncOutbox();
}
