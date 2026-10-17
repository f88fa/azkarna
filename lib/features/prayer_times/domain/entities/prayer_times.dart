enum Prayer {
  fajr('الفجر'),
  sunrise('الشروق'),
  dhuhr('الظهر'),
  asr('العصر'),
  maghrib('المغرب'),
  isha('العشاء');

  const Prayer(this.label);
  final String label;

  /// Prayers that trigger an Adhan (sunrise is informational only).
  static const List<Prayer> adhanPrayers = [fajr, dhuhr, asr, maghrib, isha];
}

/// Manual per-prayer corrections, in whole minutes (e.g. `+1` / `-1`).
class PrayerOffsets {
  const PrayerOffsets([this.minutes = const {}]);

  static const int maxMinutes = 30;

  final Map<Prayer, int> minutes;

  int of(Prayer prayer) => minutes[prayer] ?? 0;

  PrayerOffsets withOffset(Prayer prayer, int value) =>
      PrayerOffsets({...minutes, prayer: value.clamp(-maxMinutes, maxMinutes)});

  @override
  bool operator ==(Object other) =>
      other is PrayerOffsets &&
      Prayer.values.every((p) => of(p) == other.of(p));

  @override
  int get hashCode => Object.hashAll(Prayer.values.map(of));
}

class PrayerTimes {
  const PrayerTimes({
    required this.location,
    required this.timeZone,
    required this.utcOffset,
    required this.date,
    required this.hijriDate,
    required this.times,
  });

  final String location;

  /// IANA time zone in which [times] are expressed.
  final String timeZone;
  final Duration utcOffset;
  final DateTime date;
  final String hijriDate;

  /// Wall-clock times in [timeZone] (the date/time fields are what matter).
  final Map<Prayer, DateTime> times;

  /// Current wall-clock time in [timeZone].
  DateTime get wallClockNow {
    final utc = DateTime.now().toUtc().add(utcOffset);
    return DateTime(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
    );
  }

  /// The first prayer still ahead of [now], or null once Isha has passed.
  Prayer? nextPrayer(DateTime now) {
    for (final prayer in Prayer.values) {
      final time = times[prayer];
      if (time != null && time.isAfter(now)) return prayer;
    }
    return null;
  }
}
