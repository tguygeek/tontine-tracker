import 'package:equatable/equatable.dart';

class Contribution extends Equatable {
  const Contribution({
    required this.id,
    required this.tontineId,
    required this.roundId,
    required this.membershipId,
    required this.amount,
    required this.method,
    required this.status,
  });

  final String id;
  final String tontineId;
  final String roundId;
  final String membershipId;
  final double amount;
  final String method; // 'cash' | 'momo_mtn' | 'momo_orange'
  final String status; // 'pending' | 'confirmed' | 'late'

  @override
  List<Object?> get props =>
      [id, tontineId, roundId, membershipId, amount, method, status];
}
