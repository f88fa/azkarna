import '../../domain/entities/prayer_times.dart';

class PrayerTimesModel {
  const PrayerTimesModel({
    required this.location,
    required this.timeZone,
    required this.date,
    required this.hijriDate,
    required this.times,
  });

  final String location;
  final String timeZone;
  final DateTime date;
  final String hijriDate;
  final Map<Prayer, DateTime> times;

  static const Map<Prayer, String> _apiKeys = {
    Prayer.fajr: 'Fajr',
    Prayer.sunrise: 'Sunrise',
    Prayer.dhuhr: 'Dhuhr',
    Prayer.asr: 'Asr',
    Prayer.maghrib: 'Maghrib',
    Prayer.isha: 'Isha',
  };

  /// Parses an Aladhan `timingsByCity` response. Throws [FormatException]
  /// when the payload does not have the expected shape.
  factory PrayerTimesModel.fromJson(
    Map<String, dynamic> json, {
    required String location,
    required String fallbackTimeZone,
  }) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Missing "data" object');
    }
    return PrayerTimesModel.fromDayJson(
      data,
      location: location,
      fallbackTimeZone: fallbackTimeZone,
    );
  }

  /// Parses a single day entry (`data` of `timingsByCity`, or one element of
  /// the `calendarByCity` `data` list).
  factory PrayerTimesModel.fromDayJson(
    Map<String, dynamic> data, {
    required String location,
    required String fallbackTimeZone,
  }) {
    final timings = data['timings'];
    if (timings is! Map<String, dynamic>) {
      throw const FormatException('Missing "timings" object');
    }

    final date = _parseGregorian(data['date']) ?? DateTime.now();
    final day = DateTime(date.year, date.month, date.day);

    final times = <Prayer, DateTime>{};
    for (final entry in _apiKeys.entries) {
      times[entry.key] = _parseTime(timings[entry.value], day, entry.value);
    }

    final meta = data['meta'];
    final metaZone = meta is Map<String, dynamic> ? meta['timezone'] : null;

    return PrayerTimesModel(
      location: location,
      timeZone: metaZone is String && metaZone.isNotEmpty
          ? metaZone
          : fallbackTimeZone,
      date: day,
      hijriDate: _parseHijri(data['date']),
      times: times,
    );
  }

  /// Restores a model previously written by [toCacheJson].
  /// Throws [FormatException] for malformed payloads.
  factory PrayerTimesModel.fromCacheJson(Map<String, dynamic> json) {
    final location = json['location'];
    final timeZone = json['time_zone'];
    final date = json['date'];
    final times = json['times'];
    if (location is! String ||
        timeZone is! String ||
        date is! String ||
        times is! Map<String, dynamic>) {
      throw const FormatException('Invalid cached prayer times');
    }

    final parsed = <Prayer, DateTime>{};
    for (final prayer in Prayer.values) {
      final value = times[prayer.name];
      final time = value is String ? DateTime.tryParse(value) : null;
      if (time == null) {
        throw FormatException('Invalid cached time for ${prayer.name}');
      }
      parsed[prayer] = time;
    }

    return PrayerTimesModel(
      location: location,
      timeZone: timeZone,
      date: DateTime.parse(date),
      hijriDate: json['hijri_date'] as String? ?? '',
      times: parsed,
    );
  }

  Map<String, dynamic> toCacheJson() => {
    'location': location,
    'time_zone': timeZone,
    'date': date.toIso8601String(),
    'hijri_date': hijriDate,
    'times': {
      for (final entry in times.entries)
        entry.key.name: entry.value.toIso8601String(),
    },
  };

  PrayerTimes toEntity({bool isCached = false}) => PrayerTimes(
    isCached: isCached,
    location: location,
    timeZone: timeZone,
    date: date,
    hijriDate: hijriDate,
    times: times,
  );

  // Values look like "05:12" or "05:12 (+03)".
  static DateTime _parseTime(Object? raw, DateTime day, String name) {
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch('$raw');
    if (match == null) throw FormatException('Invalid time for $name: $raw');
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) {
      throw FormatException('Out-of-range time for $name: $raw');
    }
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  // Gregorian date looks like "17-10-2026" (DD-MM-YYYY).
  static DateTime? _parseGregorian(Object? date) {
    if (date is! Map<String, dynamic>) return null;
    final gregorian = date['gregorian'];
    if (gregorian is! Map<String, dynamic>) return null;
    final parts = '${gregorian['date']}'.split('-');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  static String _parseHijri(Object? date) {
    if (date is! Map<String, dynamic>) return '';
    final hijri = date['hijri'];
    if (hijri is! Map<String, dynamic>) return '';
    final month = hijri['month'];
    final monthName = month is Map<String, dynamic> ? month['en'] : null;
    final day = hijri['day'];
    final year = hijri['year'];
    if (day == null || monthName == null || year == null) return '';
    return '$day $monthName $year AH';
  }
}
