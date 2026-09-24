import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// true = aucune connexion détectée. Sert uniquement à afficher un bandeau
/// d'information ; ce n'est jamais ce qui décide si un appel API échoue
/// (guards.dart s'en charge via la vraie réponse Dio).
final isOfflineProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) => results.every((r) => r == ConnectivityResult.none));
});
