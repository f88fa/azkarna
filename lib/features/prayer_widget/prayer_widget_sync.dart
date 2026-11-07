import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../prayer_times/domain/entities/prayer_location.dart';
import '../prayer_times/domain/entities/prayer_times.dart';
import '../prayer_times/domain/repositories/prayer_times_repository.dart';

/// Hands the coming prayer times to the iOS lock-screen / home-screen widget
/// (WidgetKit extension "PrayerWidget"), which reads them from the shared
/// App Group and works out the countdown and elapsed time by itself.
class PrayerWidgetSync {
  const PrayerWidgetSync(this._repository);

  static const MethodChannel _channel = MethodChannel('awwab/widget');

  /// Enough days that the widget keeps working if the app is not opened for
  /// a while.
  static const int daysAhead = 14;

  final PrayerTimesRepository _repository;

  Future<void> call(PrayerLocation location) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final days = await _repository.getUpcomingPrayerTimes(
        location,
        days: daysAhead,
      );
      await _channel.invokeMethod<bool>('update', {
        'prayers': jsonEncode(encode(days)),
        'city': location.city,
      });
    } catch (_) {
      // The widget is best-effort and must never break the app.
    }
  }

  /// `[{n: 'asr', l: 'العصر', t: <epoch seconds>}, …]` for the five prayers.
  @visibleForTesting
  static List<Map<String, Object>> encode(List<PrayerTimes> days) => [
    for (final day in days)
      for (final prayer in Prayer.adhanPrayers)
        if (day.times[prayer] case final time?)
          {
            'n': prayer.name,
            'l': prayer.label,
            // Times are wall-clock at the location; turn them into instants.
            't':
                DateTime.utc(
                  time.year,
                  time.month,
                  time.day,
                  time.hour,
                  time.minute,
                ).subtract(day.utcOffset).millisecondsSinceEpoch ~/
                1000,
          },
  ];
}
