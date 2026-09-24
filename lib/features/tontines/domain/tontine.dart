import 'package:equatable/equatable.dart';

class Tontine extends Equatable {
  const Tontine({
    required this.id,
    required this.name,
    required this.currency,
    required this.contributionAmount,
    required this.frequency,
    required this.rotationMode,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String currency;
  final double contributionAmount;
  final String frequency; // 'weekly' | 'biweekly' | 'monthly'
  final String rotationMode; // 'fixed' | 'random'
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        name,
        currency,
        contributionAmount,
        frequency,
        rotationMode,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
