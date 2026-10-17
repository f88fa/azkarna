import '../../../../core/error/failures.dart';
import '../../domain/entities/khatmah_progress.dart';
import '../../domain/repositories/khatmah_repository.dart';
import '../datasources/khatmah_local_data_source.dart';
import '../models/khatmah_model.dart';

class KhatmahRepositoryImpl implements KhatmahRepository {
  KhatmahRepositoryImpl(this._local, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final KhatmahLocalDataSource _local;
  final DateTime Function() _clock;

  DateTime get _today {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Future<KhatmahProgress> getProgress() => _guard(_load);

  @override
  Future<void> saveBookmark(Bookmark bookmark, {int ayahsAdvanced = 0}) =>
      _guard(() async {
        final current = await _load();
        await _save(
          current.copyWith(
            bookmark: bookmark,
            todayRead: current.todayRead + ayahsAdvanced,
          ),
        );
      });

  @override
  Future<void> saveDailyTarget(int ayahs) => _guard(() async {
    final current = await _load();
    await _save(current.copyWith(dailyTarget: ayahs < 1 ? 1 : ayahs));
  });

  /// Loads progress, resetting the daily counter when the day has changed.
  Future<KhatmahProgress> _load() async {
    final stored = await _local.getProgress();
    final today = _today;
    if (stored.progressDate == today) return stored;
    return stored.copyWith(todayRead: 0, progressDate: today);
  }

  Future<void> _save(KhatmahProgress progress) =>
      _local.saveProgress(KhatmahModel.fromEntity(progress));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Failure {
      rethrow;
    } catch (e) {
      throw CacheFailure(e.toString());
    }
  }
}
