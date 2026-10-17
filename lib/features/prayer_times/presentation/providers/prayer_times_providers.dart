import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/http_client_provider.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../data/datasources/prayer_times_local_data_source.dart';
import '../../data/datasources/prayer_times_remote_data_source.dart';
import '../../data/repositories/prayer_times_repository_impl.dart';
import '../../domain/entities/prayer_location.dart';
import '../../domain/entities/prayer_times.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../../domain/usecases/get_today_prayer_times.dart';

final prayerLocationProvider = Provider<PrayerLocation>(
  (ref) => PrayerLocation.hail,
);

final prayerTimesRemoteDataSourceProvider =
    Provider<PrayerTimesRemoteDataSource>(
      (ref) =>
          AladhanPrayerTimesRemoteDataSource(ref.watch(httpClientProvider)),
    );

final prayerTimesLocalDataSourceProvider = Provider<PrayerTimesLocalDataSource>(
  (ref) =>
      SharedPrefsPrayerTimesDataSource(ref.watch(sharedPreferencesProvider)),
);

final prayerTimesRepositoryProvider = Provider<PrayerTimesRepository>(
  (ref) => PrayerTimesRepositoryImpl(
    ref.watch(prayerTimesRemoteDataSourceProvider),
    ref.watch(prayerTimesLocalDataSourceProvider),
  ),
);

final getTodayPrayerTimesProvider = Provider<GetTodayPrayerTimes>(
  (ref) => GetTodayPrayerTimes(ref.watch(prayerTimesRepositoryProvider)),
);

final prayerTimesProvider = FutureProvider<PrayerTimes>((ref) {
  final location = ref.watch(prayerLocationProvider);
  return ref.watch(getTodayPrayerTimesProvider).call(location);
});
