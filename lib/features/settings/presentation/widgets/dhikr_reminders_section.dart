import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../notifications/domain/entities/dhikr_reminder.dart';
import '../../../notifications/domain/entities/notification_settings.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import 'settings_group.dart';

String _time(ReminderTime t) => arTime(DateTime(2000, 1, 1, t.hour, t.minute));

/// "Periodic dhikr reminders": on/off, interval, quiet hours and a test.
class DhikrRemindersSection extends ConsumerWidget {
  const DhikrRemindersSection({super.key, required this.settings});

  final DhikrReminderSettings settings;

  Future<void> _pick(
    BuildContext context,
    ReminderTime current,
    String help,
    Future<void> Function(ReminderTime) save,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: help,
      cancelText: 'إلغاء',
      confirmText: 'حفظ',
    );
    if (picked == null) return;
    await save(ReminderTime(hour: picked.hour, minute: picked.minute));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(notificationSettingsProvider.notifier);
    final on = settings.enabled;

    return SettingsSection(
      title: 'تذكيرات الذكر الدورية',
      footer:
          'استغفار وتسبيح وحوقلة وصلاة على النبي ﷺ بأذكار مختلفة في كل مرة، '
          'حتى والتطبيق مغلق. يجدّد التطبيق الجدولة كلما فتحته.',
      children: [
        SettingsSwitchTile(
          icon: Icons.favorite_rounded,
          color: AppColors.pink,
          title: 'تفعيل التذكير',
          subtitle: on ? settings.interval.label : 'تذكير منتظم بذكر الله',
          value: on,
          onChanged: (v) async {
            final ok = await notifier.setDhikrEnabled(v);
            if (!ok && context.mounted) {
              showAppSnack(
                context,
                'الإشعارات محظورة. فعّلها من إعدادات النظام.',
              );
            }
          },
        ),
        SettingsChoiceTile<DhikrInterval>(
          icon: Icons.timer_rounded,
          color: AppColors.blue,
          title: 'التكرار',
          options: DhikrInterval.values,
          selected: settings.interval,
          labelOf: (i) => i.label,
          enabled: on,
          onSelected: notifier.setDhikrInterval,
        ),
        SettingsSwitchTile(
          icon: Icons.bedtime_rounded,
          color: AppColors.indigo,
          title: 'وقت الهدوء أثناء النوم',
          subtitle: 'لا تصلك تذكيرات خلاله',
          value: settings.quietHoursEnabled,
          onChanged: notifier.setDhikrQuietHours,
        ),
        if (settings.quietHoursEnabled) ...[
          SettingsValueTile(
            icon: Icons.nightlight_round,
            color: AppColors.purple,
            title: 'يبدأ الهدوء',
            value: _time(settings.quietStart),
            onTap: () => _pick(
              context,
              settings.quietStart,
              'بداية وقت الهدوء',
              notifier.setDhikrQuietStart,
            ),
          ),
          SettingsValueTile(
            icon: Icons.wb_sunny_rounded,
            color: AppColors.amber,
            title: 'ينتهي الهدوء',
            value: _time(settings.quietEnd),
            onTap: () => _pick(
              context,
              settings.quietEnd,
              'نهاية وقت الهدوء',
              notifier.setDhikrQuietEnd,
            ),
          ),
        ],
        SettingsActionTile(
          icon: Icons.notifications_active_rounded,
          color: AppColors.primary,
          title: 'تجربة إشعار ذكر الآن',
          subtitle: 'يصلك بعد ٥ ثوانٍ، اقفل الشاشة لتراه',
          onTap: () async {
            final ok = await notifier.testDhikr();
            if (!context.mounted) return;
            showAppSnack(
              context,
              ok
                  ? 'سيصلك إشعار الذكر بعد ٥ ثوانٍ.'
                  : 'الإشعارات محظورة. فعّلها من إعدادات النظام.',
            );
          },
        ),
      ],
    );
  }
}
