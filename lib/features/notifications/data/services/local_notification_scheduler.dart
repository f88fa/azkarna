import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../prayer_times/domain/entities/prayer_times.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../domain/entities/adhan_sound.dart';
import '../../domain/entities/dhikr_reminder.dart';
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
  // Periodic dhikr reminders: [_dhikrIdBase, _dhikrIdEnd).
  static const int _dhikrIdBase = 200000;
  static const int _dhikrIdEnd = 300000;
  // Test notifications sit between the dhikr ids and the task ids.
  static const int _testAdhanId = 300001;
  static const int _testDhikrId = 300002;
  // Friday Al-Kahf reminders: [_kahfIdBase, _kahfIdEnd).
  static const int _kahfIdBase = 300100;
  static const int _kahfIdEnd = 300200;
  // iOS keeps at most 64 pending local notifications.
  static const int _pendingLimit = 64;
  static const int _pendingSafety = 8;
  static const int _maxDhikrReminders = 40;
  // Task reminder ids live above every Adhan id.
  static const int _taskIdBase = 1000000;

  /// Adhan notification playing [sound]. iOS needs the bundled `.caf` file
  /// name; Android needs a channel per sound (a channel's sound is fixed once
  /// created) and the raw resource name.
  static NotificationDetails _adhanDetails(AdhanSound sound) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'adhan_${sound.file}',
          'الأذان · ${sound.label}',
          channelDescription: 'تنبيهات الأذان عند كل صلاة',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(sound.file),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          sound: sound.iosFile,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

  /// Periodic dhikr: the spoken recording of [message], or a silent
  /// notification when [sound] is off. Android needs one channel per sound
  /// (a channel's sound is fixed once created) plus one silent channel.
  static NotificationDetails _dhikrDetails(DhikrMessage message, bool sound) =>
      NotificationDetails(
        android: sound
            ? AndroidNotificationDetails(
                'dhikr_${message.sound}',
                'ذكر دوري · ${message.body.split(' · ').first}',
                channelDescription: 'تذكير دوري بالأذكار بصوت مسموع',
                importance: Importance.high,
                priority: Priority.high,
                playSound: true,
                sound: RawResourceAndroidNotificationSound(message.sound),
              )
            : const AndroidNotificationDetails(
                'dhikr_silent',
                'ذكر دوري · بدون صوت',
                channelDescription: 'تذكير دوري بالأذكار بإشعار صامت',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
                playSound: false,
                enableVibration: false,
              ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: sound,
          sound: sound ? message.iosFile : null,
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

  static const NotificationDetails _kahfDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'kahf',
      'تذكير سورة الكهف',
      channelDescription: 'تذكير يوم الجمعة بقراءة سورة الكهف قبل المغرب',
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
        android: AndroidInitializationSettings('ic_stat_awwab'),
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
  Future<void> scheduleAdhan(
    List<PrayerTimes> days, {
    required AdhanSound sound,
  }) async {
    await cancelAdhan();
    final details = _adhanDetails(sound);

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
          details: details,
        );
      }
    }
  }

  @override
  Future<void> cancelAdhan() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id >= _adhanIdBase && request.id < _dhikrIdBase) {
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
  Future<void> scheduleKahfReminders(
    List<PrayerTimes> fridays, {
    required Duration before,
  }) async {
    await cancelKahfReminders();
    for (var i = 0; i < fridays.length && i < _kahfIdEnd - _kahfIdBase; i++) {
      final day = fridays[i];
      final maghrib = day.times[Prayer.maghrib];
      if (maghrib == null) continue;
      final location = _locationFor(day.timeZone);
      final when = tz.TZDateTime(
        location,
        maghrib.year,
        maghrib.month,
        maghrib.day,
        maghrib.hour,
        maghrib.minute,
      ).subtract(before);
      if (!when.isAfter(tz.TZDateTime.now(location))) continue;
      await _schedule(
        id: _kahfIdBase + i,
        title: 'سورة الكهف · يوم الجمعة',
        body: 'لا تنسَ قراءة سورة الكهف قبل أذان المغرب',
        when: when,
        details: _kahfDetails,
      );
    }
  }

  @override
  Future<void> cancelKahfReminders() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id >= _kahfIdBase && request.id < _kahfIdEnd) {
        await _plugin.cancel(id: request.id);
      }
    }
  }

  @override
  Future<void> replacePeriodicDhikr(DhikrReminderSettings settings) async {
    await cancelPeriodicDhikr();
    if (!settings.enabled) return;

    // Leave room for everything else that is already pending (Adhan, Adhkar,
    // Khatmah, tasks) under the OS cap.
    final pending = await _plugin.pendingNotificationRequests();
    final others = pending
        .where((r) => r.id < _dhikrIdBase || r.id >= _dhikrIdEnd)
        .length;
    final budget = (_pendingLimit - _pendingSafety - others).clamp(
      0,
      _maxDhikrReminders,
    );
    if (budget == 0) return;

    final step = Duration(minutes: settings.interval.minutes);
    final now = tz.TZDateTime.now(tz.local);
    // Align to the interval boundary (e.g. :00 / :30) so reminders feel regular.
    final epochMinutes = now.millisecondsSinceEpoch ~/ 60000;
    final stepMinutes = settings.interval.minutes;
    var next = tz.TZDateTime.fromMillisecondsSinceEpoch(
      tz.local,
      ((epochMinutes ~/ stepMinutes) + 1) * stepMinutes * 60000,
    );
    final horizon = now.add(const Duration(days: 3));

    var scheduled = 0;
    while (scheduled < budget && next.isBefore(horizon)) {
      if (!settings.isQuiet(next.hour, next.minute)) {
        final message = DhikrMessages.at(
          next.millisecondsSinceEpoch ~/ 60000 ~/ stepMinutes,
        );
        await _schedule(
          id: _dhikrIdBase + scheduled,
          title: message.title,
          body: message.body,
          when: next,
          details: _dhikrDetails(message, settings.soundEnabled),
        );
        scheduled++;
      }
      next = next.add(step);
    }
  }

  @override
  Future<void> cancelPeriodicDhikr() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id >= _dhikrIdBase && request.id < _dhikrIdEnd) {
        await _plugin.cancel(id: request.id);
      }
    }
  }

  @override
  Future<void> scheduleTestAdhan(
    AdhanSound sound, {
    Duration delay = const Duration(seconds: 5),
  }) => _schedule(
    id: _testAdhanId,
    title: 'تجربة إشعار الأذان',
    body: sound.label,
    when: tz.TZDateTime.now(tz.local).add(delay),
    details: _adhanDetails(sound),
  );

  @override
  Future<void> scheduleTestDhikr({
    Duration delay = const Duration(seconds: 5),
    bool sound = true,
  }) {
    final message = DhikrMessages.at(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    return _schedule(
      id: _testDhikrId,
      title: message.title,
      body: message.body,
      when: tz.TZDateTime.now(tz.local).add(delay),
      details: _dhikrDetails(message, sound),
    );
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
