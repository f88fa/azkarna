import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/shared_preferences_provider.dart';
import '../../data/datasources/adhan_prayer_calculator.dart';
import '../../data/datasources/prayer_offsets_local_data_source.dart';
import '../../data/repositories/prayer_times_repository_impl.dart';
import '../../domain/entities/prayer_location.dart';
import '../../domain/entities/prayer_times.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../../domain/usecases/get_today_prayer_times.dart';

final prayerLocationProvider = Provider<PrayerLocation>(
  (ref) => PrayerLocation.hail,
);

final prayerOffsetsLocalDataSourceProvider =
    Provider<PrayerOffsetsLocalDataSource>(
      (ref) =>
          PrayerOffsetsLocalDataSource(ref.watch(sharedPreferencesProvider)),
    );

/// Manual per-prayer minute offsets chosen in Settings.
final prayerOffsetsProvider =
    NotifierProvider<PrayerOffsetsNotifier, PrayerOffsets>(
      PrayerOffsetsNotifier.new,
    );

class PrayerOffsetsNotifier extends Notifier<PrayerOffsets> {
  @override
  PrayerOffsets build() =>
      ref.watch(prayerOffsetsLocalDataSourceProvider).load();

  Future<void> change(Prayer prayer, int delta) async {
    final next = state.withOffset(prayer, state.of(prayer) + delta);
    if (next == state) return;
    state = next;
    await ref
        .read(prayerOffsetsLocalDataSourceProvider)
        .save(prayer, next.of(prayer));
  }

  Future<void> reset(Prayer prayer) async {
    if (state.of(prayer) == 0) return;
    state = state.withOffset(prayer, 0);
    await ref.read(prayerOffsetsLocalDataSourceProvider).save(prayer, 0);
  }
}

final prayerTimesRepositoryProvider = Provider<PrayerTimesRepository>(
  (ref) => PrayerTimesRepositoryImpl(
    const AdhanPrayerCalculator(),
    ref.watch(prayerOffsetsProvider),
  ),
);

final getTodayPrayerTimesProvider = Provider<GetTodayPrayerTimes>(
  (ref) => GetTodayPrayerTimes(ref.watch(prayerTimesRepositoryProvider)),
);

final prayerTimesProvider = FutureProvider<PrayerTimes>((ref) {
  final location = ref.watch(prayerLocationProvider);
  return ref.watch(getTodayPrayerTimesProvider).call(location);
});
