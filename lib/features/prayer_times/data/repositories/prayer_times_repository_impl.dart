import '../../../../core/error/failures.dart';
import '../../domain/entities/prayer_location.dart';
import '../../domain/entities/prayer_times.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../datasources/prayer_times_local_data_source.dart';
import '../datasources/prayer_times_remote_data_source.dart';
import '../models/prayer_times_model.dart';

class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  const PrayerTimesRepositoryImpl(this._remote, this._local);

  final PrayerTimesRemoteDataSource _remote;
  final PrayerTimesLocalDataSource _local;

  /// Fetches today's times; when offline or the API fails, falls back to
  /// the cached times if they are for today.
  @override
  Future<PrayerTimes> getTodayPrayerTimes(PrayerLocation location) async {
    try {
      final model = await _remote.fetchTimingsByCity(location);
      await _saveToCache(location, model);
      return model.toEntity();
    } on Failure {
      final cached = await _validCache(location);
      if (cached != null) return cached.toEntity(isCached: true);
      rethrow;
    } catch (_) {
      throw const UnknownFailure();
    }
  }

  @override
  Future<List<PrayerTimes>> getUpcomingPrayerTimes(
    PrayerLocation location, {
    int days = 7,
  }) => _guard(() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(Duration(days: days - 1));

    final months = <(int, int)>{
      (today.year, today.month),
      (end.year, end.month),
    };
    final all = <PrayerTimesModel>[];
    for (final (year, month) in months) {
      all.addAll(
        await _remote.fetchCalendarByCity(location, year: year, month: month),
      );
    }

    final upcoming =
        all
            .where((m) => !m.date.isBefore(today) && !m.date.isAfter(end))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return upcoming.map((m) => m.toEntity()).toList(growable: false);
  });

  Future<PrayerTimesModel?> _validCache(PrayerLocation location) async {
    try {
      final cached = await _local.getCached(location);
      if (cached == null) return null;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return cached.date == today ? cached : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(
    PrayerLocation location,
    PrayerTimesModel model,
  ) async {
    try {
      await _local.cache(location, model);
    } catch (_) {
      // Caching is best-effort and must not fail the request.
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Failure {
      rethrow;
    } catch (_) {
      throw const UnknownFailure();
    }
  }
}
