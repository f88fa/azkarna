import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/adhkar/presentation/screens/adhkar_category_screen.dart';
import '../../features/adhkar/presentation/screens/adhkar_screen.dart';
import '../../features/quran/presentation/screens/quran_screen.dart';
import '../../features/quran/presentation/screens/surah_reader_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shell/presentation/screens/main_shell_screen.dart';
import '../../features/tasks/presentation/screens/tasks_screen.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.tasks,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShellScreen(navigationShell: navigationShell),
        branches: [
          _branch(AppRoutes.tasks, const TasksScreen()),
          _branch(
            AppRoutes.quran,
            const QuranScreen(),
            routes: [
              GoRoute(
                path: AppRoutes.surahPattern,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => SurahReaderScreen(
                  surahNumber:
                      int.tryParse(state.pathParameters['number'] ?? '') ?? 1,
                  initialAyah: int.tryParse(
                    state.uri.queryParameters['ayah'] ?? '',
                  ),
                ),
              ),
            ],
          ),
          _branch(
            AppRoutes.adhkar,
            const AdhkarScreen(),
            routes: [
              GoRoute(
                path: AppRoutes.adhkarCategoryPattern,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => AdhkarCategoryScreen(
                  categoryId: state.pathParameters['id'] ?? '',
                ),
              ),
            ],
          ),
          _branch(AppRoutes.settings, const SettingsScreen()),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

StatefulShellBranch _branch(
  String path,
  Widget child, {
  List<RouteBase> routes = const [],
}) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: child,
          transitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        ),
        routes: routes,
      ),
    ],
  );
}
