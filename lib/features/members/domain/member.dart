import 'package:equatable/equatable.dart';

class Member extends Equatable {
  const Member({
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
  final String role; // 'admin' | 'treasurer' | 'member'
  final int position; // ordre dans la rotation des tours
  final String status; // 'active' | 'left'

  @override
  List<Object?> get props =>
      [id, tontineId, displayName, role, position, status];
}
