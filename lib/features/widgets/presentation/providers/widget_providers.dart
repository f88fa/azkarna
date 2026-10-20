import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../khatmah/presentation/providers/khatmah_providers.dart';
import '../../../prayer_times/data/datasources/adhan_prayer_calculator.dart';
import '../../../prayer_times/domain/entities/prayer_times.dart';
import '../../../prayer_times/presentation/providers/prayer_times_providers.dart';
import '../../../quran/presentation/providers/quran_providers.dart';
import '../../data/widget_bridge.dart';
import '../../data/widget_payload.dart';

final widgetBridgeProvider = Provider<WidgetBridge>(
  (ref) => createWidgetBridge(),
);

/// Recomputes the data behind the home / lock screen widgets and hands it to
/// the native side. Never throws: widgets are a nice-to-have.
final syncHomeWidgetsProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final bridge = ref.read(widgetBridgeProvider);
    if (!bridge.isSupported) return;
    try {
      final location = ref.read(prayerLocationProvider);
      final offsets = ref.read(prayerOffsetsProvider);
      const calculator = AdhanPrayerCalculator();
      final today = location.today();
      final days = <PrayerTimes>[
        for (
          var i = -WidgetPayload.daysBefore;
          i < WidgetPayload.daysAhead;
          i++
        )
          calculator.calculate(
            location,
            DateTime(today.year, today.month, today.day + i),
            offsets,
          ),
      ];

      final khatmah = await ref.read(khatmahProvider.future);
      final quran = await ref.read(quranIndexProvider.future);

      final payload = WidgetPayload.build(
        location: location,
        days: days,
        khatmah: khatmah,
        quran: quran,
      );
      await bridge.save(WidgetPayload.encode(payload));
    } catch (_) {
      // Best-effort.
    }
  };
});
