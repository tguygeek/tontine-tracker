import '../../../core/storage/app_database.dart';
import '../domain/member.dart';

class MemberDto {
  const MemberDto({
    required this.id,
    required this.tontineId,
    required this.displayName,
    required this.role,
    required this.position,
    required this.status,
  });

  final String id;
  final String tontineId;
  final String displayName;
  final String role;
  final int position;
  final String status;

  factory MemberDto.fromJson(Map<String, dynamic> json) => MemberDto(
        id: json['id'] as String,
        tontineId: json['tontine_id'] as String,
        displayName: json['display_name'] as String,
        role: json['role'] as String,
        position: json['position'] as int,
        status: (json['status'] as String?) ?? 'active',
      );

  /// status n'est pas envoyé : la base le pose à 'active' par défaut.
  Map<String, dynamic> toInsertJson() => {
        'id': id,
        'tontine_id': tontineId,
        'display_name': displayName,
        'role': role,
        'position': position,
      };

  Member toEntity() => Member(
        id: id,
        tontineId: tontineId,
        displayName: displayName,
        role: role,
        position: position,
        status: status,
      );

  MembersTableCompanion toCompanion() => MembersTableCompanion.insert(
        id: id,
        tontineId: tontineId,
        displayName: displayName,
        role: role,
        position: position,
        status: status,
        updatedAt: DateTime.now().toUtc(),
      );
}

extension MemberRowMapper on MembersTableData {
  Member toEntity() => Member(
        id: id,
        tontineId: tontineId,
        displayName: displayName,
        role: role,
        position: position,
        status: status,
      );
}
