import 'dart:io';

import 'package:dio/dio.dart';

import 'exceptions.dart';
import 'failures.dart';

/// À utiliser dans les datasources distantes : DioException -> AppException.
Future<T> guardRemote<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on AppException {
    rethrow;
  } on DioException catch (e) {
    throw _fromDio(e);
  }
}

/// À utiliser dans les repositories : AppException -> Failure.
Future<T> guardFailure<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on Failure {
    rethrow;
  } on AppException catch (e) {
    throw _toFailure(e);
  } on Exception {
    throw const UnknownFailure();
  }
}

AppException _fromDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.badResponse:
      {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        final message =
            _read(data, ['msg', 'message', 'error_description', 'error']);
        if (status == 401) return UnauthorizedException(message);
        return ServerException(
          statusCode: status,
          code: _read(data, ['error_code', 'code']),
          message: message,
        );
      }
    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
    default: // ex. DioExceptionType.transformTimeout, ajouté par des versions récentes de dio
      if (e.error is SocketException) return const NetworkException();
      return ServerException(message: e.message);
  }
}

Failure _toFailure(AppException e) => switch (e) {
      NetworkException() => const NetworkFailure(),
      UnauthorizedException() => const UnauthorizedFailure(),
      CacheException() => const CacheFailure(),
      ServerException(:final code, :final statusCode, :final message) =>
        _serverFailure(code, statusCode, message),
    };

Failure _serverFailure(String? code, int? status, String? message) {
  switch (code) {
    case 'invalid_credentials':
      return const InvalidCredentialsFailure();
    case 'user_already_exists':
    case 'email_exists':
      return const EmailAlreadyUsedFailure();
    case 'weak_password':
      return const ValidationFailure('Mot de passe trop faible.');
    case 'validation_failed':
      return const ValidationFailure('Données invalides (email mal formé ?).');
    case 'email_not_confirmed':
      return const ValidationFailure(
        'Email non confirmé. Désactive "Confirm email" dans Supabase pour ce projet.',
      );
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
      return const ValidationFailure('Trop de tentatives. Patiente un instant.');
    case '23505': // violation de contrainte unique Postgres (PostgREST)
      return const ValidationFailure(
        'Cette opération existe déjà (doublon détecté par la base).',
      );
  }
  if (status == 429) {
    return const ValidationFailure('Trop de tentatives. Patiente un instant.');
  }
  // Anciennes versions de GoTrue : pas de error_code, seulement un message.
  if (message != null && message.toLowerCase().contains('invalid login')) {
    return const InvalidCredentialsFailure();
  }
  return const ServerFailure();
}

String? _read(Object? data, List<String> keys) {
  if (data is Map) {
    for (final key in keys) {
      final value = data[key];
      if (value != null) return value.toString();
    }
  }
  return null;
}
