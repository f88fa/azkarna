import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/layout/layout.dart';
import '../../../khatmah/presentation/widgets/khatmah_card.dart';
import '../providers/quran_providers.dart';
import '../widgets/surah_tile.dart';
import '../../../../core/widgets/error_view.dart';

class QuranScreen extends ConsumerWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final surahs = ref.watch(surahsProvider);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar.large(
            backgroundColor: theme.scaffoldBackgroundColor,
            title: const Text(
              'Quran',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverToBoxAdapter(child: KhatmahCard()),
          ),
          surahs.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: ErrorView(
                error: error,
                onRetry: () => ref.invalidate(surahsProvider),
              ),
            ),
            data: (items) => SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                floatingNavBarInset(context),
              ),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final surah = items[index];
                  return SurahTile(
                    surah: surah,
                    onTap: () => context.push(AppRoutes.surah(surah.number)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
