import '../../../../core/error/failures.dart';
import '../../domain/entities/prayer_location.dart';
import '../../domain/entities/prayer_times.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../datasources/adhan_prayer_calculator.dart';

class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  const PrayerTimesRepositoryImpl(this._calculator, this._offsets);

  final AdhanPrayerCalculator _calculator;
  final PrayerOffsets _offsets;

  @override
  Future<PrayerTimes> getTodayPrayerTimes(PrayerLocation location) =>
      _guard(() => _calculator.calculate(location, location.today(), _offsets));

  @override
  Future<List<PrayerTimes>> getUpcomingPrayerTimes(
    PrayerLocation location, {
    int days = 7,
  }) => _guard(() {
    final today = location.today();
    return [
      for (var i = 0; i < days; i++)
        _calculator.calculate(
          location,
          DateTime(today.year, today.month, today.day + i),
          _offsets,
        ),
    ];
  });

  Future<T> _guard<T>(T Function() action) async {
    try {
      return action();
    } on Failure {
      rethrow;
    } catch (_) {
      throw const UnknownFailure();
    }
  }
}
