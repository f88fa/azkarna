import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/shared_preferences_provider.dart';
import '../../../prayer_times/presentation/providers/prayer_times_providers.dart';
import '../../data/datasources/notification_settings_local_data_source.dart';
import '../../data/repositories/notification_settings_repository_impl.dart';
import '../../domain/entities/adhan_sound.dart';
import '../../domain/entities/dhikr_reminder.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/repositories/notification_settings_repository.dart';
import '../../domain/services/notification_scheduler.dart';
import '../../domain/usecases/initialize_notifications.dart';
import '../../domain/usecases/sync_notifications.dart';

/// Must be overridden in `main()` with an initialized scheduler.
final notificationSchedulerProvider = Provider<NotificationScheduler>(
  (ref) => throw UnimplementedError('notificationSchedulerProvider'),
);

final notificationSettingsLocalDataSourceProvider =
    Provider<NotificationSettingsLocalDataSource>(
      (ref) => SharedPrefsNotificationSettingsDataSource(
        ref.watch(sharedPreferencesProvider),
      ),
    );

final notificationSettingsRepositoryProvider =
    Provider<NotificationSettingsRepository>(
      (ref) => NotificationSettingsRepositoryImpl(
        ref.watch(notificationSettingsLocalDataSourceProvider),
      ),
    );

final syncNotificationsProvider = Provider<SyncNotifications>(
  (ref) => SyncNotifications(
    ref.watch(notificationSettingsRepositoryProvider),
    ref.watch(prayerTimesRepositoryProvider),
    ref.watch(notificationSchedulerProvider),
  ),
);

final initializeNotificationsProvider = Provider<InitializeNotifications>(
  (ref) => InitializeNotifications(
    ref.watch(notificationSettingsRepositoryProvider),
    ref.watch(notificationSchedulerProvider),
    ref.watch(syncNotificationsProvider),
  ),
);

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      NotificationSettingsNotifier.new,
    );

class NotificationSettingsNotifier extends AsyncNotifier<NotificationSettings> {
  NotificationSettingsRepository get _repository =>
      ref.read(notificationSettingsRepositoryProvider);

  @override
  Future<NotificationSettings> build() =>
      ref.watch(notificationSettingsRepositoryProvider).getSettings();

  /// Returns false when the OS denied notification permission.
  Future<bool> setAdhanEnabled(bool enabled) async {
    if (enabled && !await _ensurePermission()) return false;
    await _update((s) => s.copyWith(adhanEnabled: enabled));
    return true;
  }

  /// Returns false when the OS denied notification permission.
  Future<bool> setMorningAdhkarEnabled(bool enabled) async {
    if (enabled && !await _ensurePermission()) return false;
    await _update((s) => s.copyWith(morningAdhkarEnabled: enabled));
    return true;
  }

  /// Returns false when the OS denied notification permission.
  Future<bool> setEveningAdhkarEnabled(bool enabled) async {
    if (enabled && !await _ensurePermission()) return false;
    await _update((s) => s.copyWith(eveningAdhkarEnabled: enabled));
    return true;
  }

  /// Returns false when the OS denied notification permission.
  Future<bool> setKhatmahReminderEnabled(bool enabled) async {
    if (enabled && !await _ensurePermission()) return false;
    await _update((s) => s.copyWith(khatmahReminderEnabled: enabled));
    return true;
  }

  Future<void> setKhatmahReminderTime(ReminderTime time) =>
      _update((s) => s.copyWith(khatmahReminderTime: time));

  /// Returns false when the OS denied notification permission.
  Future<bool> setKahfReminderEnabled(bool enabled) async {
    if (enabled && !await _ensurePermission()) return false;
    await _update((s) => s.copyWith(kahfReminderEnabled: enabled));
    return true;
  }

  Future<void> setKahfLead(KahfLead lead) =>
      _update((s) => s.copyWith(kahfLead: lead));

  Future<void> setAdhanDuration(AdhanDuration duration) =>
      _update((s) => s.copyWith(adhanDuration: duration));

  Future<void> setAdhanSound(AdhanSound sound) =>
      _update((s) => s.copyWith(adhanSound: sound));

  /// Returns false when the OS denied notification permission.
  Future<bool> setDhikrEnabled(bool enabled) async {
    if (enabled && !await _ensurePermission()) return false;
    await _update((s) => s.copyWith(dhikr: s.dhikr.copyWith(enabled: enabled)));
    return true;
  }

  Future<void> setDhikrInterval(DhikrInterval interval) =>
      _update((s) => s.copyWith(dhikr: s.dhikr.copyWith(interval: interval)));

  Future<void> setDhikrSound(bool enabled) => _update(
    (s) => s.copyWith(dhikr: s.dhikr.copyWith(soundEnabled: enabled)),
  );

  Future<void> setDhikrQuietHours(bool enabled) => _update(
    (s) => s.copyWith(dhikr: s.dhikr.copyWith(quietHoursEnabled: enabled)),
  );

  Future<void> setDhikrQuietStart(ReminderTime time) =>
      _update((s) => s.copyWith(dhikr: s.dhikr.copyWith(quietStart: time)));

  Future<void> setDhikrQuietEnd(ReminderTime time) =>
      _update((s) => s.copyWith(dhikr: s.dhikr.copyWith(quietEnd: time)));

  /// Schedules a test Adhan with the chosen sound after 5 s. Returns false
  /// when the OS denied notification permission.
  Future<bool> testAdhan() async {
    if (!await _ensurePermission()) return false;
    final settings = state.asData?.value ?? await _repository.getSettings();
    await ref
        .read(notificationSchedulerProvider)
        .scheduleTestAdhan(
          settings.adhanSound,
          duration: settings.adhanDuration,
        );
    return true;
  }

  /// Schedules a test dhikr notification after 5 s.
  Future<bool> testDhikr() async {
    if (!await _ensurePermission()) return false;
    final dhikr =
        (state.asData?.value ?? await _repository.getSettings()).dhikr;
    await ref
        .read(notificationSchedulerProvider)
        .scheduleTestDhikr(sound: dhikr.soundEnabled);
    return true;
  }

  Future<bool> _ensurePermission() => ref
      .read(notificationSchedulerProvider)
      .requestPermissions(includeExactAlarms: true);

  Future<void> _update(
    NotificationSettings Function(NotificationSettings) change,
  ) async {
    final current = state.asData?.value ?? await _repository.getSettings();
    final next = change(current);
    await _repository.saveSettings(next);
    state = AsyncData(next);

    try {
      await ref
          .read(syncNotificationsProvider)
          .call(ref.read(prayerLocationProvider));
    } catch (_) {
      // Scheduling is best-effort; the saved preference stays intact.
    }
  }
}
