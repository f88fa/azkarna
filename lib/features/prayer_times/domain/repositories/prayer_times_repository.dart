import '../entities/prayer_location.dart';
import '../entities/prayer_times.dart';

abstract interface class PrayerTimesRepository {
  /// Throws a `Failure` on error.
  Future<PrayerTimes> getTodayPrayerTimes(PrayerLocation location);

  /// Prayer times for today and the following days, [days] entries at most.
  Future<List<PrayerTimes>> getUpcomingPrayerTimes(
    PrayerLocation location, {
    int days = 7,
  });
}
