import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/popup_scaffold.dart';
import '../../../notifications/domain/entities/notification_settings.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../widgets/settings_group.dart';

/// Morning / evening adhkar and the daily Khatmah reminder.
class AdhkarRemindersScreen extends ConsumerWidget {
  const AdhkarRemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);

    return PopupScaffold(
      title: 'الأذكار والختمة',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.only(top: 4, bottom: floatingNavBarInset(context)),
        child: settings.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(notificationSettingsProvider),
          ),
          data: (data) => _Reminders(settings: data),
        ),
      ),
    );
  }
}

class _Reminders extends ConsumerWidget {
  const _Reminders({required this.settings});

  final NotificationSettings settings;

  Future<void> _toggle(
    BuildContext context,
    Future<bool> Function() action,
  ) async {
    final granted = await action();
    if (granted || !context.mounted) return;
    showAppSnack(context, 'الإشعارات محظورة. فعّلها من إعدادات النظام.');
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
      title: 'التذكيرات',
      children: [
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
