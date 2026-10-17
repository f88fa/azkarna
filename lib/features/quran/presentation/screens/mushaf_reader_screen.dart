import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/layout.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../khatmah/domain/entities/khatmah_progress.dart';
import '../../../khatmah/presentation/providers/khatmah_providers.dart';
import '../../domain/entities/quran_index.dart';
import '../../domain/entities/surah.dart';
import '../providers/quran_providers.dart';
import '../widgets/go_to_page_dialog.dart';
import '../widgets/mushaf_page_view.dart';

/// Reads the Quran page by page, exactly as in the printed Madani Mushaf
/// (604 pages), with a "where I stopped" bookmark.
class MushafReaderScreen extends ConsumerStatefulWidget {
  const MushafReaderScreen({super.key, required this.initialPage});

  final int initialPage;

  @override
  ConsumerState<MushafReaderScreen> createState() => _MushafReaderScreenState();
}

class _MushafReaderScreenState extends ConsumerState<MushafReaderScreen> {
  late final int _start = widget.initialPage.clamp(1, QuranIndex.pageCount);
  late final PageController _controller = PageController(
    initialPage: _start - 1,
  );
  late int _page = _start;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jumpTo(int page) {
    final target = page.clamp(1, QuranIndex.pageCount);
    _controller.animateToPage(
      target - 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _askPage() async {
    final page = await showGoToPageDialog(context, current: _page);
    if (page != null && mounted) _jumpTo(page);
  }

  Future<void> _saveBookmark(QuranIndex index, Surah surah, Ayah ayah) async {
    HapticFeedback.selectionClick();
    await ref
        .read(khatmahProvider.notifier)
        .updatePosition(
          Bookmark(surahNumber: surah.number, ayahNumber: ayah.number),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          content: Text(
            'تم حفظ العلامة · سورة ${surah.name} · '
            'الآية ${arNum(ayah.number)} · صفحة ${arNum(ayah.page)}',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(quranIndexProvider);
    final bookmark = ref.watch(khatmahProvider).asData?.value.bookmark;
    final data = index.asData?.value;
    final bookmarkPage = bookmark == null
        ? null
        : data?.pageOf(bookmark.surahNumber, bookmark.ayahNumber);

    final title = data == null
        ? 'القرآن الكريم'
        : data
              .page(_page)
              .segments
              .map((s) => 'سورة ${s.surah.name}')
              .join(' · ');

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: 'الانتقال إلى علامة القراءة',
            onPressed: bookmarkPage == null
                ? null
                : () => _jumpTo(bookmarkPage),
            icon: Icon(
              bookmarkPage == null
                  ? Icons.bookmark_border_rounded
                  : Icons.bookmark_rounded,
            ),
          ),
          IconButton(
            tooltip: 'الانتقال إلى صفحة',
            onPressed: data == null ? null : _askPage,
            icon: const Icon(Icons.pin_outlined),
          ),
        ],
      ),
      body: index.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(quranIndexProvider),
        ),
        data: (quran) => PageView.builder(
          controller: _controller,
          itemCount: QuranIndex.pageCount,
          onPageChanged: (i) => setState(() => _page = i + 1),
          itemBuilder: (context, i) => MushafPageView(
            key: ValueKey(i),
            page: quran.page(i + 1),
            bookmark: bookmark,
            bottomInset: screenBottomInset(context, extra: 16),
            onAyahSelected: (surah, ayah) =>
                _showAyahSheet(quran, surah, ayah, bookmark),
          ),
        ),
      ),
    );
  }

  Future<void> _showAyahSheet(
    QuranIndex index,
    Surah surah,
    Ayah ayah,
    Bookmark? bookmark,
  ) {
    final isMarked =
        bookmark?.surahNumber == surah.number &&
        bookmark?.ayahNumber == ayah.number;
    final theme = Theme.of(context);

    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'سورة ${surah.name} · الآية ${arNum(ayah.number)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'صفحة ${arNum(ayah.page)} · الجزء ${arNum(ayah.juz)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isMarked
                    ? null
                    : () {
                        Navigator.of(sheetContext).pop();
                        _saveBookmark(index, surah, ayah);
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: Icon(
                  isMarked
                      ? Icons.bookmark_added_rounded
                      : Icons.bookmark_add_rounded,
                ),
                label: Text(
                  isMarked ? 'هذه علامتك الحالية' : 'وقفت هنا · احفظ العلامة',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: ayah.text));
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                ),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('نسخ الآية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
