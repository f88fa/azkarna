import 'package:azkarna/features/prayer_times/domain/entities/prayer_times.dart';
import 'package:azkarna/features/prayer_widget/prayer_widget_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encodes the five prayers as UTC instants, skipping sunrise', () {
    final slots = PrayerWidgetSync.encode([
      PrayerTimes(
        location: 'حائل',
        timeZone: 'Asia/Riyadh',
        utcOffset: const Duration(hours: 3),
        date: DateTime(2030, 1, 1),
        hijriDate: '',
        times: {
          Prayer.fajr: DateTime(2030, 1, 1, 5, 30),
          Prayer.sunrise: DateTime(2030, 1, 1, 6, 50),
          Prayer.isha: DateTime(2030, 1, 1, 19, 0),
        },
      ),
    ]);

    expect(slots.map((s) => s['n']), ['fajr', 'isha']);
    expect(slots.first['l'], 'الفجر');
    // 05:30 Riyadh time = 02:30 UTC.
    expect(
      slots.first['t'],
      DateTime.utc(2030, 1, 1, 2, 30).millisecondsSinceEpoch ~/ 1000,
    );
  });
}
