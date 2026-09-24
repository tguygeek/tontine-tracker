// Page TEMPORAIRE pour valider le socle (auth + intercepteur + refresh).
// Sera remplacée par les vrais écrans (go_router + login/register).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/errors/failures.dart';
import 'core/errors/guards.dart';
import 'core/providers.dart';
import 'core/storage/session_storage.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'features/tontines/presentation/tontines_providers.dart';

class SmokePage extends ConsumerStatefulWidget {
  const SmokePage({super.key});

  @override
  ConsumerState<SmokePage> createState() => _SmokePageState();
}

class _SmokePageState extends ConsumerState<SmokePage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _logs = <String>[];

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _log(String message) => setState(() => _logs.insert(0, message));

  String _tail(AuthTokens? t) => t == null
      ? 'aucun'
      : t.accessToken.substring(t.accessToken.length - 6);

  void _reportAuth(String action) {
    ref.read(authControllerProvider).when(
          data: (u) => _log('$action → ${u?.email ?? "déconnecté"}'),
          loading: () => _log('$action → …'),
          error: (e, _) =>
              _log('$action → ❌ ${e is Failure ? e.message : e}'),
        );
  }

  Future<void> _register() async {
    await ref.read(authControllerProvider.notifier).register(
          email: _email.text.trim(),
          password: _password.text,
          fullName: 'Testeur',
        );
    _reportAuth('Register');
  }

  Future<void> _login() async {
    await ref.read(authControllerProvider.notifier).login(
          email: _email.text.trim(),
          password: _password.text,
        );
    _reportAuth('Login');
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    _reportAuth('Logout');
  }

  Future<void> _callApi() async {
    final storage = ref.read(sessionStorageProvider);
    final before = await storage.readTokens();
    try {
      final res = await guardFailure(
        () => guardRemote(
          () => ref.read(dioProvider).get<dynamic>(
            '/rest/v1/tontines',
            queryParameters: {'select': 'id', 'limit': 1},
          ),
        ),
      );
      final after = await storage.readTokens();
      _log('API ${res.statusCode} ${res.data} | token …${_tail(before)} → …${_tail(after)}');
    } on Failure catch (f) {
      _log('API ❌ ${f.message}');
    }
  }

  Future<void> _corruptToken() async {
    final storage = ref.read(sessionStorageProvider);
    final tokens = await storage.readTokens();
    if (tokens == null) {
      _log('Connecte-toi d\'abord.');
      return;
    }
    await storage.saveTokens(
      AuthTokens(
        accessToken: 'token.invalide.expire',
        refreshToken: tokens.refreshToken,
      ),
    );
    _log('Token corrompu. Clique sur "Appeler l\'API" : il doit se réparer tout seul.');
  }

  Future<void> _createTontine() async {
    final n = DateTime.now();
    try {
      await ref.read(tontinesControllerProvider.notifier).create(
            name: 'Test ${n.hour}:${n.minute}:${n.second}',
            contributionAmount: 5000,
            frequency: 'monthly',
          );
      _log('Tontine créée (visible même hors-ligne, synchro tentée).');
    } on Failure catch (f) {
      _log('Créer tontine ❌ ${f.message}');
    }
  }

  Future<void> _refreshTontines() async {
    await ref.read(tontinesControllerProvider.notifier).refresh();
    _log('Rafraîchi.');
  }

  Future<void> _syncOutbox() async {
    await ref.read(tontinesControllerProvider.notifier).syncOutbox();
    _log('Outbox synchronisée.');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final status = auth.when(
      data: (u) => u == null ? 'Déconnecté' : 'Connecté : ${u.email}',
      loading: () => 'Chargement…',
      error: (e, _) => 'Erreur : ${e is Failure ? e.message : e}',
    );
    final tontines = ref.watch(tontinesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Smoke test : socle réseau')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(status, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _password,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(onPressed: _register, child: const Text('Register')),
              FilledButton(onPressed: _login, child: const Text('Login')),
              OutlinedButton(onPressed: _callApi, child: const Text('Appeler l\'API')),
              OutlinedButton(onPressed: _corruptToken, child: const Text('Simuler token expiré')),
              TextButton(onPressed: _logout, child: const Text('Logout')),
            ],
          ),
          const Divider(height: 32),
          Text('Tontines (réseau → cache → outbox)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                  onPressed: _createTontine, child: const Text('Créer tontine test')),
              OutlinedButton(
                  onPressed: _refreshTontines, child: const Text('Rafraîchir')),
              OutlinedButton(
                  onPressed: _syncOutbox, child: const Text('Synchroniser l\'outbox')),
            ],
          ),
          const SizedBox(height: 8),
          tontines.when(
            data: (list) => list.isEmpty
                ? const Text('Aucune tontine.')
                : Column(
                    children: [
                      for (final t in list)
                        ListTile(
                          dense: true,
                          title: Text(t.name),
                          subtitle: Text(
                              '${t.contributionAmount.toStringAsFixed(0)} ${t.currency} · ${t.frequency}'),
                        ),
                    ],
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) =>
                Text('❌ ${e is Failure ? e.message : e}', style: const TextStyle(color: Colors.red)),
          ),
          const Divider(height: 32),
          for (final line in _logs)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
