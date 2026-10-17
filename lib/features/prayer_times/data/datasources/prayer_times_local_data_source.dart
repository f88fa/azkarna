import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/prayer_location.dart';
import '../models/prayer_times_model.dart';

abstract interface class PrayerTimesLocalDataSource {
  /// Last successfully fetched times for [location], or null.
  Future<PrayerTimesModel?> getCached(PrayerLocation location);
  Future<void> cache(PrayerLocation location, PrayerTimesModel times);
}

class SharedPrefsPrayerTimesDataSource implements PrayerTimesLocalDataSource {
  const SharedPrefsPrayerTimesDataSource(this._prefs);

  final SharedPreferences _prefs;

  String _key(PrayerLocation l) => 'prayer_times_cache_${l.country}_${l.city}';

  @override
  Future<PrayerTimesModel?> getCached(PrayerLocation location) async {
    final raw = _prefs.getString(_key(location));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return PrayerTimesModel.fromCacheJson(decoded);
      }
    } on FormatException {
      // Corrupted cache is treated as a miss.
    }
    return null;
  }

  @override
  Future<void> cache(PrayerLocation location, PrayerTimesModel times) async {
    await _prefs.setString(_key(location), jsonEncode(times.toCacheJson()));
  }
}
