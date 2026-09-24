import 'package:dio/dio.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/guards.dart';
import 'round_dto.dart';

class RoundsRemoteDataSource {
  RoundsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<RoundDto>> fetchForTontine(String tontineId) =>
      guardRemote(() async {
        final res = await _dio.get<List<dynamic>>(
          '/rest/v1/rounds',
          queryParameters: {
            'select': '*',
            'tontine_id': 'eq.$tontineId',
            'deleted_at': 'is.null',
            'order': 'number.asc',
          },
        );
        return (res.data ?? [])
            .cast<Map<String, dynamic>>()
            .map(RoundDto.fromJson)
            .toList();
      });

  Future<RoundDto> create(Map<String, dynamic> body) => guardRemote(() async {
        final res = await _dio.post<List<dynamic>>(
          '/rest/v1/rounds',
          data: body,
          options: Options(headers: {'Prefer': 'return=representation'}),
        );
        final rows = res.data ?? [];
        if (rows.isEmpty) {
          throw const ServerException(message: 'Réponse vide du serveur.');
        }
        return RoundDto.fromJson(rows.first as Map<String, dynamic>);
      });
}
