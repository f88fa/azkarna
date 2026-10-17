import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/layout/layout.dart';
import '../../../../core/widgets/app_backdrop.dart';
import '../../../../core/widgets/reveal.dart';
import '../../../moon/presentation/widgets/moon_phase_card.dart';
import '../../../prayer_times/presentation/widgets/prayer_times_card.dart';
import '../widgets/home_adhkar_section.dart';
import '../widgets/home_dock.dart';
import '../widgets/home_tasks_section.dart';

/// The app's single base page: prayer times, then adhkar, then today's
/// tasks. Everything else opens as a pop-up from the dock.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safe = MediaQuery.viewPaddingOf(context);
    final dockInset = navBarFootprint(safe.bottom) + 20;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: AppBackdrop(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, safe.top + 12, 20, 14),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/logo_symbol.png',
                      height: 42,
                      filterQuality: FilterQuality.high,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    const MoonPhasePill(),
                  ],
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 26),
              sliver: SliverToBoxAdapter(
                child: Reveal(child: PrayerTimesCard()),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 26),
              sliver: SliverToBoxAdapter(
                child: Reveal(index: 1, child: HomeAdhkarSection()),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, dockInset),
              sliver: const SliverToBoxAdapter(
                child: Reveal(index: 2, child: HomeTasksSection()),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const HomeDock(),
    );
  }
}
