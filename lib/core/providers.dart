import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network/dio_client.dart';
import 'storage/app_database.dart';
import 'storage/session_storage.dart';

/// Canal d'événements : l'intercepteur signale "session expirée",
/// le AuthController écoute et repasse l'utilisateur en déconnecté.
class SessionEvents {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get expired => _controller.stream;
  void notifyExpired() => _controller.add(null);
  void dispose() => _controller.close();
}

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SessionStorage(),
);

final bareDioProvider = Provider<Dio>((ref) => buildBareDio());

final dioProvider = Provider<Dio>((ref) {
  return buildApiDio(
    bareDio: ref.watch(bareDioProvider),
    sessionStorage: ref.watch(sessionStorageProvider),
    onSessionExpired: ref.read(sessionEventsProvider).notifyExpired,
  );
});

/// Une seule connexion Drift pour toute l'app (rouverte à chaque
/// redémarrage). ref.onDispose la ferme proprement si le scope est détruit.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
