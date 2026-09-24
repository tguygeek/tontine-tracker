// ignore_for_file: prefer_initializing_formals

import 'package:dio/dio.dart';

import '../storage/session_storage.dart';

/// Injecte le token utilisateur et gère le refresh sur 401.
///
/// Points clés :
///  * QueuedInterceptor : les erreurs sont traitées une par une, donc un seul
///    refresh à la fois même si 5 requêtes tombent en 401 ensemble.
///  * Le retry passe par [_bareDio] (sans cet intercepteur) : rejouer via le
///    même Dio ferait attendre la requête dans la file de l'erreur en cours
///    => deadlock.
///  * Refresh impossible car réseau coupé / 5xx : on NE déconnecte PAS
///    (le mode hors-ligne doit continuer à fonctionner).
///  * Refresh refusé (400/401/403) : session morte => logout.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required Dio bareDio,
    required SessionStorage storage,
    this.onSessionExpired,
  })  : _bareDio = bareDio,
        _storage = storage;

  final Dio _bareDio;
  
  final SessionStorage _storage;
  final void Function()? onSessionExpired;

  static const _retriedKey = 'auth_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final tokens = await _storage.readTokens();
    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;

    if (!isUnauthorized || options.extra[_retriedKey] == true) {
      return handler.next(err);
    }

    final stored = await _storage.readTokens();
    if (stored == null) return handler.next(err); // pas de session à rafraîchir

    try {
      var tokens = stored;
      // Si le token stocké a déjà changé, une requête précédente de la file
      // l'a rafraîchi : inutile de recommencer, on rejoue directement.
      if (options.headers['Authorization'] == 'Bearer ${stored.accessToken}') {
        tokens = await _refresh(stored.refreshToken);
      }
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      options.extra[_retriedKey] = true;
      final response = await _bareDio.fetch<dynamic>(options);
      handler.resolve(response);
    } on _SessionExpired {
      await _storage.clear();
      onSessionExpired?.call();
      handler.next(err);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<AuthTokens> _refresh(String refreshToken) async {
    try {
      final res = await _bareDio.post<Map<String, dynamic>>(
        '/auth/v1/token',
        queryParameters: {'grant_type': 'refresh_token'},
        data: {'refresh_token': refreshToken},
      );
      final data = res.data!;
      final tokens = AuthTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      await _storage.saveTokens(tokens);
      return tokens;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) {
        throw const _SessionExpired();
      }
      rethrow;
    }
  }
}

class _SessionExpired implements Exception {
  const _SessionExpired();
}