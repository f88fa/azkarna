import '../entities/khatmah_progress.dart';

abstract interface class KhatmahRepository {
  Future<KhatmahProgress> getProgress();

  /// Saves the reading position and adds [ayahsAdvanced] to today's total.
  Future<void> saveBookmark(Bookmark bookmark, {int ayahsAdvanced = 0});

  Future<void> saveDailyTarget(int ayahs);
}
