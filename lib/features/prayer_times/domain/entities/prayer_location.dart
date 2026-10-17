class PrayerLocation {
  const PrayerLocation({
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.timeZone,
    required this.utcOffset,
  });

  /// Display names (Arabic).
  final String city;
  final String country;

  final double latitude;
  final double longitude;

  /// IANA time zone identifier, e.g. `Asia/Riyadh`.
  final String timeZone;

  /// Fixed offset of [timeZone] from UTC (Saudi Arabia has no DST).
  final Duration utcOffset;

  String get displayName => '$city، $country';

  /// Current wall-clock time at this location, independent of the device
  /// time zone.
  DateTime wallClockNow() {
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

  /// Today's calendar date at this location (midnight, local fields).
  DateTime today() {
    final now = wallClockNow();
    return DateTime(now.year, now.month, now.day);
  }

  static const PrayerLocation hail = PrayerLocation(
    city: 'حائل',
    country: 'المملكة العربية السعودية',
    latitude: 27.5114,
    longitude: 41.7208,
    timeZone: 'Asia/Riyadh',
    utcOffset: Duration(hours: 3),
  );
}
