import 'member.dart';

abstract interface class MemberRepository {
  /// Réseau d'abord ; repli sur le cache si le réseau est indisponible.
  Future<List<Member>> getMembers(String tontineId);

  /// Écrit en local immédiatement (optimiste), puis tente une synchro.
  Future<Member> addMember({
    required String tontineId,
    required String displayName,
    required int position,
    String role,
  });

  Future<void> syncOutbox();
}
