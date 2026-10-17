class PrayerLocation {
  const PrayerLocation({
    required this.city,
    required this.country,
    required this.timeZone,
  });

  final String city;
  final String country;

  /// IANA time zone identifier, e.g. `Asia/Riyadh`.
  final String timeZone;

  static const PrayerLocation hail = PrayerLocation(
    city: 'Hail',
    country: 'Saudi Arabia',
    timeZone: 'Asia/Riyadh',
  );
}
