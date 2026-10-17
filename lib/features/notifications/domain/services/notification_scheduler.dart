import '../../../prayer_times/domain/entities/prayer_times.dart';
import '../entities/notification_settings.dart';

/// Platform-agnostic contract for scheduling local notifications.
abstract interface class NotificationScheduler {
  /// Asks the OS for notification permission (and optionally exact-alarm
  /// access on Android). Returns whether notifications are allowed.
  Future<bool> requestPermissions({bool includeExactAlarms = false});

  /// Replaces all scheduled Adhan notifications with those in [days].
  Future<void> scheduleAdhan(List<PrayerTimes> days);
  Future<void> cancelAdhan();

  /// Schedules a notification repeating every day at [time].
  Future<void> scheduleDailyKhatmahReminder(ReminderTime time);
  Future<void> cancelKhatmahReminder();
}
