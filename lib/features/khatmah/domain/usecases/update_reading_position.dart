import '../../../quran/domain/entities/surah.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../entities/khatmah_progress.dart';
import '../repositories/khatmah_repository.dart';

/// Saves a new bookmark and credits the ayahs read since the previous one
/// toward today's goal.
class UpdateReadingPosition {
  const UpdateReadingPosition(this._khatmah, this._quran);

  final KhatmahRepository _khatmah;
  final QuranRepository _quran;

  Future<void> call(Bookmark bookmark) async {
    final progress = await _khatmah.getProgress();
    final surahs = await _quran.getSurahs();

    final previous = progress.bookmark;
    final advanced = previous == null
        ? 0
        : (_absoluteIndex(surahs, bookmark) - _absoluteIndex(surahs, previous))
              .clamp(0, 1 << 30);

    await _khatmah.saveBookmark(bookmark, ayahsAdvanced: advanced);
  }

  int _absoluteIndex(List<Surah> surahs, Bookmark bookmark) {
    var index = bookmark.ayahNumber;
    for (final surah in surahs) {
      if (surah.number < bookmark.surahNumber) index += surah.ayahCount;
    }
    return index;
  }
}
