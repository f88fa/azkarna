import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../prayer_times/domain/entities/prayer_times.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/services/notification_scheduler.dart';

class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const int _khatmahId = 1;
  static const int _adhanIdBase = 1000;
  static const int _idsPerDay = 10;

  static const NotificationDetails _adhanDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'adhan',
      'Prayer times',
      channelDescription: 'Adhan alerts at each prayer time',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  static const NotificationDetails _khatmahDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'khatmah',
      'Khatmah reminder',
      channelDescription: 'Daily Quran reading reminder',
      importance: Importance.high,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  /// Must be awaited once before the app starts.
  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Keep the default (UTC) if the device zone cannot be resolved.
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<bool> requestPermissions({bool includeExactAlarms = false}) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission() ?? false;
      if (granted &&
          includeExactAlarms &&
          !(await android.canScheduleExactNotifications() ?? true)) {
        await android.requestExactAlarmsPermission();
      }
      return granted;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  @override
  Future<void> scheduleAdhan(List<PrayerTimes> days) async {
    await cancelAdhan();

    for (var dayIndex = 0; dayIndex < days.length; dayIndex++) {
      final day = days[dayIndex];
      final location = _locationFor(day.timeZone);
      final now = tz.TZDateTime.now(location);

      for (var i = 0; i < Prayer.adhanPrayers.length; i++) {
        final prayer = Prayer.adhanPrayers[i];
        final time = day.times[prayer];
        if (time == null) continue;

        final when = tz.TZDateTime(
          location,
          time.year,
          time.month,
          time.day,
          time.hour,
          time.minute,
        );
        if (!when.isAfter(now)) continue;

        await _schedule(
          id: _adhanIdBase + dayIndex * _idsPerDay + i,
          title: prayer.label,
          body: 'It is time for ${prayer.label} prayer · ${day.location}',
          when: when,
          details: _adhanDetails,
        );
      }
    }
  }

  @override
  Future<void> cancelAdhan() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id >= _adhanIdBase) await _plugin.cancel(id: request.id);
    }
  }

  @override
  Future<void> scheduleDailyKhatmahReminder(ReminderTime time) async {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));

    await _schedule(
      id: _khatmahId,
      title: 'Daily Khatmah',
      body: 'Take a few minutes to read your daily Quran goal.',
      when: when,
      details: _khatmahDetails,
      repeatDaily: true,
    );
  }

  @override
  Future<void> cancelKhatmahReminder() => _plugin.cancel(id: _khatmahId);

  tz.Location _locationFor(String name) {
    try {
      return tz.getLocation(name);
    } catch (_) {
      return tz.local;
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
    bool repeatDaily = false,
  }) async {
    Future<void> run(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: details,
      androidScheduleMode: mode,
      matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
    );

    try {
      await run(AndroidScheduleMode.exactAllowWhileIdle);
    } on PlatformException catch (e) {
      if (e.code != 'exact_alarms_not_permitted') rethrow;
      // Exact alarms not granted: fall back to a best-effort alarm.
      await run(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }
}
