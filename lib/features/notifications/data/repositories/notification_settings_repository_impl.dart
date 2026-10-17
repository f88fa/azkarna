import '../../domain/entities/notification_settings.dart';
import '../../domain/repositories/notification_settings_repository.dart';
import '../datasources/notification_settings_local_data_source.dart';

class NotificationSettingsRepositoryImpl
    implements NotificationSettingsRepository {
  const NotificationSettingsRepositoryImpl(this._local);

  final NotificationSettingsLocalDataSource _local;

  @override
  Future<NotificationSettings> getSettings() => _local.getSettings();

  @override
  Future<void> saveSettings(NotificationSettings settings) =>
      _local.saveSettings(settings);

  @override
  Future<bool> hasRequestedPermission() => _local.hasRequestedPermission();

  @override
  Future<void> markPermissionRequested() => _local.markPermissionRequested();
}
