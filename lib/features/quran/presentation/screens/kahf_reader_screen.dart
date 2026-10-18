import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/layout.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/app_backdrop.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/surah.dart';
import '../providers/kahf_providers.dart';
import '../providers/quran_providers.dart';
import '../widgets/mushaf_page_view.dart';

/// Surah Al-Kahf in one comfortable, continuous scroll with a large, adjustable
/// Quran font. The reading position is saved automatically and restored.
class KahfReaderScreen extends ConsumerStatefulWidget {
  const KahfReaderScreen({super.key});

  @override
  ConsumerState<KahfReaderScreen> createState() => _KahfReaderScreenState();
}

class _KahfReaderScreenState extends ConsumerState<KahfReaderScreen> {
  final ScrollController _scroll = ScrollController();
  late final KahfProgressNotifier _progress;
  bool _restored = false;
  double _fraction = 0;

  @override
  void initState() {
    super.initState();
    _progress = ref.read(kahfProgressProvider.notifier);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    // `ref` is unsafe here and providers must not change mid-teardown, so
    // save the final position right after the tree has been torn down.
    if (_restored) {
      final fraction = _currentFraction();
      Future.microtask(() => _progress.save(fraction));
    }
    _scroll.dispose();
    super.dispose();
  }

  double _currentFraction() {
    if (!_scroll.hasClients) return _fraction;
    final max = _scroll.position.maxScrollExtent;
    return max <= 0 ? 0 : (_scroll.offset / max).clamp(0.0, 1.0);
  }

  void _onScroll() {
    final f = _currentFraction();
    if ((f - _fraction).abs() > 0.002) setState(() => _fraction = f);
  }

  void _persist() {
    if (!_restored) return;
    _progress.save(_currentFraction());
  }

  /// Jumps to the saved position once the text has been laid out.
  void _restore() {
    if (_restored) return;
    _restored = true;
    final saved = ref.read(kahfProgressProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (saved > 0 && max > 0) _scroll.jumpTo(saved * max);
      setState(() => _fraction = _currentFraction());
    });
  }

  Future<void> _restart() async {
    HapticFeedback.selectionClick();
    await _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final surah = ref.watch(surahProvider(kahfSurahNumber));
    final fontSize = ref.watch(kahfFontSizeProvider);
    final fonts = ref.read(kahfFontSizeProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'سورة الكهف',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
        actions: [
          IconButton(
            tooltip: 'تصغير الخط',
            onPressed: fontSize <= KahfFontSizeNotifier.min
                ? null
                : () => fonts.change(-2),
            icon: const Icon(Icons.text_decrease_rounded),
          ),
          IconButton(
            tooltip: 'تكبير الخط',
            onPressed: fontSize >= KahfFontSizeNotifier.max
                ? null
                : () => fonts.change(2),
            icon: const Icon(Icons.text_increase_rounded),
          ),
          IconButton(
            tooltip: 'العودة إلى البداية',
            onPressed: _restart,
            icon: const Icon(Icons.vertical_align_top_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: _fraction,
            minHeight: 3,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          ),
        ),
      ),
      body: AppBackdrop(
        child: surah.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(surahProvider(kahfSurahNumber)),
          ),
          data: (data) {
            _restore();
            return NotificationListener<ScrollEndNotification>(
              onNotification: (_) {
                _persist();
                return false;
              },
              child: SingleChildScrollView(
                controller: _scroll,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  14,
                  12,
                  14,
                  screenBottomInset(context, extra: 24),
                ),
                child: _KahfText(surah: data, fontSize: fontSize),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _KahfText extends StatelessWidget {
  const _KahfText({required this.surah, required this.fontSize});

  final Surah surah;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gold = isDark ? const Color(0xFFC9A961) : const Color(0xFF9A7B2F);
    final paper = isDark ? const Color(0xFF0E2328) : const Color(0xFFFFFBF0);
    final ink = isDark ? const Color(0xFFEDEAE0) : const Color(0xFF1B1A17);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: gold.withValues(alpha: 0.55), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SurahBanner(surah: surah, gold: gold),
          Text(
            '${surah.revelationType == 'Meccan' ? 'مكية' : 'مدنية'} · '
            '${arNum(surah.ayahCount)} آية · الجزء ${arNum(surah.ayahs.first.juz)}',
            textAlign: TextAlign.center,
            style: TextStyle(color: gold, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            kBismillah,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: kQuranFont,
              fontSize: fontSize + 2,
              height: 2.1,
              color: ink,
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                for (final ayah in surah.ayahs) ...[
                  TextSpan(text: ayah.text),
                  const TextSpan(text: ' '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: AyahMarker(
                      number: ayah.number,
                      color: gold,
                      highlighted: false,
                    ),
                  ),
                  const TextSpan(text: ' '),
                ],
              ],
            ),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: kQuranFont,
              fontSize: fontSize,
              height: 2.15,
              color: ink,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'صدق الله العظيم',
              style: TextStyle(
                fontFamily: kQuranFont,
                fontSize: 24,
                color: gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
