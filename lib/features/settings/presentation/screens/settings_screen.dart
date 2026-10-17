import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/layout.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../notifications/domain/entities/notification_settings.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../prayer_times/presentation/providers/prayer_times_providers.dart';
import '../widgets/settings_group.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(notificationSettingsProvider);
    final location = ref.watch(prayerLocationProvider);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar.large(
            backgroundColor: theme.scaffoldBackgroundColor,
            title: const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              floatingNavBarInset(context),
            ),
            sliver: SliverToBoxAdapter(
              child: settings.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => ErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(notificationSettingsProvider),
                ),
                data: (data) => _NotificationsSection(
                  settings: data,
                  cityLabel: location.city,
                ),
              ),
            ),
          ),
        ],
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
          content: Text(
            'Notifications are blocked. Enable them in system settings.',
          ),
        ),
      );
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final current = settings.khatmahReminderTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'Khatmah reminder time',
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
    final timeLabel = TimeOfDay(
      hour: time.hour,
      minute: time.minute,
    ).format(context);

    return SettingsGroup(
      title: 'Notifications',
      children: [
        SettingsSwitchTile(
          icon: Icons.mosque_rounded,
          title: 'Adhan',
          subtitle: 'Alert at each of the 5 daily prayers · $cityLabel',
          value: settings.adhanEnabled,
          onChanged: (v) => _toggle(context, () => notifier.setAdhanEnabled(v)),
        ),
        SettingsSwitchTile(
          icon: Icons.menu_book_rounded,
          title: 'Khatmah reminder',
          subtitle: 'Daily reminder to read your Quran goal',
          value: settings.khatmahReminderEnabled,
          onChanged: (v) =>
              _toggle(context, () => notifier.setKhatmahReminderEnabled(v)),
        ),
        SettingsValueTile(
          icon: Icons.schedule_rounded,
          title: 'Reminder time',
          value: timeLabel,
          enabled: settings.khatmahReminderEnabled,
          onTap: () => _pickTime(context, ref),
        ),
      ],
    );
  }
}
