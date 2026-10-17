import 'package:azkarna/features/moon/domain/moon_phase.dart';
import 'package:azkarna/features/prayer_times/data/datasources/adhan_prayer_calculator.dart';
import 'package:azkarna/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:azkarna/features/prayer_times/domain/entities/prayer_times.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  const calculator = AdhanPrayerCalculator();
  final day = DateTime(2026, 10, 17);

  test('Umm Al-Qura times for Hail are computed offline', () {
    final t = calculator.calculate(
      PrayerLocation.hail,
      day,
      const PrayerOffsets(),
    );
    for (final p in Prayer.values) {
      // ignore: avoid_print
      print('${p.name}: ${t.times[p]}');
    }
    final order = [for (final p in Prayer.values) t.times[p]!];
    for (var i = 1; i < order.length; i++) {
      expect(order[i].isAfter(order[i - 1]), isTrue);
    }
    // Isha is 90 minutes after Maghrib outside Ramadan.
    expect(
      t.times[Prayer.isha]!.difference(t.times[Prayer.maghrib]!).inMinutes,
      90,
    );
    expect(t.times[Prayer.dhuhr]!.hour, inInclusiveRange(11, 12));
  });

  test('manual offsets shift each prayer individually by whole minutes', () {
    final base = calculator.calculate(
      PrayerLocation.hail,
      day,
      const PrayerOffsets(),
    );
    final shifted = calculator.calculate(
      PrayerLocation.hail,
      day,
      const PrayerOffsets({Prayer.asr: 1, Prayer.fajr: -1}),
    );
    expect(
      shifted.times[Prayer.asr]!.difference(base.times[Prayer.asr]!).inMinutes,
      1,
    );
    expect(
      shifted.times[Prayer.fajr]!
          .difference(base.times[Prayer.fajr]!)
          .inMinutes,
      -1,
    );
    expect(shifted.times[Prayer.dhuhr], base.times[Prayer.dhuhr]);
  });

  test('moon phase: known new and full moons', () {
    // New moon 2026-02-17, full moon 2026-03-03 (approx).
    expect(
      MoonPhase.at(DateTime.utc(2026, 2, 17, 12)).illumination,
      lessThan(0.05),
    );
    expect(
      MoonPhase.at(DateTime.utc(2026, 3, 3, 12)).illumination,
      greaterThan(0.95),
    );
  });
}
