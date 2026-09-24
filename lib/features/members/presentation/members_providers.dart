import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/member_repository_impl.dart';
import '../data/members_local_data_source.dart';
import '../data/members_remote_data_source.dart';
import '../domain/member.dart';
import '../domain/member_repository.dart';

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepositoryImpl(
    remote: MembersRemoteDataSource(ref.watch(dioProvider)),
    local: MembersLocalDataSource(ref.watch(appDatabaseProvider)),
  );
});

/// Liste des membres d'une tontine donnée. FutureProvider.family plutôt
/// qu'un AsyncNotifier : plus simple à invalider après une création
/// (ref.invalidate(membersProvider(tontineId))).
final membersProvider =
    FutureProvider.family<List<Member>, String>((ref, tontineId) {
  return ref.watch(memberRepositoryProvider).getMembers(tontineId);
});
