import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/adhkar/presentation/screens/adhkar_category_screen.dart';
import '../../features/adhkar/presentation/screens/adhkar_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/quran/presentation/screens/kahf_reader_screen.dart';
import '../../features/quran/presentation/screens/mushaf_reader_screen.dart';
import '../../features/quran/presentation/screens/quran_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tasbeeh/presentation/screens/tasbeeh_screen.dart';
import '../../features/tasks/presentation/screens/tasks_screen.dart';
import '../widgets/app_sheet_page.dart';
import 'app_routes.dart';

/// The home screen is the single base page. Tasks, Quran, Adhkar and
/// Settings open as pop-up sheets over it; closing a sheet returns home.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      _sheet(AppRoutes.tasks, const TasksScreen()),
      _sheet(AppRoutes.quran, const QuranScreen()),
      _sheet(AppRoutes.adhkar, const AdhkarScreen()),
      _sheet(AppRoutes.settings, const SettingsScreen()),
      _sheet(AppRoutes.tasbeeh, const TasbeehScreen()),
      GoRoute(
        path: AppRoutes.kahf,
        builder: (context, state) => const KahfReaderScreen(),
      ),
      GoRoute(
        path: AppRoutes.mushafPagePattern,
        builder: (context, state) => MushafReaderScreen(
          initialPage: int.tryParse(state.pathParameters['page'] ?? '') ?? 1,
        ),
      ),
      GoRoute(
        path: AppRoutes.adhkarCategoryPattern,
        builder: (context, state) =>
            AdhkarCategoryScreen(categoryId: state.pathParameters['id'] ?? ''),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

GoRoute _sheet(String path, Widget child) => GoRoute(
  path: path,
  pageBuilder: (context, state) => appSheetPage(state: state, child: child),
);
