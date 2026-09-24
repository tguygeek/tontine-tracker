import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/contribution_repository_impl.dart';
import '../data/contributions_local_data_source.dart';
import '../data/contributions_remote_data_source.dart';
import '../domain/contribution.dart';
import '../domain/contribution_repository.dart';

final contributionRepositoryProvider = Provider<ContributionRepository>((ref) {
  return ContributionRepositoryImpl(
    remote: ContributionsRemoteDataSource(ref.watch(dioProvider)),
    local: ContributionsLocalDataSource(ref.watch(appDatabaseProvider)),
  );
});

final contributionsProvider =
    FutureProvider.family<List<Contribution>, String>((ref, roundId) {
  return ref.watch(contributionRepositoryProvider).getForRound(roundId);
});
