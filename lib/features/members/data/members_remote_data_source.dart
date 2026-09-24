import 'package:dio/dio.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/guards.dart';
import 'member_dto.dart';

class MembersRemoteDataSource {
  MembersRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<MemberDto>> fetchForTontine(String tontineId) =>
      guardRemote(() async {
        final res = await _dio.get<List<dynamic>>(
          '/rest/v1/memberships',
          queryParameters: {
            'select': '*',
            'tontine_id': 'eq.$tontineId',
            'deleted_at': 'is.null',
            'order': 'position.asc',
          },
        );
        return (res.data ?? [])
            .cast<Map<String, dynamic>>()
            .map(MemberDto.fromJson)
            .toList();
      });

  Future<MemberDto> create(Map<String, dynamic> body) => guardRemote(() async {
        final res = await _dio.post<List<dynamic>>(
          '/rest/v1/memberships',
          data: body,
          options: Options(headers: {'Prefer': 'return=representation'}),
        );
        final rows = res.data ?? [];
        if (rows.isEmpty) {
          throw const ServerException(message: 'Réponse vide du serveur.');
        }
        return MemberDto.fromJson(rows.first as Map<String, dynamic>);
      });
}
