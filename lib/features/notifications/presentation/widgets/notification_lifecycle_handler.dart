import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prayer_times/presentation/providers/prayer_times_providers.dart';
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
    final tasks = ref.read(tasksProvider).asData?.value;
    if (tasks != null) _syncTaskReminders(tasks);
    final last = _lastSync;
    if (last == null || DateTime.now().difference(last) > _minSyncInterval) {
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

  Future<void> _bootstrap() async {
    _lastSync = DateTime.now();
    try {
      await ref
          .read(initializeNotificationsProvider)
          .call(ref.read(prayerLocationProvider));
    } catch (_) {
      // Notifications are best-effort and must never block the app.
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
      if (previous != next) _sync();
    });
    // Keep task reminders in line with the task list.
    ref.listen(tasksProvider, (previous, next) {
      final tasks = next.asData?.value;
      if (tasks != null) _syncTaskReminders(tasks);
    });
    return widget.child;
  }
}
