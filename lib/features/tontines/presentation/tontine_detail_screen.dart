import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../contributions/presentation/contributions_providers.dart';
import '../../members/domain/member.dart';
import '../../members/presentation/members_providers.dart';
import '../../rounds/domain/generate_rounds.dart';
import '../../rounds/domain/round.dart';
import '../../rounds/presentation/rounds_providers.dart';
import '../domain/tontine.dart';
import 'tontines_providers.dart';

class TontineDetailScreen extends ConsumerStatefulWidget {
  const TontineDetailScreen({required this.tontineId, super.key});

  final String tontineId;

  @override
  ConsumerState<TontineDetailScreen> createState() =>
      _TontineDetailScreenState();
}

class _TontineDetailScreenState extends ConsumerState<TontineDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {})); // pour rafraîchir le FAB
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get tontineId => widget.tontineId;

  // ---- Membres ----------------------------------------------------------

  Future<void> _openAddMemberDialog(int nextPosition) async {
    final nameCtrl = TextEditingController();
    final add = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un membre'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Nom du membre'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (add != true || nameCtrl.text.trim().isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(memberRepositoryProvider)
          .addMember(
            tontineId: tontineId,
            displayName: nameCtrl.text.trim(),
            position: nextPosition,
          );
      ref.invalidate(membersProvider(tontineId));
    } on Failure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  // ---- Tours --------------------------------------------------------

  Future<void> _generateRounds(List<Member> members) async {
    if (members.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final rounds = generateRounds(
        tontineId: tontineId,
        members: members,
        firstDueDate: DateTime.now(),
        // v1 : fréquence fixée à mensuelle. À lire depuis la tontine
        // elle-même dans une prochaine itération.
        frequency: 'monthly',
      );
      await ref.read(roundRepositoryProvider).createRounds(rounds);
      ref.invalidate(roundsProvider(tontineId));
    } on Failure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openRecordContributionDialog({
    required Round round,
    required Member member,
  }) async {
    final tontines = ref.read(tontinesControllerProvider).value ?? const [];
    Tontine? tontine;
    for (final t in tontines) {
      if (t.id == tontineId) {
        tontine = t;
        break;
      }
    }
    final amountCtrl = TextEditingController(
      text: tontine != null
          ? tontine.contributionAmount.toStringAsFixed(0)
          : '',
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cotisation — ${member.displayName}'),
        content: TextField(
          controller: amountCtrl,
          decoration: const InputDecoration(labelText: 'Montant (XAF)'),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
    if (confirm != true || amount == null || amount <= 0) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(contributionRepositoryProvider)
          .record(
            tontineId: tontineId,
            roundId: round.id,
            membershipId: member.id,
            amount: amount,
          );
      ref.invalidate(contributionsProvider(round.id));
    } on Failure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _buildRoundsTab(List<Member> members) {
    final rounds = ref.watch(roundsProvider(tontineId));

    return rounds.when(
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Aucun tour généré.', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: members.isEmpty
                        ? null
                        : () => _generateRounds(members),
                    child: Text(
                      members.isEmpty
                          ? 'Ajoute des membres d\'abord'
                          : 'Générer les tours',
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        Round current = list.first;
        for (final r in list) {
          if (r.status == 'current') {
            current = r;
            break;
          }
        }
        Member? beneficiary;
        for (final m in members) {
          if (m.id == current.beneficiaryId) {
            beneficiary = m;
            break;
          }
        }
        final contributions = ref.watch(contributionsProvider(current.id));

        return ListView(
          children: [
            ListTile(
              tileColor: Theme.of(context).colorScheme.primaryContainer,
              title: Text('Tour n°${current.number}'),
              subtitle: Text(
                'Bénéficiaire : ${beneficiary?.displayName ?? '—'}',
              ),
            ),
            contributions.when(
              data: (paid) => Column(
                children: [
                  for (final m in members)
                    Builder(
                      builder: (context) {
                        final done = paid.any((c) => c.membershipId == m.id);
                        return ListTile(
                          leading: Icon(
                            done ? Icons.check_circle : Icons.circle_outlined,
                            color: done ? Colors.green : null,
                          ),
                          title: Text(m.displayName),
                          trailing: done
                              ? const Text('Payé')
                              : TextButton(
                                  onPressed: () =>
                                      _openRecordContributionDialog(
                                        round: current,
                                        member: m,
                                      ),
                                  child: const Text('Marquer payé'),
                                ),
                        );
                      },
                    ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(e is Failure ? e.message : 'Erreur inattendue.'),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            e is Failure ? e.message : 'Erreur inattendue.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider(tontineId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la tontine'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Membres'),
            Tab(text: 'Tour courant'),
          ],
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(membersProvider(tontineId)),
                  child: members.when(
                    data: (list) => list.isEmpty
                        ? ListView(
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'Aucun membre pour le moment.\nAjoutes-en un avec le bouton +.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (context, i) {
                              final m = list[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text('${m.position}'),
                                ),
                                title: Text(m.displayName),
                                subtitle: Text(m.role),
                              );
                            },
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          e is Failure ? e.message : 'Erreur inattendue.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                _buildRoundsTab(members.value ?? const []),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () {
                final nextPosition = (members.value?.length ?? 0) + 1;
                _openAddMemberDialog(nextPosition);
              },
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }
}
