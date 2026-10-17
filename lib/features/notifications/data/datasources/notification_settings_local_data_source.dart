import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _khatmahKey = 'notif_khatmah_enabled';
  static const String _hourKey = 'notif_khatmah_hour';
  static const String _minuteKey = 'notif_khatmah_minute';
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
      khatmahReminderEnabled:
          _prefs.getBool(_khatmahKey) ?? defaults.khatmahReminderEnabled,
      khatmahReminderTime: validTime
          ? ReminderTime(hour: hour, minute: minute)
          : defaults.khatmahReminderTime,
    );
  }

  @override
  Future<void> saveSettings(NotificationSettings settings) async {
    await _prefs.setBool(_adhanKey, settings.adhanEnabled);
    await _prefs.setBool(_khatmahKey, settings.khatmahReminderEnabled);
    await _prefs.setInt(_hourKey, settings.khatmahReminderTime.hour);
    await _prefs.setInt(_minuteKey, settings.khatmahReminderTime.minute);
  }

  @override
  Future<bool> hasRequestedPermission() async =>
      _prefs.getBool(_askedKey) ?? false;

  @override
  Future<void> markPermissionRequested() async {
    await _prefs.setBool(_askedKey, true);
  }
}
