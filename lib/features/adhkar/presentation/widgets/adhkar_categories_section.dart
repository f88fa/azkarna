import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/adhkar_category.dart';
import '../providers/adhkar_providers.dart';
import '../../../../core/widgets/error_view.dart';

IconData adhkarCategoryIcon(String id) => switch (id) {
  'morning' => Icons.wb_sunny_rounded,
  'evening' => Icons.nights_stay_rounded,
  'after_prayer' => Icons.mosque_rounded,
  'sleep' => Icons.bedtime_rounded,
  _ => Icons.auto_awesome_rounded,
};

Color adhkarCategoryColor(String id) => switch (id) {
  'morning' => AppColors.orange,
  'evening' => AppColors.indigo,
  'after_prayer' => AppColors.teal,
  'sleep' => AppColors.purple,
  _ => AppColors.blue,
};

/// Sliver list of Adhkar categories shown under the prayer times card.
class AdhkarCategoriesSection extends ConsumerWidget {
  const AdhkarCategoriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(adhkarCategoriesProvider);

    return categories.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => SliverToBoxAdapter(
        child: ErrorView(
          error: error,
          onRetry: () => ref.invalidate(adhkarCategoriesProvider),
        ),
      ),
      data: (items) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        sliver: SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) =>
              _CategoryTile(category: items[index]),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final AdhkarCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = adhkarCategoryColor(category.id);

    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(AppRoutes.adhkarCategory(category.id)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [color.withValues(alpha: 0.85), color],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              adhkarCategoryIcon(category.id),
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.titleAr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${arNum(category.adhkar.length)} أذكار',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_left_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
