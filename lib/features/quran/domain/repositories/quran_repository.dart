import '../entities/surah.dart';

abstract interface class QuranRepository {
  /// Throws a `Failure` on error.
  Future<List<Surah>> getSurahs();
  Future<Surah> getSurah(int number);
}
