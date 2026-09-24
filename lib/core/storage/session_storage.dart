import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokens extends Equatable {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  @override
  List<Object?> get props => [accessToken, refreshToken];
}

/// Stockage chiffré de la session (tokens + utilisateur en cache).
/// Les tokens sont aussi gardés en mémoire : l'intercepteur les lit à chaque requête.
class SessionStorage {
  SessionStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kUser = 'cached_user';

  AuthTokens? _memory;
  bool _loaded = false;

  Future<AuthTokens?> readTokens() async {
    if (_loaded) return _memory;
    final access = await _storage.read(key: _kAccess);
    final refresh = await _storage.read(key: _kRefresh);
    _memory = (access != null && refresh != null)
        ? AuthTokens(accessToken: access, refreshToken: refresh)
        : null;
    _loaded = true;
    return _memory;
  }

  Future<void> saveTokens(AuthTokens tokens) async {
    await _storage.write(key: _kAccess, value: tokens.accessToken);
    await _storage.write(key: _kRefresh, value: tokens.refreshToken);
    _memory = tokens;
    _loaded = true;
  }

  Future<String?> readUserJson() => _storage.read(key: _kUser);

  Future<void> saveUserJson(String json) =>
      _storage.write(key: _kUser, value: json);

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUser);
    _memory = null;
    _loaded = true;
  }
}
