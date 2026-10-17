import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prayer_times/presentation/providers/prayer_times_providers.dart';
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
    final last = _lastSync;
    if (last == null || DateTime.now().difference(last) > _minSyncInterval) {
      _sync();
    }
  }

  /// Reload the prayer card when it shows a past day or offline data.
  void _refreshPrayerTimesIfStale() {
    final times = ref.read(prayerTimesProvider);
    final value = times.asData?.value;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (times.hasError ||
        (value != null && (value.isCached || value.date != today))) {
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
  Widget build(BuildContext context) => widget.child;
}
