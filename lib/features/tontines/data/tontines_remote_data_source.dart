import 'package:dio/dio.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/guards.dart';
import 'tontine_dto.dart';

/// Appelle l'API REST de Supabase (PostgREST) via le Dio applicatif
/// (intercepteur auth + refresh, cf. core/network/dio_client.dart).
class TontinesRemoteDataSource {
  TontinesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<TontineDto>> fetchAll() => guardRemote(() async {
        final res = await _dio.get<List<dynamic>>(
          '/rest/v1/tontines',
          queryParameters: {
            'select': '*',
            'deleted_at': 'is.null',
            'order': 'name.asc',
          },
        );
        return (res.data ?? [])
            .cast<Map<String, dynamic>>()
            .map(TontineDto.fromJson)
            .toList();
      });

  /// Prefer: return=representation => Supabase renvoie la ligne créée
  /// (avec created_at/updated_at posés par la base), qu'on relit ici.
  Future<TontineDto> create(Map<String, dynamic> body) => guardRemote(() async {
        final res = await _dio.post<List<dynamic>>(
          '/rest/v1/tontines',
          data: body,
          options: Options(headers: {'Prefer': 'return=representation'}),
        );
        final rows = res.data ?? [];
        if (rows.isEmpty) {
          throw const ServerException(message: 'Réponse vide du serveur.');
        }
        return TontineDto.fromJson(rows.first as Map<String, dynamic>);
      });
}
