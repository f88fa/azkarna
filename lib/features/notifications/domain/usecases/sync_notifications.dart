import '../../../../core/error/failures.dart';
import '../../../prayer_times/domain/entities/prayer_location.dart';
import '../../../prayer_times/domain/entities/prayer_times.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../entities/notification_settings.dart';
import '../repositories/notification_settings_repository.dart';
import '../services/notification_scheduler.dart';

/// Brings scheduled notifications in line with the saved settings.
class SyncNotifications {
  const SyncNotifications(this._settings, this._prayerTimes, this._scheduler);

  static const int adhanDaysAhead = 7;
  static const int adhanDaysWithDhikr = 4;
  // Pre-prayer alerts double the per-day count; fewer days keep everything
  // under the iOS cap of 64 pending notifications (topped up on each open).
  static const int adhanDaysWithBefore = 4;
  static const int adhanDaysWithBeforeAndDhikr = 3;
  static const int kahfDaysAhead = 8;

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
    await _syncKahf(settings, location);

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
    final before = settings.prayerReminderEnabled;
    if (!settings.adhanEnabled) await _scheduler.cancelAdhan();
    if (!adhkar) await _scheduler.cancelAdhkarReminders();
    if (!before) await _scheduler.cancelPrayerReminders();
    if (!settings.adhanEnabled && !adhkar && !before) return;

    final dhikr = settings.dhikr.enabled;
    try {
      final days = await _prayerTimes.getUpcomingPrayerTimes(
        location,
        // Fewer days when other reminders also need pending slots.
        days: before
            ? (dhikr ? adhanDaysWithBeforeAndDhikr : adhanDaysWithBefore)
            : (dhikr ? adhanDaysWithDhikr : adhanDaysAhead),
      );
      if (days.isEmpty) return;
      if (settings.adhanEnabled) {
        await _scheduler.scheduleAdhan(
          days,
          sound: settings.adhanSound,
          duration: settings.adhanDuration,
        );
      }
      if (before) {
        await _scheduler.schedulePrayerReminders(
          days,
          before: Duration(minutes: settings.prayerReminderMinutes),
        );
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

  /// Friday reminder: the Fridays of the coming week, [KahfLead] before
  /// Maghrib. Fetches its own days so it never depends on how many days the
  /// Adhan scheduling asked for.
  Future<void> _syncKahf(
    NotificationSettings settings,
    PrayerLocation location,
  ) async {
    if (!settings.kahfReminderEnabled) {
      await _scheduler.cancelKahfReminders();
      return;
    }
    try {
      final days = await _prayerTimes.getUpcomingPrayerTimes(
        location,
        days: kahfDaysAhead,
      );
      final fridays = [
        for (final day in days)
          if (day.times[Prayer.maghrib]?.weekday == DateTime.friday) day,
      ];
      await _scheduler.scheduleKahfReminders(
        fridays,
        before: settings.kahfLead.duration,
      );
    } on Failure {
      // Keep whatever was scheduled before.
    }
  }
}
