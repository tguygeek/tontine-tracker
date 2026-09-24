import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failures.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../auth/presentation/auth_providers.dart';
import 'tontines_providers.dart';

class TontinesListScreen extends ConsumerWidget {
  const TontinesListScreen({super.key});

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    var frequency = 'monthly';

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouvelle tontine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: amountCtrl,
                decoration:
                    const InputDecoration(labelText: 'Montant de cotisation (XAF)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: frequency,
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Hebdomadaire')),
                  DropdownMenuItem(value: 'biweekly', child: Text('Bimensuelle')),
                  DropdownMenuItem(value: 'monthly', child: Text('Mensuelle')),
                ],
                onChanged: (v) => setState(() => frequency = v ?? frequency),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );

    if (created != true) return;
    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
    if (nameCtrl.text.trim().isEmpty || amount == null || amount <= 0) return;

    // ignore: use_build_context_synchronously
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(tontinesControllerProvider.notifier).create(
            name: nameCtrl.text.trim(),
            contributionAmount: amount,
            frequency: frequency,
          );
    } on Failure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tontines = ref.watch(tontinesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes tontines'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(tontinesControllerProvider.notifier).refresh(),
              child: tontines.when(
                data: (list) => list.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'Aucune tontine pour le moment.\nCrée-en une avec le bouton +.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final t = list[i];
                          return ListTile(
                            title: Text(t.name),
                            subtitle: Text(
                                '${t.contributionAmount.toStringAsFixed(0)} ${t.currency} · ${t.frequency}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/tontines/${t.id}'),
                          );
                        },
                      ),
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
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
