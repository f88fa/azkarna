import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/layout/layout.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/popup_scaffold.dart';
import '../../../prayer_times/domain/entities/prayer_times.dart';
import '../../../prayer_times/data/services/device_location_service.dart';
import '../../../prayer_times/domain/entities/saudi_city.dart';
import '../../../prayer_times/presentation/providers/location_providers.dart';
import '../../../prayer_times/presentation/providers/prayer_times_providers.dart';
import '../widgets/settings_group.dart';

/// Location (automatic GPS or a picked Saudi city), calculation method and
/// the manual per-prayer minute offsets.
class LocationSettingsScreen extends ConsumerStatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  ConsumerState<LocationSettingsScreen> createState() =>
      _LocationSettingsScreenState();
}

class _LocationSettingsScreenState
    extends ConsumerState<LocationSettingsScreen> {
  bool _busy = false;

  Future<void> _locate() async {
    if (_busy) return;
    setState(() => _busy = true);
    final outcome = await ref.read(locationProvider.notifier).enableAuto();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case LocationUpdated(:final location):
        showAppSnack(
          context,
          'تم تحديد موقعك: ${location.city}، وحُدّثت مواقيت الصلاة.',
        );
      case LocationFailed():
        showAppSnack(context, outcome.message);
        final service = ref.read(deviceLocationServiceProvider);
        if (outcome.access == LocationAccess.deniedForever) {
          await service.openSettings();
        } else if (outcome.access == LocationAccess.serviceOff) {
          await service.openLocationSettings();
        }
    }
  }

  Future<void> _setAuto(bool on) async {
    if (on) return _locate();
    final state = ref.read(locationProvider);
    final city = SaudiCity.byId(state.cityId) ?? SaudiCity.hail;
    await ref.read(locationProvider.notifier).setManual(city);
    if (!mounted) return;
    showAppSnack(
      context,
      'الوضع اليدوي: المواقيت لمدينة ${city.name}. يمكنك تغييرها من «المدينة».',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationProvider);
    final location = state.location;

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
              title: 'الموقع',
              footer: state.isAuto
                  ? 'يقرأ التطبيق موقعك عند فتحه، وإذا انتقلت إلى مدينة أخرى '
                        'تتحدّث المواقيت والتنبيهات تلقائيًا.'
                  : 'المواقيت ثابتة على المدينة المختارة. إذا انتقلت إلى مدينة '
                        'أخرى سيسألك التطبيق هل تريد تحديثها.',
              children: [
                SettingsSwitchTile(
                  icon: Icons.my_location_rounded,
                  color: AppColors.primary,
                  title: 'تحديد الموقع تلقائيًا',
                  subtitle: _busy
                      ? 'جارٍ تحديد موقعك…'
                      : state.isAuto
                      ? 'من موقع الجهاز (GPS)'
                      : 'متوقف · مدينة مختارة يدويًا',
                  value: state.isAuto,
                  onChanged: _busy ? (_) {} : _setAuto,
                ),
                SettingsValueTile(
                  icon: Icons.location_on_rounded,
                  color: AppColors.red,
                  title: state.isAuto ? 'موقعك الحالي' : 'المدينة',
                  value: location.city,
                  onTap: state.isAuto
                      ? null
                      : () => context.push(AppRoutes.settingsCity),
                ),
                if (state.isAuto)
                  SettingsActionTile(
                    icon: Icons.refresh_rounded,
                    color: AppColors.teal,
                    title: _busy ? 'جارٍ التحديث…' : 'تحديث الموقع الآن',
                    onTap: _locate,
                  )
                else
                  SettingsActionTile(
                    icon: Icons.location_city_rounded,
                    color: AppColors.teal,
                    title: 'اختيار مدينة أخرى',
                    subtitle: 'مدن المملكة مرتّبة حسب المنطقة',
                    onTap: () => context.push(AppRoutes.settingsCity),
                  ),
              ],
            ),
            const SettingsSection(
              title: 'طريقة الحساب',
              footer: 'تُحسب المواقيت لهذا الموقع بطريقة أم القرى.',
              children: [
                SettingsValueTile(
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
