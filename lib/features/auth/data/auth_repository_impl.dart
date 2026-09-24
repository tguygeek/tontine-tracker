// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import '../../../core/errors/guards.dart';
import '../../../core/storage/session_storage.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import 'auth_models.dart';
import 'auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required SessionStorage storage,
  }) : _remote = remote,
       _storage = storage;

  final AuthRemoteDataSource _remote;
  final SessionStorage _storage;

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    String? fullName,
  }) => guardFailure(() async {
    final session = await _remote.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );
    return _persist(session);
  });

  @override
  Future<AppUser> login({required String email, required String password}) =>
      guardFailure(() async {
        final session = await _remote.signIn(email: email, password: password);
        return _persist(session);
      });

  @override
  Future<void> logout() async {
    final tokens = await _storage.readTokens();
    if (tokens != null) {
      unawaited(_remote.signOut(tokens.accessToken)); // sans bloquer l'UI
    }
    await _storage.clear();
  }

  @override
  Future<AppUser?> restoreSession() async {
    final tokens = await _storage.readTokens();
    final raw = await _storage.readUserJson();
    if (tokens == null || raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return UserModel.fromJson(json).toEntity();
  }

  Future<AppUser> _persist(SessionModel session) async {
    await _storage.saveTokens(session.tokens);
    await _storage.saveUserJson(jsonEncode(session.user.toJson()));
    return session.user.toEntity();
  }
}
