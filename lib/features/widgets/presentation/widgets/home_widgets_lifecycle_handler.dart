import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../khatmah/presentation/providers/khatmah_providers.dart';
import '../../../prayer_times/presentation/providers/prayer_times_providers.dart';
import '../providers/widget_providers.dart';

/// Keeps the iOS home / lock screen widgets in line with the app: when it
/// starts, comes back to the foreground, or the data they show changes.
class HomeWidgetsLifecycleHandler extends ConsumerStatefulWidget {
  const HomeWidgetsLifecycleHandler({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HomeWidgetsLifecycleHandler> createState() =>
      _HomeWidgetsLifecycleHandlerState();
}

class _HomeWidgetsLifecycleHandlerState
    extends ConsumerState<HomeWidgetsLifecycleHandler>
    with WidgetsBindingObserver {
  static const Duration _debounce = Duration(seconds: 2);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Also when leaving: the widgets should show the latest reading progress.
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.paused) {
      _schedule();
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(_debounce, _sync);
  }

  void _sync() {
    if (!mounted) return;
    unawaited(ref.read(syncHomeWidgetsProvider)());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(prayerOffsetsProvider, (previous, next) {
      if (previous != next) _schedule();
    });
    ref.listen(khatmahProvider, (previous, next) {
      if (next.hasValue) _schedule();
    });
    return widget.child;
  }
}
