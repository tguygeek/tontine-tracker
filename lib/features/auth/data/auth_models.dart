import '../../../core/errors/exceptions.dart';
import '../../../core/storage/session_storage.dart';
import '../domain/app_user.dart';

class UserModel {
  const UserModel({required this.id, required this.email, this.fullName});

  final String id;
  final String email;
  final String? fullName;

  /// Sert à la fois pour la réponse de l'API et pour le cache local
  /// (toJson reproduit la même forme).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final meta = json['user_metadata'];
    final name = meta is Map ? meta['full_name'] : null;
    return UserModel(
      id: json['id'] as String,
      email: (json['email'] as String?) ?? '',
      fullName: (name is String && name.isNotEmpty) ? name : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'user_metadata': {'full_name': fullName},
      };

  AppUser toEntity() => AppUser(id: id, email: email, fullName: fullName);
}

class SessionModel {
  const SessionModel({required this.tokens, required this.user});

  final AuthTokens tokens;
  final UserModel user;

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    final access = json['access_token'];
    final refresh = json['refresh_token'];
    final user = json['user'];
    if (access is! String || refresh is! String || user is! Map<String, dynamic>) {
      // Pas de session renvoyée : typiquement "Confirm email" encore activé.
      throw const ServerException(code: 'email_not_confirmed');
    }
    return SessionModel(
      tokens: AuthTokens(accessToken: access, refreshToken: refresh),
      user: UserModel.fromJson(user),
    );
  }
}
