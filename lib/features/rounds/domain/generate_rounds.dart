import 'package:uuid/uuid.dart';

import '../../members/domain/member.dart';
import 'round.dart';

/// Calcule la liste des tours à partir des membres, sans toucher au réseau
/// ni au stockage : fonction pure, donc facile à tester isolément.
/// Rotation fixe = ordre des positions. Le premier tour est "current",
/// les suivants "upcoming", espacés selon [frequency].
List<Round> generateRounds({
  required String tontineId,
  required List<Member> members,
  required DateTime firstDueDate,
  required String frequency, // 'weekly' | 'biweekly' | 'monthly'
}) {
  final sorted = [...members]..sort((a, b) => a.position.compareTo(b.position));
  const uuid = Uuid();
  return [
    for (var i = 0; i < sorted.length; i++)
      Round(
        id: uuid.v4(),
        tontineId: tontineId,
        number: i + 1,
        beneficiaryId: sorted[i].id,
        dueDate: _advance(firstDueDate, frequency, i),
        status: i == 0 ? 'current' : 'upcoming',
      ),
  ];
}

DateTime _advance(DateTime start, String frequency, int steps) {
  switch (frequency) {
    case 'weekly':
      return start.add(Duration(days: 7 * steps));
    case 'biweekly':
      return start.add(Duration(days: 14 * steps));
    case 'monthly':
    default:
      return DateTime(start.year, start.month + steps, start.day);
  }
}
