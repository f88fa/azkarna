import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../prayer_times/domain/entities/prayer_times.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/services/notification_scheduler.dart';

class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const int _khatmahId = 1;
  // Adhkar reminders: 2 ids per day, in [_adhkarIdBase, _adhanIdBase).
  static const int _adhkarIdBase = 500;
  static const int _adhanIdBase = 1000;
  static const int _idsPerDay = 10;
  // Task reminder ids live above every Adhan id.
  static const int _taskIdBase = 1000000;

  static const NotificationDetails _adhanDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'adhan',
      'مواقيت الصلاة',
      channelDescription: 'تنبيهات الأذان عند كل صلاة',
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

  static const NotificationDetails _adhkarDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'adhkar',
      'تذكير الأذكار',
      channelDescription: 'تذكير بأذكار الصباح والمساء',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  static const NotificationDetails _taskDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'tasks',
      'تذكير المهام',
      channelDescription: 'تنبيه عند وقت المهمة',
      importance: Importance.high,
      priority: Priority.high,
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
      'تذكير الختمة',
      channelDescription: 'تذكير يومي بقراءة وردك من القرآن',
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
          title: 'حان وقت صلاة ${prayer.label}',
          body: 'حان الآن موعد أذان ${prayer.label} · ${day.location}',
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
      if (request.id >= _adhanIdBase && request.id < _taskIdBase) {
        await _plugin.cancel(id: request.id);
      }
    }
  }

  @override
  Future<void> scheduleAdhkarReminders(
    List<PrayerTimes> days, {
    required bool morning,
    required bool evening,
  }) async {
    await cancelAdhkarReminders();

    for (var dayIndex = 0; dayIndex < days.length; dayIndex++) {
      final day = days[dayIndex];
      final location = _locationFor(day.timeZone);
      final now = tz.TZDateTime.now(location);

      final slots = [
        if (morning)
          (
            slot: 0,
            prayer: Prayer.fajr,
            delay: AdhkarReminderDelays.morningAfterFajr,
            title: 'أذكار الصباح',
            body: 'ابدأ يومك بذكر الله · أذكار الصباح',
          ),
        if (evening)
          (
            slot: 1,
            prayer: Prayer.asr,
            delay: AdhkarReminderDelays.eveningAfterAsr,
            title: 'أذكار المساء',
            body: 'حان وقت أذكار المساء، لا تنسَ وردك',
          ),
      ];

      for (final item in slots) {
        final time = day.times[item.prayer];
        if (time == null) continue;
        final when = tz.TZDateTime(
          location,
          time.year,
          time.month,
          time.day,
          time.hour,
          time.minute,
        ).add(item.delay);
        if (!when.isAfter(now)) continue;

        await _schedule(
          id: _adhkarIdBase + dayIndex * 2 + item.slot,
          title: item.title,
          body: item.body,
          when: when,
          details: _adhkarDetails,
        );
      }
    }
  }

  @override
  Future<void> cancelAdhkarReminders() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id >= _adhkarIdBase && request.id < _adhanIdBase) {
        await _plugin.cancel(id: request.id);
      }
    }
  }

  @override
  Future<void> replaceTaskReminders(List<Task> tasks) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id >= _taskIdBase) await _plugin.cancel(id: request.id);
    }

    final now = tz.TZDateTime.now(tz.local);
    for (final task in tasks) {
      final minutes = task.timeMinutes;
      if (!task.remind || minutes == null) continue;
      final hour = minutes ~/ 60;
      final minute = minutes % 60;
      final idBase = _taskIdBase + (_stableHash(task.id) % 100000) * 10;
      final due = task.dueDate;

      if (!task.isRepeating) {
        if (task.isCompleted) continue;
        final when = tz.TZDateTime(
          tz.local,
          due.year,
          due.month,
          due.day,
          hour,
          minute,
        );
        if (!when.isAfter(now)) continue;
        await _schedule(
          id: idBase,
          title: task.title,
          body: 'حان موعد مهمتك',
          when: when,
          details: _taskDetails,
        );
        continue;
      }

      // Repeating: one weekly notification per chosen weekday, starting no
      // earlier than the task's first day.
      final startDay = due.isAfter(now) ? due : now;
      for (final weekday in task.repeatDays) {
        tz.TZDateTime? when;
        for (var offset = 0; offset < 8 && when == null; offset++) {
          final candidate = tz.TZDateTime(
            tz.local,
            startDay.year,
            startDay.month,
            startDay.day + offset,
            hour,
            minute,
          );
          if (candidate.weekday == weekday && candidate.isAfter(now)) {
            when = candidate;
          }
        }
        if (when == null) continue;
        await _schedule(
          id: idBase + weekday,
          title: task.title,
          body: 'حان موعد مهمتك',
          when: when,
          details: _taskDetails,
          match: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  /// Deterministic string hash (String.hashCode is not guaranteed stable).
  static int _stableHash(String value) {
    var hash = 17;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
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
      title: 'الختمة اليومية',
      body: 'خصّص دقائق لقراءة وردك اليومي من القرآن الكريم.',
      when: when,
      details: _khatmahDetails,
      match: DateTimeComponents.time,
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
    DateTimeComponents? match,
  }) async {
    Future<void> run(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: details,
      androidScheduleMode: mode,
      matchDateTimeComponents: match,
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
