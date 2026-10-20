import 'dart:convert';
import 'dart:io';

import 'package:azkarna/core/storage/shared_preferences_provider.dart';
import 'package:azkarna/features/khatmah/domain/entities/khatmah_progress.dart';
import 'package:azkarna/features/prayer_times/data/datasources/adhan_prayer_calculator.dart';
import 'package:azkarna/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:azkarna/features/prayer_times/domain/entities/prayer_times.dart';
import 'package:azkarna/features/quran/domain/entities/quran_index.dart';
import 'package:azkarna/features/quran/domain/entities/surah.dart';
import 'package:azkarna/features/widgets/data/widget_bridge.dart';
import 'package:azkarna/features/widgets/data/widget_payload.dart';
import 'package:azkarna/features/widgets/presentation/providers/widget_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBridge implements WidgetBridge {
  final List<String> saved = [];

  @override
  bool get isSupported => true;

  @override
  Future<void> save(String json) async => saved.add(json);
}

List<PrayerTimes> _days(int from, int to) {
  const location = PrayerLocation.hail;
  final today = location.today();
  return [
    for (var i = from; i < to; i++)
      const AdhanPrayerCalculator().calculate(
        location,
        DateTime(today.year, today.month, today.day + i),
        const PrayerOffsets(),
      ),
  ];
}

QuranIndex _tinyQuran() => QuranIndex([
  Surah(
    number: 2,
    name: 'البقرة',
    englishName: 'Al-Baqarah',
    revelationType: 'Medinan',
    ayahs: const [
      Ayah(number: 1, text: 'a', page: 2, juz: 1),
      Ayah(number: 2, text: 'b', page: 2, juz: 1),
      Ayah(number: 3, text: 'c', page: 3, juz: 1),
    ],
  ),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WidgetPayload', () {
    test('lists every prayer moment in time order as Unix seconds', () {
      final days = _days(-1, 14);
      final payload = WidgetPayload.build(
        location: PrayerLocation.hail,
        days: days,
      );

      expect(payload['city'], 'حائل');
      expect(payload['utcOffset'], 3 * 3600);

      final events = (payload['events']! as List).cast<Map<String, Object>>();
      expect(events, hasLength(days.length * 6));

      final times = [for (final e in events) e['t']! as int];
      expect([...times]..sort(), times);

      // First event is yesterday's Fajr; converting back gives the same
      // wall-clock time in the location's zone.
      expect(events.first['p'], 'fajr');
      final back = DateTime.fromMillisecondsSinceEpoch(
        times.first * 1000,
        isUtc: true,
      ).add(PrayerLocation.hail.utcOffset);
      final fajr = days.first.times[Prayer.fajr]!;
      expect(
        [back.year, back.month, back.day, back.hour, back.minute],
        [fajr.year, fajr.month, fajr.day, fajr.hour, fajr.minute],
      );
      expect(payload.containsKey('khatmah'), isFalse);
    });

    test('maps the Khatmah progress, with surah name and page', () {
      final payload = WidgetPayload.build(
        location: PrayerLocation.hail,
        days: _days(0, 1),
        quran: _tinyQuran(),
        khatmah: KhatmahProgress(
          bookmark: const Bookmark(surahNumber: 2, ayahNumber: 3),
          dailyTarget: 30,
          todayRead: 7,
          progressDate: DateTime(2026, 3, 5),
        ),
      );

      expect(payload['khatmah'], {
        'target': 30,
        'read': 7,
        'readDay': '2026-03-05',
        'surah': 'البقرة',
        'ayah': 3,
        'page': 3,
      });
    });

    test('works before the first reading', () {
      final payload = WidgetPayload.build(
        location: PrayerLocation.hail,
        days: _days(0, 1),
        khatmah: const KhatmahProgress(),
        now: DateTime(2026, 1, 9),
      );
      final khatmah = payload['khatmah']! as Map;
      expect(khatmah['readDay'], '2026-01-09');
      expect(khatmah.containsKey('surah'), isFalse);
      expect(khatmah.containsKey('page'), isFalse);
    });

    test('encodes to JSON the native side can decode', () {
      final payload = WidgetPayload.build(
        location: PrayerLocation.hail,
        days: _days(0, 2),
      );
      final decoded = jsonDecode(WidgetPayload.encode(payload)) as Map;
      expect(decoded['v'], 1);
      expect((decoded['events'] as List), hasLength(12));
    });
  });

  group('syncHomeWidgets', () {
    test('saves the next two weeks plus yesterday to the bridge', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final bridge = _FakeBridge();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          widgetBridgeProvider.overrideWithValue(bridge),
        ],
      );
      addTearDown(container.dispose);

      await container.read(syncHomeWidgetsProvider)();

      expect(bridge.saved, hasLength(1));
      final payload = jsonDecode(bridge.saved.single) as Map;
      expect(
        (payload['events'] as List).length,
        (WidgetPayload.daysBefore + WidgetPayload.daysAhead) * 6,
      );
      expect(payload['khatmah'], isNotNull);
    });

    test('does nothing where widgets are not supported', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          widgetBridgeProvider.overrideWithValue(const NoopWidgetBridge()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(syncHomeWidgetsProvider)();
      expect(const NoopWidgetBridge().isSupported, isFalse);
    });
  });

  group('iOS project', () {
    test('widget extension is wired into the Runner project', () {
      final pbxproj = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      expect(pbxproj, contains('com.alray.azkarna.AwwabWidgets'));
      expect(pbxproj, contains('Embed Foundation Extensions'));
      expect(pbxproj, contains('Runner/Runner.entitlements'));
      for (final file in [
        'AwwabWidgetBundle.swift',
        'WidgetData.swift',
        'WidgetTheme.swift',
        'PrayerWidgets.swift',
        'ReadingWidgets.swift',
      ]) {
        expect(pbxproj, contains('$file in Sources'));
        expect(File('ios/AwwabWidgets/$file').existsSync(), isTrue);
      }
    });

    test('app and widgets share the same App Group', () {
      const group = 'group.com.alray.azkarna';
      for (final path in [
        'ios/Runner/Runner.entitlements',
        'ios/AwwabWidgets/AwwabWidgets.entitlements',
        'ios/Runner/AppDelegate.swift',
        'ios/AwwabWidgets/WidgetData.swift',
      ]) {
        expect(File(path).readAsStringSync(), contains(group), reason: path);
      }
    });
  });
}
