import '../../../prayer_times/domain/entities/prayer_times.dart';
import '../../../tasks/domain/entities/task.dart';
import '../entities/notification_settings.dart';

/// Platform-agnostic contract for scheduling local notifications.
abstract interface class NotificationScheduler {
  /// Asks the OS for notification permission (and optionally exact-alarm
  /// access on Android). Returns whether notifications are allowed.
  Future<bool> requestPermissions({bool includeExactAlarms = false});

  /// Replaces all scheduled Adhan notifications with those in [days].
  Future<void> scheduleAdhan(List<PrayerTimes> days);
  Future<void> cancelAdhan();

  /// Replaces the Adhkar reminders: morning Adhkar
  /// [AdhkarReminderDelays.morningAfterFajr] after Fajr and evening Adhkar
  /// [AdhkarReminderDelays.eveningAfterAsr] after Asr, for each day in [days].
  Future<void> scheduleAdhkarReminders(
    List<PrayerTimes> days, {
    required bool morning,
    required bool evening,
  });
  Future<void> cancelAdhkarReminders();

  /// Replaces all task reminders: one notification at each task's time
  /// (weekly for repeating tasks).
  Future<void> replaceTaskReminders(List<Task> tasks);

  /// Schedules a notification repeating every day at [time].
  Future<void> scheduleDailyKhatmahReminder(ReminderTime time);
  Future<void> cancelKhatmahReminder();
}
