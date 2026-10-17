import 'package:adhan/adhan.dart' as adhan;
import 'package:hijri/hijri_calendar.dart';

import '../../../../core/utils/arabic_format.dart';
import '../../domain/entities/prayer_location.dart';
import '../../domain/entities/prayer_times.dart';

/// Offline prayer time calculation using the `adhan` package.
///
/// The method is strictly Umm Al-Qura (Makkah). Calculated times are rounded
/// to the nearest minute by the library (not truncated), then manual offsets
/// are added.
class AdhanPrayerCalculator {
  const AdhanPrayerCalculator();

  PrayerTimes calculate(
    PrayerLocation location,
    DateTime date,
    PrayerOffsets offsets,
  ) {
    final day = DateTime(date.year, date.month, date.day);
    final hijri = HijriCalendar.fromDate(
      DateTime(day.year, day.month, day.day, 12),
    );

    final params = adhan.CalculationMethod.umm_al_qura.getParameters();
    // Umm Al-Qura: Isha is 90 minutes after Maghrib, 120 during Ramadan.
    final ramadanIsha = hijri.hMonth == 9 ? 30 : 0;
    params.adjustments
      ..fajr = offsets.of(Prayer.fajr)
      ..sunrise = offsets.of(Prayer.sunrise)
      ..dhuhr = offsets.of(Prayer.dhuhr)
      ..asr = offsets.of(Prayer.asr)
      ..maghrib = offsets.of(Prayer.maghrib)
      ..isha = offsets.of(Prayer.isha) + ramadanIsha;

    final result = adhan.PrayerTimes(
      adhan.Coordinates(location.latitude, location.longitude),
      adhan.DateComponents(day.year, day.month, day.day),
      params,
      utcOffset: location.utcOffset,
    );

    // With `utcOffset` the library returns UTC DateTimes already shifted to
    // the location's wall clock; copy the fields into plain local DateTimes.
    DateTime wall(DateTime t) =>
        DateTime(t.year, t.month, t.day, t.hour, t.minute);

    return PrayerTimes(
      location: location.displayName,
      timeZone: location.timeZone,
      utcOffset: location.utcOffset,
      date: day,
      hijriDate:
          '${arNum(hijri.hDay)} ${hijriMonthsAr[hijri.hMonth - 1]} ${arPlain(hijri.hYear)} هـ',
      times: {
        Prayer.fajr: wall(result.fajr),
        Prayer.sunrise: wall(result.sunrise),
        Prayer.dhuhr: wall(result.dhuhr),
        Prayer.asr: wall(result.asr),
        Prayer.maghrib: wall(result.maghrib),
        Prayer.isha: wall(result.isha),
      },
    );
  }
}
