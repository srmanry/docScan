import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:doc_sense/core/widgets/app_bottom_nav.dart';
import 'package:doc_sense/features/auth/presentation/pages/login_page.dart';
import 'package:doc_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:doc_sense/features/document/presentation/pages/home_page.dart';
import 'package:doc_sense/features/history/presentation/pages/history_page.dart';
import 'package:doc_sense/features/settings/presentation/pages/settings_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final loggingIn = state.matchedLocation == '/login';

      if (authState is AuthAuthenticated && loggingIn) return '/';
      if (authState is! AuthAuthenticated && !loggingIn) return '/login';
      return null;
    },
    refreshListenable: _AuthListenable(ref),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/', builder: (context, state) => const _RootShell()),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authProvider, (previous, next) => notifyListeners());
  }
}

/// Which bottom-nav tab is active. Exposed as a provider (rather than local
/// state) so pages nested inside a tab — e.g. Home's "See All" — can switch
/// tabs without the shell needing to hand them a callback.
final rootTabIndexProvider = StateProvider<int>((ref) => 0);

/// Bottom-nav shell for the three primary destinations once signed in.
class _RootShell extends ConsumerWidget {
  const _RootShell();

  static const _pages = [HomePage(), HistoryPage(), SettingsPage()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(rootTabIndexProvider);

    return Scaffold(
      extendBody: true,
      body: _pages[index],
      bottomNavigationBar: AppBottomNav(
        selectedIndex: index,
        onDestinationSelected: (i) => ref.read(rootTabIndexProvider.notifier).state = i,
        items: const [
          AppBottomNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          AppBottomNavItem(
            icon: Icons.history_outlined,
            activeIcon: Icons.history_rounded,
            label: 'History',
          ),
          AppBottomNavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
