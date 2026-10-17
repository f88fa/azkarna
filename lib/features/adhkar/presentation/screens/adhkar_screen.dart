import 'package:flutter/material.dart';

import '../../../prayer_times/presentation/widgets/prayer_times_card.dart';
import '../widgets/adhkar_categories_section.dart';

class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar.large(
            backgroundColor: theme.scaffoldBackgroundColor,
            title: const Text(
              'Adhkar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverToBoxAdapter(child: PrayerTimesCard()),
          ),
          const AdhkarCategoriesSection(),
        ],
      ),
    );
  }
}
