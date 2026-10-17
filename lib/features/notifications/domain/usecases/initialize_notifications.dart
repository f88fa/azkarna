import '../../../prayer_times/domain/entities/prayer_location.dart';
import '../repositories/notification_settings_repository.dart';
import '../services/notification_scheduler.dart';
import 'sync_notifications.dart';

/// App-startup flow: ask for permission once, then schedule everything.
class InitializeNotifications {
  const InitializeNotifications(this._settings, this._scheduler, this._sync);

  final NotificationSettingsRepository _settings;
  final NotificationScheduler _scheduler;
  final SyncNotifications _sync;

  Future<void> call(PrayerLocation location) async {
    if (!await _settings.hasRequestedPermission()) {
      await _scheduler.requestPermissions(includeExactAlarms: true);
      await _settings.markPermissionRequested();
    }
    await _sync(location);
  }
}
