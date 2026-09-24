import 'package:equatable/equatable.dart';

class Round extends Equatable {
  const Round({
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
  final String status; // 'upcoming' | 'current' | 'closed'

  @override
  List<Object?> get props =>
      [id, tontineId, number, beneficiaryId, dueDate, status];
}
