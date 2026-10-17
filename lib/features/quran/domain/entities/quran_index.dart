import 'surah.dart';

/// The ayahs of one surah that are printed on a given Mushaf page.
class PageSegment {
  const PageSegment({required this.surah, required this.ayahs});

  final Surah surah;
  final List<Ayah> ayahs;

  /// True when the surah's heading (and Basmalah) is printed on this page.
  bool get startsSurah => ayahs.first.number == 1;
}

class MushafPage {
  const MushafPage({
    required this.number,
    required this.juz,
    required this.segments,
  });

  final int number;
  final int juz;
  final List<PageSegment> segments;
}

/// Page/juz lookup built once from the full list of surahs.
class QuranIndex {
  QuranIndex(this.surahs) {
    final byPage = <int, Map<int, List<Ayah>>>{};
    for (final surah in surahs) {
      for (final ayah in surah.ayahs) {
        byPage
            .putIfAbsent(ayah.page, () => {})
            .putIfAbsent(surah.number, () => [])
            .add(ayah);
      }
    }

    final bySurah = {for (final s in surahs) s.number: s};
    final pages = <int, MushafPage>{};
    for (final entry in byPage.entries) {
      final segments = [
        for (final s in entry.value.entries)
          PageSegment(surah: bySurah[s.key]!, ayahs: s.value),
      ];
      pages[entry.key] = MushafPage(
        number: entry.key,
        juz: segments.first.ayahs.first.juz,
        segments: segments,
      );
    }
    _pages = pages;

    final juz = <int, ({int page, Surah surah, int ayah})>{};
    for (final surah in surahs) {
      for (final ayah in surah.ayahs) {
        juz.putIfAbsent(
          ayah.juz,
          () => (page: ayah.page, surah: surah, ayah: ayah.number),
        );
      }
    }
    _juzStarts = juz;
  }

  static const int pageCount = 604;
  static const int juzCount = 30;

  final List<Surah> surahs;
  late final Map<int, MushafPage> _pages;
  late final Map<int, ({int page, Surah surah, int ayah})> _juzStarts;

  MushafPage page(int number) {
    final page = _pages[number.clamp(1, pageCount)];
    if (page == null) throw StateError('Page $number is not available');
    return page;
  }

  /// Where [juz] (1–30) begins.
  ({int page, Surah surah, int ayah}) juzStart(int juz) => _juzStarts[juz]!;

  Surah? surah(int number) {
    for (final s in surahs) {
      if (s.number == number) return s;
    }
    return null;
  }

  /// Page for a saved position, or null if the surah is unknown.
  int? pageOf(int surahNumber, int ayah) => surah(surahNumber)?.pageOf(ayah);
}
