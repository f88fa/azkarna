enum Prayer {
  fajr('Fajr'),
  sunrise('Sunrise'),
  dhuhr('Dhuhr'),
  asr('Asr'),
  maghrib('Maghrib'),
  isha('Isha');

  const Prayer(this.label);
  final String label;

  /// Prayers that trigger an Adhan (sunrise is informational only).
  static const List<Prayer> adhanPrayers = [fajr, dhuhr, asr, maghrib, isha];
}

class PrayerTimes {
  const PrayerTimes({
    required this.location,
    required this.timeZone,
    required this.date,
    required this.hijriDate,
    required this.times,
    this.isCached = false,
  });

  /// True when served from the offline cache instead of the network.
  final bool isCached;

  final String location;

  /// IANA time zone in which [times] are expressed.
  final String timeZone;
  final DateTime date;
  final String hijriDate;
  final Map<Prayer, DateTime> times;

  /// The first prayer still ahead of [now], or null once Isha has passed.
  Prayer? nextPrayer(DateTime now) {
    for (final prayer in Prayer.values) {
      final time = times[prayer];
      if (time != null && time.isAfter(now)) return prayer;
    }
    return null;
  }
}
