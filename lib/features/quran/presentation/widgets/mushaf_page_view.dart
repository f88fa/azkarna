import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/arabic_format.dart';
import '../../../khatmah/domain/entities/khatmah_progress.dart';
import '../../domain/entities/quran_index.dart';
import '../../domain/entities/surah.dart';

const String kQuranFont = 'AmiriQuran';
const String kBismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

/// One printed Mushaf page: ayahs in mushaf order with the end-of-ayah
/// ornament carrying the ayah number, surah headings and the page number.
class MushafPageView extends StatefulWidget {
  const MushafPageView({
    super.key,
    required this.page,
    required this.bookmark,
    required this.onAyahSelected,
    this.bottomInset = 16,
  });

  final MushafPage page;
  final Bookmark? bookmark;
  final void Function(Surah surah, Ayah ayah) onAyahSelected;
  final double bottomInset;

  @override
  State<MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<MushafPageView> {
  /// One tap recognizer per ayah, keyed `surah:ayah`.
  final Map<String, TapGestureRecognizer> _taps = {};

  @override
  void initState() {
    super.initState();
    for (final segment in widget.page.segments) {
      for (final ayah in segment.ayahs) {
        _taps['${segment.surah.number}:${ayah.number}'] = TapGestureRecognizer()
          ..onTap = () => widget.onAyahSelected(segment.surah, ayah);
      }
    }
  }

  @override
  void dispose() {
    for (final recognizer in _taps.values) {
      recognizer.dispose();
    }
    super.dispose();
  }

  bool _isMarked(Surah surah, Ayah ayah) =>
      widget.bookmark?.surahNumber == surah.number &&
      widget.bookmark?.ayahNumber == ayah.number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final gold = isDark ? const Color(0xFFC9A961) : const Color(0xFF9A7B2F);
    final paper = isDark ? const Color(0xFF0E2328) : const Color(0xFFFFFBF0);
    final ink = isDark ? const Color(0xFFEDEAE0) : const Color(0xFF1B1A17);
    final page = widget.page;

    final bookmarkHere = page.segments.any(
      (s) => s.ayahs.any((a) => _isMarked(s.surah, a)),
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(14, 6, 14, widget.bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: gold.withValues(alpha: 0.55), width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'الجزء ${arNum(page.juz)}',
                  style: TextStyle(
                    color: gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (bookmarkHere)
                  Icon(Icons.bookmark_rounded, size: 20, color: primary),
              ],
            ),
            const SizedBox(height: 6),
            for (final segment in page.segments) ...[
              if (segment.startsSurah)
                SurahBanner(surah: segment.surah, gold: gold),
              if (segment.startsSurah && segment.surah.hasBismillahHeader)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    kBismillah,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: kQuranFont,
                      fontSize: 26,
                      height: 2,
                      color: ink,
                    ),
                  ),
                ),
              Text.rich(
                TextSpan(
                  children: [
                    for (final ayah in segment.ayahs) ...[
                      TextSpan(
                        text: ayah.text,
                        recognizer:
                            _taps['${segment.surah.number}:${ayah.number}'],
                        style: _isMarked(segment.surah, ayah)
                            ? TextStyle(
                                backgroundColor: primary.withValues(alpha: 0.2),
                              )
                            : null,
                      ),
                      const TextSpan(text: ' '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: AyahMarker(
                          number: ayah.number,
                          color: gold,
                          highlighted: _isMarked(segment.surah, ayah),
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
                  fontSize: 24,
                  height: 2.0,
                  color: ink,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: gold.withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  arNum(page.number),
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SurahBanner extends StatelessWidget {
  const SurahBanner({super.key, required this.surah, required this.gold});

  final Surah surah;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: gold.withValues(alpha: 0.7)),
      ),
      child: Text(
        'سورة ${surah.name}',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: kQuranFont,
          fontSize: 26,
          color: gold,
          height: 1.5,
        ),
      ),
    );
  }
}

/// The round ornament that closes each ayah and carries its number.
class AyahMarker extends StatelessWidget {
  const AyahMarker({
    super.key,
    required this.number,
    required this.color,
    required this.highlighted,
  });

  final int number;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final digits = arNum(number);
    final size = digits.length > 2 ? 34.0 : 30.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: highlighted ? color.withValues(alpha: 0.25) : null,
        border: Border.all(color: color, width: 1.3),
      ),
      child: Text(
        digits,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          color: color,
          fontSize: digits.length > 2 ? 12 : 14,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}
