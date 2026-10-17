import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/layout.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/popup_scaffold.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../khatmah/presentation/widgets/khatmah_card.dart';
import '../../domain/entities/quran_index.dart';
import '../providers/quran_providers.dart';
import '../widgets/go_to_page_dialog.dart';
import '../widgets/surah_tile.dart';

/// Normalizes Arabic for searching (diacritics and alef/ya variants).
String _norm(String input) => input
    .replaceAll(RegExp('[\u064B-\u065F\u0670\u0640]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .trim();

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  bool _byJuz = false;
  String _query = '';

  Future<void> _goToPage() async {
    final page = await showGoToPageDialog(context, current: 1);
    if (page != null && mounted) context.push(AppRoutes.mushafPage(page));
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(quranIndexProvider);
    final theme = Theme.of(context);

    return PopupScaffold(
      title: 'القرآن الكريم',
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
            sliver: SliverToBoxAdapter(child: KhatmahCard()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<bool>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: false, label: Text('السور')),
                            ButtonSegment(value: true, label: Text('الأجزاء')),
                          ],
                          selected: {_byJuz},
                          onSelectionChanged: (s) =>
                              setState(() => _byJuz = s.first),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        tooltip: 'الانتقال إلى صفحة',
                        onPressed: _goToPage,
                        icon: const Icon(Icons.pin_outlined),
                      ),
                    ],
                  ),
                  if (!_byJuz) ...[
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن سورة',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: theme.colorScheme.surface.withValues(
                          alpha: 0.7,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          index.when(
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
            data: (quran) => SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                floatingNavBarInset(context),
              ),
              sliver: _byJuz
                  ? _juzList(quran)
                  : _surahList(quran, _norm(_query)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _surahList(QuranIndex quran, String query) {
    final items = [
      for (final s in quran.surahs)
        if (query.isEmpty || _norm(s.name).contains(query)) s,
    ];
    if (items.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('لا توجد سورة بهذا الاسم')),
        ),
      );
    }
    return SliverList.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => SurahTile(
        surah: items[i],
        onTap: () => context.push(AppRoutes.mushafPage(items[i].startPage)),
      ),
    );
  }

  Widget _juzList(QuranIndex quran) {
    return SliverList.separated(
      itemCount: QuranIndex.juzCount,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final start = quran.juzStart(i + 1);
        return JuzTile(
          juz: i + 1,
          page: start.page,
          startLabel:
              'يبدأ من سورة ${start.surah.name}'
              '${start.ayah == 1 ? '' : ' · الآية ${arNum(start.ayah)}'}',
          onTap: () => context.push(AppRoutes.mushafPage(start.page)),
        );
      },
    );
  }
}
