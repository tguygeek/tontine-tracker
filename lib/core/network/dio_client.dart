import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/session_storage.dart';
import 'auth_interceptor.dart';

BaseOptions _baseOptions() => BaseOptions(
      baseUrl: Env.supabaseUrl,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'apikey': Env.supabaseAnonKey,
        'Content-Type': 'application/json',
      },
    );

/// Dio "nu", sans intercepteur d'auth.
/// Sert à login / register / refresh et aux retries de l'intercepteur.
Dio buildBareDio() => Dio(_baseOptions());

/// Dio applicatif : injecte le Bearer et rafraîchit le token sur 401.
/// C'est celui que les repositories de données (tontines, etc.) utiliseront.
Dio buildApiDio({
  required Dio bareDio,
  required SessionStorage sessionStorage,
  void Function()? onSessionExpired,
}) {
  final dio = Dio(_baseOptions());
  dio.interceptors.add(
    AuthInterceptor(
      bareDio: bareDio,
      storage: sessionStorage,
      onSessionExpired: onSessionExpired,
    ),
  );
  return dio;
}
