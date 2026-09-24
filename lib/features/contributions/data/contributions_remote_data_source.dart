import 'package:dio/dio.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/guards.dart';
import 'contribution_dto.dart';

class ContributionsRemoteDataSource {
  ContributionsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ContributionDto>> fetchForRound(String roundId) =>
      guardRemote(() async {
        final res = await _dio.get<List<dynamic>>(
          '/rest/v1/contributions',
          queryParameters: {
            'select': '*',
            'round_id': 'eq.$roundId',
            'deleted_at': 'is.null',
          },
        );
        return (res.data ?? [])
            .cast<Map<String, dynamic>>()
            .map(ContributionDto.fromJson)
            .toList();
      });

  Future<ContributionDto> create(Map<String, dynamic> body) => guardRemote(() async {
        final res = await _dio.post<List<dynamic>>(
          '/rest/v1/contributions',
          data: body,
          options: Options(headers: {'Prefer': 'return=representation'}),
        );
        final rows = res.data ?? [];
        if (rows.isEmpty) {
          throw const ServerException(message: 'Réponse vide du serveur.');
        }
        return ContributionDto.fromJson(rows.first as Map<String, dynamic>);
      });
}
