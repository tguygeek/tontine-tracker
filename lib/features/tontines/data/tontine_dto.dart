import '../../../core/storage/app_database.dart';
import '../domain/tontine.dart';

/// Représentation d'une tontine côté "fil de données" : sait se construire
/// depuis le JSON Supabase, se convertir en ligne Drift, et se convertir
/// en entité domain.
class TontineDto {
  const TontineDto({
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
  final String frequency;
  final String rotationMode;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TontineDto.fromJson(Map<String, dynamic> json) => TontineDto(
        id: json['id'] as String,
        name: json['name'] as String,
        currency: json['currency'] as String,
        contributionAmount: (json['contribution_amount'] as num).toDouble(),
        frequency: json['frequency'] as String,
        rotationMode: json['rotation_mode'] as String,
        createdBy: json['created_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  /// Corps envoyé à PostgREST pour un INSERT.
  /// created_by est posé par la base via `default auth.uid()` (voir schéma
  /// SQL) : inutile et déconseillé de l'envoyer depuis le client.
  Map<String, dynamic> toInsertJson() => {
        'id': id,
        'name': name,
        'currency': currency,
        'contribution_amount': contributionAmount,
        'frequency': frequency,
        'rotation_mode': rotationMode,
      };

  Tontine toEntity() => Tontine(
        id: id,
        name: name,
        currency: currency,
        contributionAmount: contributionAmount,
        frequency: frequency,
        rotationMode: rotationMode,
        createdBy: createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  TontinesTableCompanion toCompanion() => TontinesTableCompanion.insert(
        id: id,
        name: name,
        currency: currency,
        contributionAmount: contributionAmount,
        frequency: frequency,
        rotationMode: rotationMode,
        createdBy: createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension TontineRowMapper on TontinesTableData {
  Tontine toEntity() => Tontine(
        id: id,
        name: name,
        currency: currency,
        contributionAmount: contributionAmount,
        frequency: frequency,
        rotationMode: rotationMode,
        createdBy: createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
