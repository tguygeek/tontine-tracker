/// Exceptions de la couche data (techniques).
/// Les repositories les convertissent en [Failure] (voir guards.dart).
sealed class AppException implements Exception {
  const AppException([this.message]);
  final String? message;
}

final class NetworkException extends AppException {
  const NetworkException();
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message]);
}

final class ServerException extends AppException {
  const ServerException({this.statusCode, this.code, String? message})
      : super(message);
  final int? statusCode;
  final String? code;
}

final class CacheException extends AppException {
  const CacheException([super.message]);
}
