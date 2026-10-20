import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/layout/layout.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/popup_scaffold.dart';
import '../../../notifications/domain/entities/adhan_sound.dart';
import '../../../notifications/domain/entities/notification_settings.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../notifications/presentation/providers/sound_preview_provider.dart';
import '../../../prayer_times/presentation/providers/prayer_times_providers.dart';
import '../widgets/settings_group.dart';

/// Settings home: a few grouped glass cards. Each detail (location, muezzin
/// voice, dhikr reminders, …) opens in its own sheet.
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
        padding: EdgeInsets.only(top: 4, bottom: floatingNavBarInset(context)),
        child: Column(
          children: [
            const _AppearanceSection(),
            SettingsSection(
              title: 'الموقع وطريقة الحساب',
              children: [
                SettingsNavTile(
                  icon: Icons.location_on_rounded,
                  color: AppColors.red,
                  title: 'الموقع',
                  subtitle: location.displayName,
                  onTap: () => context.push(AppRoutes.settingsLocation),
                ),
                SettingsNavTile(
                  icon: Icons.calculate_rounded,
                  color: AppColors.purple,
                  title: 'طريقة الحساب',
                  subtitle: 'أم القرى (مكة المكرمة) · تعديل الدقائق يدويًا',
                  onTap: () => context.push(AppRoutes.settingsLocation),
                ),
              ],
            ),
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
                  _AdhanSection(settings: data),
                  SettingsSection(
                    title: 'تذكيرات الذكر الدورية',
                    children: [
                      SettingsNavTile(
                        icon: Icons.favorite_rounded,
                        color: AppColors.pink,
                        title: data.dhikr.enabled ? 'مفعّل' : 'متوقف',
                        subtitle: data.dhikr.enabled
                            ? '${data.dhikr.interval.label}'
                                  '${data.dhikr.quietHoursEnabled ? ' · هدوء أثناء النوم' : ''}'
                            : 'اضغط لتفعيل التذكير وضبط التكرار',
                        onTap: () => context.push(AppRoutes.settingsDhikr),
                      ),
                    ],
                  ),
                  SettingsSection(
                    title: 'الأذكار والختمة',
                    children: [
                      SettingsNavTile(
                        icon: Icons.menu_book_rounded,
                        color: AppColors.orange,
                        title: 'تذكيرات الصباح والمساء والختمة',
                        subtitle: _remindersSummary(data),
                        onTap: () => context.push(AppRoutes.settingsReminders),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const _AboutSection(),
          ],
        ),
      ),
    );
  }

  static String _remindersSummary(NotificationSettings s) {
    final on = [
      s.morningAdhkarEnabled,
      s.eveningAdhkarEnabled,
      s.khatmahReminderEnabled,
    ].where((v) => v).length;
    return on == 0 ? 'كلها متوقفة' : '${arNum(on)} من ٣ مفعّلة';
  }
}

/// Light / dark / system, applied to the whole app at once.
class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  static const _labels = {
    ThemeMode.light: 'نهاري',
    ThemeMode.dark: 'ليلي',
    ThemeMode.system: 'تلقائي',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return SettingsSection(
      title: 'المظهر والعرض',
      footer: 'التلقائي يتبع وضع الجهاز (نهاري أو ليلي).',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              SettingsIcon(
                icon: theme.brightness == Brightness.dark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: AppColors.indigo,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoSlidingSegmentedControl<ThemeMode>(
                  groupValue: mode,
                  thumbColor: primary,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  onValueChanged: (v) {
                    if (v == null) return;
                    HapticFeedback.selectionClick();
                    ref.read(themeModeProvider.notifier).set(v);
                  },
                  children: {
                    for (final e in _labels.entries)
                      e.key: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: mode == e.key
                                ? (theme.brightness == Brightness.dark
                                      ? const Color(0xFF05201B)
                                      : Colors.white)
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Adhan on/off, the chosen muezzin (opens the picker) and a test button.
class _AdhanSection extends ConsumerWidget {
  const _AdhanSection({required this.settings});

  final NotificationSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return SettingsSection(
      title: 'إعدادات الأذان والمؤذنين',
      footer:
          'اضغط «تجربة إشعار الأذان» ثم اقفل شاشة الجوال لتسمع الصوت المختار. '
          'تأكد أن الجوال ليس على الوضع الصامت.',
      children: [
        SettingsSwitchTile(
          icon: Icons.mosque_rounded,
          color: AppColors.primary,
          title: 'إشعارات الصلوات الخمس',
          subtitle: 'تنبيه بالأذان عند دخول كل صلاة',
          value: settings.adhanEnabled,
          onChanged: (v) async {
            final ok = await notifier.setAdhanEnabled(v);
            if (!ok && context.mounted) {
              showAppSnack(
                context,
                'الإشعارات محظورة. فعّلها من إعدادات النظام.',
              );
            }
          },
        ),
        SettingsNavTile(
          icon: Icons.record_voice_over_rounded,
          color: AppColors.teal,
          title: 'صوت المؤذن',
          subtitle: settings.adhanSound.label,
          onTap: () => context.push(AppRoutes.settingsMuadhin),
        ),
        SettingsChoiceTile<AdhanDuration>(
          icon: Icons.content_cut_rounded,
          color: AppColors.orange,
          title: 'مدة الأذان في الإشعار',
          options: AdhanDuration.values,
          selected: settings.adhanDuration,
          labelOf: (d) => '${d.label} · ${d.hint}',
          onSelected: notifier.setAdhanDuration,
        ),
        SettingsActionTile(
          icon: Icons.notifications_active_rounded,
          color: AppColors.red,
          title: 'تجربة إشعار الأذان الآن (بعد ٥ ثوانٍ)',
          subtitle: 'ثم اقفل الشاشة لتسمعه',
          onTap: () async {
            await ref.read(soundPreviewProvider.notifier).stop();
            final ok = await notifier.testAdhan();
            if (!context.mounted) return;
            showAppSnack(
              context,
              ok
                  ? 'سيصلك إشعار الأذان بعد ٥ ثوانٍ، اقفل الشاشة الآن.'
                  : 'الإشعارات محظورة. فعّلها من إعدادات النظام.',
            );
          },
        ),
      ],
    );
  }
}

/// App identity and version at the bottom.
class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return SettingsSection(
      title: 'عن التطبيق',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${AppConstants.appName} - ${AppConstants.appTagline}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'الإصدار ${AppConstants.appVersion} +${AppConstants.buildNumber}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
