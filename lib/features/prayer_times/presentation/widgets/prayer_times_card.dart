import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/prayer_times.dart';
import '../providers/prayer_times_providers.dart';

class PrayerTimesCard extends ConsumerWidget {
  const PrayerTimesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prayerTimesProvider);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: GlassCard(
        tint: AppColors.primary,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: state.when(
            skipLoadingOnReload: true,
            loading: () => const _Loading(key: ValueKey('loading')),
            error: (error, _) => _Error(
              key: const ValueKey('error'),
              info: ErrorInfo.from(error),
              onRetry: () => ref.invalidate(prayerTimesProvider),
            ),
            data: (times) =>
                _Content(key: const ValueKey('data'), times: times),
          ),
        ),
      ),
    );
  }
}

class _Content extends ConsumerStatefulWidget {
  const _Content({super.key, required this.times});

  final PrayerTimes times;

  @override
  ConsumerState<_Content> createState() => _ContentState();
}

class _ContentState extends ConsumerState<_Content> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = widget.times.wallClockNow;
      final today = DateTime(now.year, now.month, now.day);
      if (today != widget.times.date) {
        // A new day started: recompute the schedule.
        ref.invalidate(prayerTimesProvider);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _countdown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${arTwo(h)}:${arTwo(m)}:${arTwo(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final times = widget.times;
    final now = times.wallClockNow;
    final next = times.nextPrayer(now);
    final dateLabel = arDate('EEEE، d MMMM', times.date);
    final remaining = next == null ? null : times.times[next]!.difference(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 16,
              color: Colors.white70,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                times.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const _MethodBadge(),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                next == null
                    ? 'انتهت صلوات اليوم'
                    : 'الصلاة القادمة: ${next.label}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (remaining != null)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  _countdown(remaining),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          times.hijriDate.isEmpty
              ? dateLabel
              : '$dateLabel · ${times.hijriDate}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 18),
        _Row(prayers: Prayer.values.sublist(0, 3), times: times, next: next),
        const SizedBox(height: 8),
        _Row(prayers: Prayer.values.sublist(3), times: times, next: next),
      ],
    );
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'أم القرى',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.prayers, required this.times, required this.next});

  final List<Prayer> prayers;
  final PrayerTimes times;
  final Prayer? next;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < prayers.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _Tile(
              label: prayers[i].label,
              time: arTime(times.times[prayers[i]]!),
              highlighted: prayers[i] == next,
            ),
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.time,
    required this.highlighted,
  });

  final String label;
  final String time;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: highlighted
            ? Colors.white.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: highlighted ? AppColors.primary : Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: highlighted ? AppColors.primaryDeep : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 140,
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({super.key, required this.info, required this.onRetry});

  final ErrorInfo info;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(info.icon, color: Colors.white70, size: 32),
          const SizedBox(height: 8),
          Text(
            info.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            info.message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
