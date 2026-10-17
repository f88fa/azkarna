import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/prayer_times.dart';

class PrayerOffsetsLocalDataSource {
  const PrayerOffsetsLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  String _key(Prayer prayer) => 'prayer_offset_${prayer.name}';

  PrayerOffsets load() => PrayerOffsets({
    for (final prayer in Prayer.values)
      prayer: (_prefs.getInt(_key(prayer)) ?? 0).clamp(
        -PrayerOffsets.maxMinutes,
        PrayerOffsets.maxMinutes,
      ),
  });

  Future<void> save(Prayer prayer, int minutes) async {
    await _prefs.setInt(_key(prayer), minutes);
  }
}
