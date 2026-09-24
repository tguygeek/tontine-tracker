import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env.dart';
import 'core/config/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Env.ensureConfigured();
  runApp(const ProviderScope(child: TontineTrackerApp()));
}

class TontineTrackerApp extends ConsumerWidget {
  const TontineTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Tontine Tracker',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      routerConfig: router,
    );
  }
}
