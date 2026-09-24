import 'package:dio/dio.dart';

import '../../../core/errors/guards.dart';
import 'auth_models.dart';

/// Appelle l'API Auth de Supabase (GoTrue) via le Dio "nu".
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<SessionModel> signUp({
    required String email,
    required String password,
    String? fullName,
  }) =>
      guardRemote(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/v1/signup',
          data: {
            'email': email,
            'password': password,
            if (fullName != null && fullName.isNotEmpty)
              'data': {'full_name': fullName},
          },
        );
        return SessionModel.fromJson(res.data!);
      });

  Future<SessionModel> signIn({
    required String email,
    required String password,
  }) =>
      guardRemote(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/v1/token',
          queryParameters: {'grant_type': 'password'},
          data: {'email': email, 'password': password},
        );
        return SessionModel.fromJson(res.data!);
      });

  /// Meilleur effort : on n'échoue jamais (hors-ligne, token expiré...).
  /// scope=local : ne coupe que cette session, pas les autres appareils.
  Future<void> signOut(String accessToken) async {
    try {
      await _dio.post<void>(
        '/auth/v1/logout',
        queryParameters: {'scope': 'local'},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException {
      // ignoré volontairement
    }
  }
}
