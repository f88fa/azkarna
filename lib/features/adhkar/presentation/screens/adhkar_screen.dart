import 'package:flutter/material.dart';

import '../../../../core/layout/layout.dart';
import '../../../../core/widgets/app_backdrop.dart';
import '../../../moon/presentation/widgets/moon_phase_card.dart';
import '../../../prayer_times/presentation/widgets/prayer_times_card.dart';
import '../widgets/adhkar_categories_section.dart';

class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackdrop(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar.large(
              backgroundColor: Colors.transparent,
              title: const Text(
                'الأذكار',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
              sliver: SliverToBoxAdapter(child: PrayerTimesCard()),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 22),
              sliver: SliverToBoxAdapter(child: MoonPhaseCard()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'أقسام الأذكار',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const AdhkarCategoriesSection(),
            SliverToBoxAdapter(
              child: SizedBox(height: floatingNavBarInset(context)),
            ),
          ],
        ),
      ),
    );
  }
}
