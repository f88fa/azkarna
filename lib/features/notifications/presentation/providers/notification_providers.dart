import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/shared_preferences_provider.dart';
import '../../../prayer_times/presentation/providers/prayer_times_providers.dart';
import '../../data/datasources/notification_settings_local_data_source.dart';
import '../../data/repositories/notification_settings_repository_impl.dart';
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
  Future<bool> setKhatmahReminderEnabled(bool enabled) async {
    if (enabled && !await _ensurePermission()) return false;
    await _update((s) => s.copyWith(khatmahReminderEnabled: enabled));
    return true;
  }

  Future<void> setKhatmahReminderTime(ReminderTime time) =>
      _update((s) => s.copyWith(khatmahReminderTime: time));

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
