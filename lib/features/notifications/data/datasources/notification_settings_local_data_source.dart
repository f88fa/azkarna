import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/adhan_sound.dart';
import '../../domain/entities/dhikr_reminder.dart';
import '../../domain/entities/notification_settings.dart';

abstract interface class NotificationSettingsLocalDataSource {
  Future<NotificationSettings> getSettings();
  Future<void> saveSettings(NotificationSettings settings);
  Future<bool> hasRequestedPermission();
  Future<void> markPermissionRequested();
}

class SharedPrefsNotificationSettingsDataSource
    implements NotificationSettingsLocalDataSource {
  const SharedPrefsNotificationSettingsDataSource(this._prefs);

  static const String _adhanKey = 'notif_adhan_enabled';
  static const String _morningKey = 'notif_adhkar_morning_enabled';
  static const String _eveningKey = 'notif_adhkar_evening_enabled';
  static const String _khatmahKey = 'notif_khatmah_enabled';
  static const String _hourKey = 'notif_khatmah_hour';
  static const String _minuteKey = 'notif_khatmah_minute';
  static const String _soundKey = 'notif_adhan_sound';
  static const String _dhikrOnKey = 'notif_dhikr_enabled';
  static const String _dhikrIntervalKey = 'notif_dhikr_interval_min';
  static const String _quietOnKey = 'notif_dhikr_quiet_enabled';
  static const String _quietStartKey = 'notif_dhikr_quiet_start';
  static const String _quietEndKey = 'notif_dhikr_quiet_end';
  static const String _askedKey = 'notif_permission_requested';

  final SharedPreferences _prefs;

  @override
  Future<NotificationSettings> getSettings() async {
    const defaults = NotificationSettings();
    final hour = _prefs.getInt(_hourKey);
    final minute = _prefs.getInt(_minuteKey);
    final validTime =
        hour != null &&
        minute != null &&
        hour >= 0 &&
        hour < 24 &&
        minute >= 0 &&
        minute < 60;

    return NotificationSettings(
      adhanEnabled: _prefs.getBool(_adhanKey) ?? defaults.adhanEnabled,
      morningAdhkarEnabled:
          _prefs.getBool(_morningKey) ?? defaults.morningAdhkarEnabled,
      eveningAdhkarEnabled:
          _prefs.getBool(_eveningKey) ?? defaults.eveningAdhkarEnabled,
      khatmahReminderEnabled:
          _prefs.getBool(_khatmahKey) ?? defaults.khatmahReminderEnabled,
      khatmahReminderTime: validTime
          ? ReminderTime(hour: hour, minute: minute)
          : defaults.khatmahReminderTime,
      adhanSound: AdhanSound.fromId(_prefs.getString(_soundKey)),
      dhikr: DhikrReminderSettings(
        enabled: _prefs.getBool(_dhikrOnKey) ?? defaults.dhikr.enabled,
        interval: DhikrInterval.fromMinutes(_prefs.getInt(_dhikrIntervalKey)),
        quietHoursEnabled:
            _prefs.getBool(_quietOnKey) ?? defaults.dhikr.quietHoursEnabled,
        quietStart: _minutesToTime(
          _prefs.getInt(_quietStartKey),
          defaults.dhikr.quietStart,
        ),
        quietEnd: _minutesToTime(
          _prefs.getInt(_quietEndKey),
          defaults.dhikr.quietEnd,
        ),
      ),
    );
  }

  static ReminderTime _minutesToTime(int? minutes, ReminderTime fallback) {
    if (minutes == null || minutes < 0 || minutes >= 24 * 60) return fallback;
    return ReminderTime(hour: minutes ~/ 60, minute: minutes % 60);
  }

  @override
  Future<void> saveSettings(NotificationSettings settings) async {
    await _prefs.setBool(_adhanKey, settings.adhanEnabled);
    await _prefs.setBool(_morningKey, settings.morningAdhkarEnabled);
    await _prefs.setBool(_eveningKey, settings.eveningAdhkarEnabled);
    await _prefs.setBool(_khatmahKey, settings.khatmahReminderEnabled);
    await _prefs.setInt(_hourKey, settings.khatmahReminderTime.hour);
    await _prefs.setInt(_minuteKey, settings.khatmahReminderTime.minute);
    await _prefs.setString(_soundKey, settings.adhanSound.id);
    final d = settings.dhikr;
    await _prefs.setBool(_dhikrOnKey, d.enabled);
    await _prefs.setInt(_dhikrIntervalKey, d.interval.minutes);
    await _prefs.setBool(_quietOnKey, d.quietHoursEnabled);
    await _prefs.setInt(
      _quietStartKey,
      d.quietStart.hour * 60 + d.quietStart.minute,
    );
    await _prefs.setInt(_quietEndKey, d.quietEnd.hour * 60 + d.quietEnd.minute);
  }

  @override
  Future<bool> hasRequestedPermission() async =>
      _prefs.getBool(_askedKey) ?? false;

  @override
  Future<void> markPermissionRequested() async {
    await _prefs.setBool(_askedKey, true);
  }
}
