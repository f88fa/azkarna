import '../../../prayer_times/domain/entities/prayer_times.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../domain/entities/adhan_sound.dart';
import '../../domain/entities/dhikr_reminder.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/services/notification_scheduler.dart';

/// Used where local notifications are unavailable (e.g. Flutter Web preview).
class NoopNotificationScheduler implements NotificationScheduler {
  const NoopNotificationScheduler();

  @override
  Future<bool> requestPermissions({bool includeExactAlarms = false}) async =>
      true;

  @override
  Future<void> scheduleAdhan(
    List<PrayerTimes> days, {
    required AdhanSound sound,
    AdhanDuration duration = AdhanDuration.full,
  }) async {}

  @override
  Future<void> cancelAdhan() async {}

  @override
  Future<void> scheduleAdhkarReminders(
    List<PrayerTimes> days, {
    required bool morning,
    required bool evening,
  }) async {}

  @override
  Future<void> cancelAdhkarReminders() async {}

  @override
  Future<void> replaceTaskReminders(List<Task> tasks) async {}

  @override
  Future<void> replacePeriodicDhikr(DhikrReminderSettings settings) async {}

  @override
  Future<void> cancelPeriodicDhikr() async {}

  @override
  Future<void> scheduleTestAdhan(
    AdhanSound sound, {
    Duration delay = const Duration(seconds: 5),
    AdhanDuration duration = AdhanDuration.full,
  }) async {}

  @override
  Future<void> scheduleTestDhikr({
    Duration delay = const Duration(seconds: 5),
    bool sound = true,
  }) async {}

  @override
  Future<void> scheduleKahfReminders(
    List<PrayerTimes> fridays, {
    required Duration before,
  }) async {}

  @override
  Future<void> cancelKahfReminders() async {}

  @override
  Future<void> scheduleDailyKhatmahReminder(ReminderTime time) async {}

  @override
  Future<void> cancelKhatmahReminder() async {}
}
