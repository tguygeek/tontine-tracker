import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/tontines/presentation/tontine_detail_screen.dart';
import '../../features/tontines/presentation/tontines_list_screen.dart';

/// Pont entre les providers Riverpod et `Listenable` attendu par go_router :
/// go_router ne "watch" pas les providers, donc sans ça une déconnexion ne
/// déclencherait pas la redirection tant que l'utilisateur ne navigue pas.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  return GoRouter(
    initialLocation: '/tontines',
    refreshListenable: refresh,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authControllerProvider).value != null;
      final onAuthScreen = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!isLoggedIn && !onAuthScreen) return '/login';
      if (isLoggedIn && onAuthScreen) return '/tontines';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen()),
      GoRoute(
          path: '/tontines',
          builder: (context, state) => const TontinesListScreen()),
      GoRoute(
        path: '/tontines/:id',
        builder: (context, state) =>
            TontineDetailScreen(tontineId: state.pathParameters['id']!),
      ),
    ],
  );
});
