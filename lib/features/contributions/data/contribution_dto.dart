import '../../../core/storage/app_database.dart';
import '../domain/contribution.dart';

class ContributionDto {
  const ContributionDto({
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
  final String method;
  final String status;

  factory ContributionDto.fromJson(Map<String, dynamic> json) => ContributionDto(
        id: json['id'] as String,
        tontineId: json['tontine_id'] as String,
        roundId: json['round_id'] as String,
        membershipId: json['membership_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        method: json['method'] as String,
        status: json['status'] as String,
      );

  /// status n'est pas envoyé : la base le pose à 'pending' par défaut.
  Map<String, dynamic> toInsertJson() => {
        'id': id,
        'tontine_id': tontineId,
        'round_id': roundId,
        'membership_id': membershipId,
        'amount': amount,
        'method': method,
      };

  Contribution toEntity() => Contribution(
        id: id,
        tontineId: tontineId,
        roundId: roundId,
        membershipId: membershipId,
        amount: amount,
        method: method,
        status: status,
      );

  ContributionsTableCompanion toCompanion() => ContributionsTableCompanion.insert(
        id: id,
        tontineId: tontineId,
        roundId: roundId,
        membershipId: membershipId,
        amount: amount,
        method: method,
        status: status,
        updatedAt: DateTime.now().toUtc(),
      );
}

extension ContributionRowMapper on ContributionsTableData {
  Contribution toEntity() => Contribution(
        id: id,
        tontineId: tontineId,
        roundId: roundId,
        membershipId: membershipId,
        amount: amount,
        method: method,
        status: status,
      );
}
