import '../entities/prayer_location.dart';
import '../entities/prayer_times.dart';
import '../repositories/prayer_times_repository.dart';

class GetTodayPrayerTimes {
  const GetTodayPrayerTimes(this._repository);

  final PrayerTimesRepository _repository;

  Future<PrayerTimes> call(PrayerLocation location) =>
      _repository.getTodayPrayerTimes(location);
}
