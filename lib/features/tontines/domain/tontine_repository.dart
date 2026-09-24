import 'tontine.dart';

/// Contrat de la couche domain. Les erreurs levées sont des [Failure]
/// (core/errors/failures.dart), jamais des exceptions techniques.
abstract interface class TontineRepository {
  /// Réseau d'abord ; si indisponible, repli sur le cache local.
  /// Ne lève une Failure que si le réseau échoue ET que le cache est vide.
  Future<List<Tontine>> getTontines();

  /// Écrit en local immédiatement (optimiste), puis tente une synchro.
  /// Ne lève jamais : la tontine créée reste visible même hors-ligne.
  Future<Tontine> createTontine({
    required String name,
    required double contributionAmount,
    required String frequency,
    String currency,
    String rotationMode,
  });

  /// Rejoue les écritures en attente (pattern outbox).
  /// À appeler au retour du réseau ou après chaque création.
  Future<void> syncOutbox();
}
