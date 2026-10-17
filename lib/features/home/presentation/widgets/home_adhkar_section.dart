import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../adhkar/domain/entities/adhkar_category.dart';
import '../../../adhkar/presentation/providers/adhkar_providers.dart';
import '../../../adhkar/presentation/widgets/adhkar_categories_section.dart'
    show adhkarCategoryColor, adhkarCategoryIcon;
import '../../../prayer_times/domain/entities/prayer_times.dart';
import '../../../prayer_times/presentation/providers/prayer_times_providers.dart';
import 'home_section_header.dart';

/// Which adhkar fit the current time of day, with a short invitation.
({String categoryId, String hint}) suggestedAdhkar(
  PrayerTimes? times,
  DateTime now,
) {
  bool reached(Prayer p, int fallbackHour) {
    final t = times?.times[p];
    return t != null ? !t.isAfter(now) : now.hour >= fallbackHour;
  }

  if (reached(Prayer.isha, 20)) {
    return (categoryId: 'sleep', hint: 'اختم يومك بذكر الله قبل النوم');
  }
  if (reached(Prayer.asr, 15)) {
    return (categoryId: 'evening', hint: 'حان وقت أذكار المساء');
  }
  if (reached(Prayer.dhuhr, 12)) {
    return (categoryId: 'after_prayer', hint: 'لا تنسَ أذكار ما بعد الصلاة');
  }
  if (reached(Prayer.fajr, 4)) {
    return (categoryId: 'morning', hint: 'ابدأ يومك بذكر الله');
  }
  return (categoryId: 'sleep', hint: 'اختم يومك بذكر الله قبل النوم');
}

class HomeAdhkarSection extends ConsumerWidget {
  const HomeAdhkarSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(adhkarCategoriesProvider).asData?.value;
    final times = ref.watch(prayerTimesProvider).asData?.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'الأذكار',
          actionLabel: 'عرض الكل',
          onAction: () => context.push(AppRoutes.adhkar),
        ),
        if (categories == null)
          const SizedBox(height: 160)
        else ...[
          _SuggestedCard(
            categories: categories,
            suggestion: suggestedAdhkar(
              times,
              times?.wallClockNow ?? DateTime.now(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) =>
                  _CategoryTile(category: categories[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _SuggestedCard extends StatelessWidget {
  const _SuggestedCard({required this.categories, required this.suggestion});

  final List<AdhkarCategory> categories;
  final ({String categoryId, String hint}) suggestion;

  @override
  Widget build(BuildContext context) {
    final category = categories.firstWhere(
      (c) => c.id == suggestion.categoryId,
      orElse: () => categories.first,
    );
    final color = adhkarCategoryColor(category.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () {
          HapticFeedback.selectionClick();
          context.push(AppRoutes.adhkarCategory(category.id));
        },
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [color, Color.lerp(color, Colors.black, 0.28)!],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  adhkarCategoryIcon(category.id),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.titleAr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${suggestion.hint} · ${arNum(category.adhkar.length)} أذكار',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
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

    return SizedBox(
      width: 112,
      child: GlassCard(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        onTap: () {
          HapticFeedback.selectionClick();
          context.push(AppRoutes.adhkarCategory(category.id));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [color.withValues(alpha: 0.85), color],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                adhkarCategoryIcon(category.id),
                color: Colors.white,
                size: 23,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.titleAr,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
