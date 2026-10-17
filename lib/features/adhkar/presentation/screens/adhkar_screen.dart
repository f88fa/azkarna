import 'package:flutter/material.dart';

import '../../../../core/layout/layout.dart';
import '../../../../core/widgets/popup_scaffold.dart';
import '../widgets/adhkar_categories_section.dart';

class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PopupScaffold(
      title: 'الأذكار',
      child: CustomScrollView(
        physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          AdhkarCategoriesSection(),
          SliverToBoxAdapter(child: _BottomGap()),
        ],
      ),
    );
  }
}

class _BottomGap extends StatelessWidget {
  const _BottomGap();

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: floatingNavBarInset(context));
}
