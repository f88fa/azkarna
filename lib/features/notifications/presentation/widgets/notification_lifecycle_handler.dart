import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../../prayer_times/domain/entities/saudi_city.dart';
import '../../../prayer_times/presentation/providers/location_providers.dart';
import '../../../prayer_times/presentation/providers/prayer_times_providers.dart';
import '../../../prayer_widget/prayer_widget_sync.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../providers/notification_providers.dart';

/// Requests permission on first launch and keeps the scheduled Adhan
/// notifications topped up whenever the app starts or returns to the
/// foreground.
class NotificationLifecycleHandler extends ConsumerStatefulWidget {
  const NotificationLifecycleHandler({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationLifecycleHandler> createState() =>
      _NotificationLifecycleHandlerState();
}

class _NotificationLifecycleHandlerState
    extends ConsumerState<NotificationLifecycleHandler>
    with WidgetsBindingObserver {
  static const Duration _minSyncInterval = Duration(hours: 6);
  static const Duration _dhikrSyncInterval = Duration(minutes: 10);

  DateTime? _lastSync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _refreshPrayerTimesIfStale();
    _syncWidget();
    _checkLocation();
    final tasks = ref.read(tasksProvider).asData?.value;
    if (tasks != null) _syncTaskReminders(tasks);
    // Periodic dhikr reminders are scheduled a few hours ahead only (OS cap on
    // pending notifications), so top them up much more often.
    final dhikrOn =
        ref.read(notificationSettingsProvider).asData?.value.dhikr.enabled ??
        false;
    final interval = dhikrOn ? _dhikrSyncInterval : _minSyncInterval;
    final last = _lastSync;
    if (last == null || DateTime.now().difference(last) > interval) {
      _sync();
    }
  }

  /// Reload the prayer card when it shows a past day.
  void _refreshPrayerTimesIfStale() {
    final times = ref.read(prayerTimesProvider);
    final value = times.asData?.value;
    final today = ref.read(prayerLocationProvider).today();
    if (times.hasError || (value != null && value.date != today)) {
      ref.invalidate(prayerTimesProvider);
    }
  }

  /// Refreshes the prayer times shown by the iOS widget.
  void _syncWidget() {
    PrayerWidgetSync(
      ref.read(prayerTimesRepositoryProvider),
    ).call(ref.read(prayerLocationProvider));
  }

  Future<void> _bootstrap() async {
    _syncWidget();
    _lastSync = DateTime.now();
    try {
      await ref
          .read(initializeNotificationsProvider)
          .call(ref.read(prayerLocationProvider));
    } catch (_) {
      // Notifications are best-effort and must never block the app.
    }
    await _checkLocation();
  }

  bool _checkingLocation = false;
  DateTime? _lastLocationCheck;

  /// Follows the device in auto mode; in manual mode asks once per new city
  /// whether the user moved there.
  Future<void> _checkLocation() async {
    if (_checkingLocation) return;
    final last = _lastLocationCheck;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(minutes: 2)) {
      return;
    }
    _checkingLocation = true;
    _lastLocationCheck = DateTime.now();
    try {
      final notifier = ref.read(locationProvider.notifier);
      final outcome = await notifier.refreshIfAuto();
      if (!mounted) return;
      if (outcome is LocationUpdated && outcome.cityChanged) {
        rootMessengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              content: Text(
                'موقعك الآن ${outcome.location.city}، '
                'وحُدّثت مواقيت الصلاة والأذان.',
              ),
            ),
          );
        return;
      }
      if (outcome != null) return;
      final moved = await notifier.detectMovedCity();
      if (moved == null || !mounted) return;
      await _askMoved(moved);
    } catch (_) {
      // Location is best-effort.
    } finally {
      _checkingLocation = false;
    }
  }

  Future<void> _askMoved(SaudiCity city) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    final current = ref.read(prayerLocationProvider).city;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.location_on_rounded),
        title: Text('هل انتقلت إلى ${city.name}؟'),
        content: Text(
          'يظهر موقعك الحالي في ${city.name}، والمواقيت الآن لمدينة $current. '
          'هل تريد تحديث مواقيت الصلاة إلى ${city.name}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('لا، أبقِها'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('نعم، حدّث المواقيت'),
          ),
        ],
      ),
    );
    final notifier = ref.read(locationProvider.notifier);
    if (yes == true) {
      await notifier.setManual(city);
    } else if (yes == false) {
      await notifier.declineMove(city);
    }
  }

  Future<void> _taskSync = Future<void>.value();

  /// Re-schedules task reminders; calls are serialized so rapid edits cannot
  /// interleave.
  void _syncTaskReminders(List<Task> tasks) {
    _taskSync = _taskSync.then((_) async {
      try {
        await ref
            .read(notificationSchedulerProvider)
            .replaceTaskReminders(tasks);
      } catch (_) {
        // Best-effort.
      }
    });
  }

  Future<void> _sync() async {
    _lastSync = DateTime.now();
    try {
      await ref
          .read(syncNotificationsProvider)
          .call(ref.read(prayerLocationProvider));
    } catch (_) {
      // Best-effort.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-schedule the Adhan notifications whenever a manual offset changes.
    ref.listen(prayerOffsetsProvider, (previous, next) {
      if (previous != next) {
        _sync();
        _syncWidget();
      }
    });
    // …and whenever the location (city or GPS fix) changes.
    ref.listen(prayerLocationProvider, (previous, next) {
      if (previous == null ||
          previous.latitude != next.latitude ||
          previous.longitude != next.longitude) {
        _sync();
        _syncWidget();
      }
    });
    // Keep task reminders in line with the task list.
    ref.listen(tasksProvider, (previous, next) {
      final tasks = next.asData?.value;
      if (tasks != null) _syncTaskReminders(tasks);
    });
    return widget.child;
  }
}
