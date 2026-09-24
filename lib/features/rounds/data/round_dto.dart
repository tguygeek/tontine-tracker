import '../../../core/storage/app_database.dart';
import '../domain/round.dart';

class RoundDto {
  const RoundDto({
    required this.id,
    required this.tontineId,
    required this.number,
    required this.beneficiaryId,
    required this.dueDate,
    required this.status,
  });

  final String id;
  final String tontineId;
  final int number;
  final String beneficiaryId;
  final DateTime dueDate;
  final String status;

  factory RoundDto.fromJson(Map<String, dynamic> json) => RoundDto(
        id: json['id'] as String,
        tontineId: json['tontine_id'] as String,
        number: json['number'] as int,
        beneficiaryId: json['beneficiary_id'] as String,
        dueDate: DateTime.parse(json['due_date'] as String),
        status: json['status'] as String,
      );

  Map<String, dynamic> toInsertJson() => {
        'id': id,
        'tontine_id': tontineId,
        'number': number,
        'beneficiary_id': beneficiaryId,
        // Colonne SQL "date" : on ne garde que AAAA-MM-JJ.
        'due_date': dueDate.toIso8601String().split('T').first,
        'status': status,
      };

  Round toEntity() => Round(
        id: id,
        tontineId: tontineId,
        number: number,
        beneficiaryId: beneficiaryId,
        dueDate: dueDate,
        status: status,
      );

  RoundsTableCompanion toCompanion() => RoundsTableCompanion.insert(
        id: id,
        tontineId: tontineId,
        number: number,
        beneficiaryId: beneficiaryId,
        dueDate: dueDate,
        status: status,
        updatedAt: DateTime.now().toUtc(),
      );
}

extension RoundRowMapper on RoundsTableData {
  Round toEntity() => Round(
        id: id,
        tontineId: tontineId,
        number: number,
        beneficiaryId: beneficiaryId,
        dueDate: dueDate,
        status: status,
      );
}
