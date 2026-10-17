import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/layout/layout.dart';
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
        padding: EdgeInsets.fromLTRB(20, 0, 20, floatingNavBarInset(context)),
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
    final primary = theme.colorScheme.primary;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(AppRoutes.adhkarCategory(category.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(adhkarCategoryIcon(category.id), color: primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${category.adhkar.length} adhkar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                category.titleAr,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
