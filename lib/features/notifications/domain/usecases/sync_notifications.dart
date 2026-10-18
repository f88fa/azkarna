import '../../../../core/error/failures.dart';
import '../../../prayer_times/domain/entities/prayer_location.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../entities/notification_settings.dart';
import '../repositories/notification_settings_repository.dart';
import '../services/notification_scheduler.dart';

/// Brings scheduled notifications in line with the saved settings.
class SyncNotifications {
  const SyncNotifications(this._settings, this._prayerTimes, this._scheduler);

  static const int adhanDaysAhead = 7;
  static const int adhanDaysWithDhikr = 4;

  final NotificationSettingsRepository _settings;
  final PrayerTimesRepository _prayerTimes;
  final NotificationScheduler _scheduler;

  Future<void> call(PrayerLocation location) async {
    final settings = await _settings.getSettings();

    if (settings.khatmahReminderEnabled) {
      await _scheduler.scheduleDailyKhatmahReminder(
        settings.khatmahReminderTime,
      );
    } else {
      await _scheduler.cancelKhatmahReminder();
    }

    await _syncPrayerBased(settings, location);

    // Last, so it only uses the room left under the OS pending limit.
    if (settings.dhikr.enabled) {
      await _scheduler.replacePeriodicDhikr(settings.dhikr);
    } else {
      await _scheduler.cancelPeriodicDhikr();
    }
  }

  Future<void> _syncPrayerBased(
    NotificationSettings settings,
    PrayerLocation location,
  ) async {
    final adhkar =
        settings.morningAdhkarEnabled || settings.eveningAdhkarEnabled;
    if (!settings.adhanEnabled) await _scheduler.cancelAdhan();
    if (!adhkar) await _scheduler.cancelAdhkarReminders();
    if (!settings.adhanEnabled && !adhkar) return;

    try {
      final days = await _prayerTimes.getUpcomingPrayerTimes(
        location,
        // Fewer days when the periodic reminders also need pending slots.
        days: settings.dhikr.enabled ? adhanDaysWithDhikr : adhanDaysAhead,
      );
      if (days.isEmpty) return;
      if (settings.adhanEnabled) {
        await _scheduler.scheduleAdhan(days, sound: settings.adhanSound);
      }
      if (adhkar) {
        await _scheduler.scheduleAdhkarReminders(
          days,
          morning: settings.morningAdhkarEnabled,
          evening: settings.eveningAdhkarEnabled,
        );
      }
    } on Failure {
      // Offline or API error: keep the previously scheduled notifications.
    }
  }
}
