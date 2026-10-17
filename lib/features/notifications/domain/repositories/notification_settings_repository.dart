import '../entities/notification_settings.dart';

abstract interface class NotificationSettingsRepository {
  Future<NotificationSettings> getSettings();
  Future<void> saveSettings(NotificationSettings settings);

  /// Whether the first-run permission prompt has already been shown.
  Future<bool> hasRequestedPermission();
  Future<void> markPermissionRequested();
}
