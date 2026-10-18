import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/layout/layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/popup_scaffold.dart';
import '../../../notifications/domain/entities/notification_settings.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../prayer_times/domain/entities/prayer_times.dart';
import '../../../prayer_times/presentation/providers/prayer_times_providers.dart';
import '../widgets/adhan_sound_section.dart';
import '../widgets/dhikr_reminders_section.dart';
import '../widgets/settings_group.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final location = ref.watch(prayerLocationProvider);

    return PopupScaffold(
      title: 'الإعدادات',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.only(bottom: floatingNavBarInset(context)),
        child: Column(
          children: [
            const _BrandHeader(),
            settings.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(notificationSettingsProvider),
              ),
              data: (data) => Column(
                children: [
                  _NotificationsSection(
                    settings: data,
                    cityLabel: location.city,
                  ),
                  AdhanSoundSection(selected: data.adhanSound),
                  DhikrRemindersSection(settings: data.dhikr),
                ],
              ),
            ),
            _PrayerSection(cityLabel: location.displayName),
            const _OffsetsSection(),
          ],
        ),
      ),
    );
  }
}

class _NotificationsSection extends ConsumerWidget {
  const _NotificationsSection({
    required this.settings,
    required this.cityLabel,
  });

  final NotificationSettings settings;
  final String cityLabel;

  Future<void> _toggle(
    BuildContext context,
    Future<bool> Function() action,
  ) async {
    final granted = await action();
    if (granted || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('الإشعارات محظورة. فعّلها من إعدادات النظام.'),
        ),
      );
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final current = settings.khatmahReminderTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'وقت تذكير الختمة',
      cancelText: 'إلغاء',
      confirmText: 'حفظ',
    );
    if (picked == null) return;
    await ref
        .read(notificationSettingsProvider.notifier)
        .setKhatmahReminderTime(
          ReminderTime(hour: picked.hour, minute: picked.minute),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(notificationSettingsProvider.notifier);
    final time = settings.khatmahReminderTime;
    final timeLabel = arTime(DateTime(2000, 1, 1, time.hour, time.minute));

    return SettingsSection(
      title: 'الإشعارات',
      children: [
        SettingsSwitchTile(
          icon: Icons.mosque_rounded,
          color: AppColors.primary,
          title: 'الأذان',
          subtitle: 'تنبيه عند كل صلاة من الصلوات الخمس · $cityLabel',
          value: settings.adhanEnabled,
          onChanged: (v) => _toggle(context, () => notifier.setAdhanEnabled(v)),
        ),
        SettingsSwitchTile(
          icon: Icons.wb_sunny_rounded,
          color: AppColors.amber,
          title: 'أذكار الصباح',
          subtitle:
              'بعد أذان الفجر بـ ${arNum(AdhkarReminderDelays.morningAfterFajr.inMinutes)} دقيقة',
          value: settings.morningAdhkarEnabled,
          onChanged: (v) =>
              _toggle(context, () => notifier.setMorningAdhkarEnabled(v)),
        ),
        SettingsSwitchTile(
          icon: Icons.nights_stay_rounded,
          color: AppColors.indigo,
          title: 'أذكار المساء',
          subtitle:
              'بعد أذان العصر بـ ${arNum(AdhkarReminderDelays.eveningAfterAsr.inMinutes)} دقيقة',
          value: settings.eveningAdhkarEnabled,
          onChanged: (v) =>
              _toggle(context, () => notifier.setEveningAdhkarEnabled(v)),
        ),
        SettingsSwitchTile(
          icon: Icons.menu_book_rounded,
          color: AppColors.orange,
          title: 'تذكير الختمة',
          subtitle: 'تذكير يومي بقراءة وردك من القرآن',
          value: settings.khatmahReminderEnabled,
          onChanged: (v) =>
              _toggle(context, () => notifier.setKhatmahReminderEnabled(v)),
        ),
        SettingsValueTile(
          icon: Icons.schedule_rounded,
          color: AppColors.blue,
          title: 'وقت التذكير',
          value: timeLabel,
          enabled: settings.khatmahReminderEnabled,
          onTap: () => _pickTime(context, ref),
        ),
      ],
    );
  }
}

class _PrayerSection extends StatelessWidget {
  const _PrayerSection({required this.cityLabel});

  final String cityLabel;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'مواقيت الصلاة',
      children: [
        SettingsValueTile(
          icon: Icons.location_on_rounded,
          color: AppColors.red,
          title: 'الموقع',
          value: cityLabel,
        ),
        const SettingsValueTile(
          icon: Icons.calculate_rounded,
          color: AppColors.purple,
          title: 'طريقة الحساب',
          value: 'أم القرى (مكة المكرمة)',
        ),
      ],
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

/// App identity: name and tagline.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  AppConstants.appTagline,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
