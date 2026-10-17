import '../../../../core/error/failures.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_local_data_source.dart';

class QuranRepositoryImpl implements QuranRepository {
  const QuranRepositoryImpl(this._local);

  final QuranLocalDataSource _local;

  @override
  Future<List<Surah>> getSurahs() async {
    try {
      return await _local.loadSurahs();
    } on Failure {
      rethrow;
    } on FormatException catch (e) {
      throw CacheFailure('Invalid Quran data: ${e.message}');
    } catch (_) {
      throw const UnknownFailure();
    }
  }

  @override
  Future<Surah> getSurah(int number) async {
    final surahs = await getSurahs();
    for (final surah in surahs) {
      if (surah.number == number) return surah;
    }
    throw CacheFailure('Surah $number is not available');
  }
}
