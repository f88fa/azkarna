import 'dart:convert';

import '../../khatmah/domain/entities/khatmah_progress.dart';
import '../../prayer_times/domain/entities/prayer_location.dart';
import '../../prayer_times/domain/entities/prayer_times.dart';
import '../../quran/domain/entities/quran_index.dart';

/// What the iOS widgets (WidgetKit extension in `ios/AwwabWidgets`) show.
///
/// The widgets cannot run Dart, so the app hands them plain data: every prayer
/// moment of the next days as a Unix timestamp (they build their own timeline
/// and live countdown from it) and the Khatmah progress.
abstract final class WidgetPayload {
  /// Prayer days saved for the widgets, starting yesterday (the "previous
  /// prayer" before today's Fajr is yesterday's Isha).
  static const int daysBefore = 1;
  static const int daysAhead = 14;

  static const Map<Prayer, String> _keys = {
    Prayer.fajr: 'fajr',
    Prayer.sunrise: 'sunrise',
    Prayer.dhuhr: 'dhuhr',
    Prayer.asr: 'asr',
    Prayer.maghrib: 'maghrib',
    Prayer.isha: 'isha',
  };

  /// Builds the JSON-encodable map written to the shared App Group.
  static Map<String, Object?> build({
    required PrayerLocation location,
    required List<PrayerTimes> days,
    KhatmahProgress? khatmah,
    QuranIndex? quran,
    DateTime? now,
  }) {
    final events = <Map<String, Object>>[];
    for (final day in days) {
      for (final prayer in Prayer.values) {
        final wall = day.times[prayer];
        if (wall == null) continue;
        events.add({
          'p': _keys[prayer]!,
          't': _epochSeconds(wall, day.utcOffset),
        });
      }
    }
    events.sort((a, b) => (a['t']! as int).compareTo(b['t']! as int));

    return {
      'v': 1,
      'updated': (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000,
      'city': location.city,
      'utcOffset': location.utcOffset.inSeconds,
      'events': events,
      if (khatmah != null) 'khatmah': _khatmah(khatmah, quran, now),
    };
  }

  static String encode(Map<String, Object?> payload) => jsonEncode(payload);

  /// Wall-clock fields in the location's time zone -> Unix seconds.
  static int _epochSeconds(DateTime wall, Duration utcOffset) =>
      DateTime.utc(
        wall.year,
        wall.month,
        wall.day,
        wall.hour,
        wall.minute,
        wall.second,
      ).subtract(utcOffset).millisecondsSinceEpoch ~/
      1000;

  static Map<String, Object?> _khatmah(
    KhatmahProgress progress,
    QuranIndex? quran,
    DateTime? now,
  ) {
    final bookmark = progress.bookmark;
    final surah = bookmark == null ? null : quran?.surah(bookmark.surahNumber);
    return {
      'target': progress.dailyTarget,
      'read': progress.todayRead,
      // The day `read` belongs to; the widgets ignore it on any other day.
      'readDay': dayKey(progress.progressDate ?? now ?? DateTime.now()),
      if (surah != null) 'surah': surah.name,
      if (bookmark != null) 'ayah': bookmark.ayahNumber,
      if (bookmark != null && surah != null)
        'page': surah.pageOf(bookmark.ayahNumber),
    };
  }

  /// `yyyy-MM-dd` with Western digits (the widgets compare it as text).
  static String dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
