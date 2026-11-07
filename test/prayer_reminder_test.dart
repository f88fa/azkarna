import 'package:azkarna/features/notifications/data/datasources/notification_settings_local_data_source.dart';
import 'package:azkarna/features/notifications/data/repositories/notification_settings_repository_impl.dart';
import 'package:azkarna/features/notifications/data/services/noop_notification_scheduler.dart';
import 'package:azkarna/features/notifications/domain/entities/notification_settings.dart';
import 'package:azkarna/features/notifications/domain/usecases/sync_notifications.dart';
import 'package:azkarna/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:azkarna/features/prayer_times/domain/entities/prayer_times.dart';
import 'package:azkarna/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Scheduler extends NoopNotificationScheduler {
  Duration? before;
  int scheduled = 0;
  int cancels = 0;

  @override
  Future<void> schedulePrayerReminders(
    List<PrayerTimes> days, {
    required Duration before,
  }) async {
    this.before = before;
    scheduled++;
  }

  @override
  Future<void> cancelPrayerReminders() async => cancels++;
}

class _Repo implements PrayerTimesRepository {
  int? requestedDays;

  @override
  Future<PrayerTimes> getTodayPrayerTimes(PrayerLocation location) async =>
      (await getUpcomingPrayerTimes(location, days: 1)).first;

  @override
  Future<List<PrayerTimes>> getUpcomingPrayerTimes(
    PrayerLocation location, {
    int days = 7,
  }) async {
    requestedDays ??= days;
    return [
      PrayerTimes(
        location: 'حائل',
        timeZone: 'Asia/Riyadh',
        utcOffset: const Duration(hours: 3),
        date: DateTime(2030, 1, 1),
        hijriDate: '',
        times: {Prayer.dhuhr: DateTime(2030, 1, 1, 12)},
      ),
    ];
  }
}

Future<(_Scheduler, _Repo)> _run(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final scheduler = _Scheduler();
  final repo = _Repo();
  await SyncNotifications(
    NotificationSettingsRepositoryImpl(
      SharedPrefsNotificationSettingsDataSource(p),
    ),
    repo,
    scheduler,
  )(PrayerLocation.hail);
  return (scheduler, repo);
}

void main() {
  test('off by default: nothing scheduled, old alerts cancelled', () async {
    final (s, _) = await _run({});
    expect(s.scheduled, 0);
    expect(s.cancels, 1);
  });

  test('scheduled with the chosen minutes, fewer days ahead', () async {
    final (s, repo) = await _run({
      'notif_before_prayer_enabled': true,
      'notif_before_prayer_min': 20,
    });
    expect(s.before, const Duration(minutes: 20));
    expect(repo.requestedDays, SyncNotifications.adhanDaysWithBefore);
  });

  test('an unknown saved value falls back to the default', () async {
    final (s, _) = await _run({
      'notif_before_prayer_enabled': true,
      'notif_before_prayer_min': 7,
    });
    expect(
      s.before,
      const Duration(minutes: PrayerReminderLead.defaultMinutes),
    );
  });
}
