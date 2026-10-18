import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/popup_scaffold.dart';
import '../../../prayer_times/domain/entities/prayer_times.dart';
import '../../../prayer_times/presentation/providers/prayer_times_providers.dart';
import '../widgets/settings_group.dart';

/// City, calculation method and the manual per-prayer minute offsets.
class LocationSettingsScreen extends ConsumerWidget {
  const LocationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(prayerLocationProvider);

    return PopupScaffold(
      title: 'الموقع وطريقة الحساب',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.only(top: 4, bottom: floatingNavBarInset(context)),
        child: Column(
          children: [
            SettingsSection(
              title: 'مواقيت الصلاة',
              footer: 'تُحسب المواقيت لهذه المدينة بطريقة أم القرى.',
              children: [
                SettingsValueTile(
                  icon: Icons.location_on_rounded,
                  color: AppColors.red,
                  title: 'الموقع',
                  value: location.displayName,
                ),
                const SettingsValueTile(
                  icon: Icons.calculate_rounded,
                  color: AppColors.purple,
                  title: 'طريقة الحساب',
                  value: 'أم القرى (مكة المكرمة)',
                ),
              ],
            ),
            const _OffsetsSection(),
          ],
        ),
      ),
    );
  }
}

class _OffsetsSection extends ConsumerWidget {
  const _OffsetsSection();

  static const _style = <Prayer, (IconData, Color)>{
    Prayer.fajr: (Icons.nights_stay_rounded, AppColors.indigo),
    Prayer.sunrise: (Icons.wb_twilight_rounded, AppColors.amber),
    Prayer.dhuhr: (Icons.wb_sunny_rounded, AppColors.orange),
    Prayer.asr: (Icons.sunny_snowing, AppColors.teal),
    Prayer.maghrib: (Icons.wb_twilight_rounded, AppColors.pink),
    Prayer.isha: (Icons.bedtime_rounded, AppColors.purple),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offsets = ref.watch(prayerOffsetsProvider);
    final times = ref.watch(prayerTimesProvider).asData?.value;

    return SettingsSection(
      title: 'تعديل المواقيت يدويًا',
      footer:
          'أضف أو أنقص دقيقة من وقت كل صلاة على حدة. '
          'يُطبَّق التعديل على المواقيت وعلى تنبيهات الأذان.',
      children: [
        for (final prayer in Prayer.values)
          SettingsOffsetTile(
            icon: _style[prayer]!.$1,
            color: _style[prayer]!.$2,
            title: prayer.label,
            subtitle: times == null
                ? ' '
                : 'الوقت الحالي ${arTime(times.times[prayer]!)}',
            minutes: offsets.of(prayer),
            onChange: (delta) =>
                ref.read(prayerOffsetsProvider.notifier).change(prayer, delta),
          ),
      ],
    );
  }
}
