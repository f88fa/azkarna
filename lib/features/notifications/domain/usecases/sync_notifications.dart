import '../../../../core/error/failures.dart';
import '../../../prayer_times/domain/entities/prayer_location.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../repositories/notification_settings_repository.dart';
import '../services/notification_scheduler.dart';

/// Brings scheduled notifications in line with the saved settings.
class SyncNotifications {
  const SyncNotifications(this._settings, this._prayerTimes, this._scheduler);

  static const int adhanDaysAhead = 7;

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

    if (!settings.adhanEnabled) {
      await _scheduler.cancelAdhan();
      return;
    }

    try {
      final days = await _prayerTimes.getUpcomingPrayerTimes(
        location,
        days: adhanDaysAhead,
      );
      if (days.isNotEmpty) await _scheduler.scheduleAdhan(days);
    } on Failure {
      // Offline or API error: keep the previously scheduled notifications.
    }
  }
}
