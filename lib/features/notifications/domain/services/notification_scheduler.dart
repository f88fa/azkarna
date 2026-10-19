import '../../../prayer_times/domain/entities/prayer_times.dart';
import '../../../tasks/domain/entities/task.dart';
import '../entities/adhan_sound.dart';
import '../entities/dhikr_reminder.dart';
import '../entities/notification_settings.dart';

/// Platform-agnostic contract for scheduling local notifications.
abstract interface class NotificationScheduler {
  /// Asks the OS for notification permission (and optionally exact-alarm
  /// access on Android). Returns whether notifications are allowed.
  Future<bool> requestPermissions({bool includeExactAlarms = false});

  /// Replaces all scheduled Adhan notifications with those in [days], each
  /// playing [sound].
  Future<void> scheduleAdhan(
    List<PrayerTimes> days, {
    required AdhanSound sound,
  });
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

  /// Replaces the periodic dhikr reminders: individually scheduled
  /// notifications (so every one can carry a different dhikr) from now on,
  /// skipping the quiet hours. The OS caps pending notifications (64 on iOS),
  /// so only as many as fit are scheduled; the app tops them up whenever it
  /// is opened.
  Future<void> replacePeriodicDhikr(DhikrReminderSettings settings);
  Future<void> cancelPeriodicDhikr();

  /// Fires a test Adhan notification with [sound] after [delay] (so the phone
  /// can be locked to hear it).
  Future<void> scheduleTestAdhan(
    AdhanSound sound, {
    Duration delay = const Duration(seconds: 5),
  });

  /// Fires a test dhikr notification after [delay].
  Future<void> scheduleTestDhikr({
    Duration delay = const Duration(seconds: 5),
    bool sound = true,
  });

  /// Replaces the Surah Al-Kahf reminders: one notification [before] each
  /// Maghrib in [fridays] (days that are Fridays).
  Future<void> scheduleKahfReminders(
    List<PrayerTimes> fridays, {
    required Duration before,
  });
  Future<void> cancelKahfReminders();

  /// Schedules a notification repeating every day at [time].
  Future<void> scheduleDailyKhatmahReminder(ReminderTime time);
  Future<void> cancelKhatmahReminder();
}
