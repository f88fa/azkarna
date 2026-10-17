import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/prayer_times.dart';
import '../providers/prayer_times_providers.dart';

/// Home hero: live countdown to the next prayer (or time elapsed since the
/// one that just passed), progress between the two, all six times and the
/// night portions. The sky colors follow the current part of the day.
class PrayerTimesCard extends ConsumerWidget {
  const PrayerTimesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prayerTimesProvider);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: state.when(
          skipLoadingOnReload: true,
          loading: () => const _Shell(
            key: ValueKey('loading'),
            colors: _night,
            child: _Loading(),
          ),
          error: (error, _) => _Shell(
            key: const ValueKey('error'),
            colors: _night,
            child: _Error(
              info: ErrorInfo.from(error),
              onRetry: () => ref.invalidate(prayerTimesProvider),
            ),
          ),
          data: (times) => _Content(key: const ValueKey('data'), times: times),
        ),
      ),
    );
  }
}

// Sky palettes (top-right → bottom-left).
const _dawn = [Color(0xFF5B4BB7), Color(0xFFD0689B)];
const _morning = [Color(0xFF1B7FC4), Color(0xFF53B7D8)];
const _noon = [Color(0xFF0A7C66), Color(0xFF2CB89B)];
const _afternoon = [Color(0xFFD9731E), Color(0xFFB8452E)];
const _dusk = [Color(0xFF7A4DC8), Color(0xFF3A57D6)];
const _night = [Color(0xFF0C1F4D), Color(0xFF1D3B7C)];

class _Shell extends StatelessWidget {
  const _Shell({super.key, required this.colors, required this.child});

  final List<Color> colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.38),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative soft circles.
          PositionedDirectional(
            top: -90,
            end: -70,
            child: _Orb(size: 230, alpha: 0.10),
          ),
          PositionedDirectional(
            bottom: -110,
            start: -80,
            child: _Orb(size: 260, alpha: 0.07),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    ),
  );
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
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
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

  static const _elapsedWindow = Duration(minutes: 30);
  static const _day = Duration(days: 1);

  @override
  Widget build(BuildContext context) {
    final times = widget.times;
    final now = times.wallClockNow;
    final t = times.times;

    // The prayer that last started (before Fajr: yesterday's Isha, taken as
    // today's Isha minus a day) and the one coming up (after Isha: tomorrow's
    // Fajr, taken as today's plus a day).
    Prayer prev = Prayer.isha;
    DateTime prevTime = t[Prayer.isha]!.subtract(_day);
    for (final p in Prayer.values) {
      if (!t[p]!.isAfter(now)) {
        prev = p;
        prevTime = t[p]!;
      }
    }
    final upcoming = times.nextPrayer(now);
    final next = upcoming ?? Prayer.fajr;
    final nextTime = upcoming == null ? t[Prayer.fajr]!.add(_day) : t[next]!;

    final sincePrev = now.difference(prevTime);
    final showElapsed = prev != Prayer.sunrise && sincePrev < _elapsedWindow;
    final total = nextTime.difference(prevTime).inSeconds;
    final progress = total <= 0
        ? 0.0
        : (sincePrev.inSeconds / total).clamp(0.0, 1.0);

    final nightStart = t[Prayer.maghrib]!;
    final nightEnd = t[Prayer.fajr]!.add(_day);
    final nightLength = nightEnd.difference(nightStart);
    final midnight = nightStart.add(nightLength ~/ 2);
    final lastThird = nightEnd.subtract(nightLength ~/ 3);

    final colors = switch (prev) {
      Prayer.fajr => _dawn,
      Prayer.sunrise => _morning,
      Prayer.dhuhr => _noon,
      Prayer.asr => _afternoon,
      Prayer.maghrib => _dusk,
      Prayer.isha => _night,
    };

    final dateLabel = arDate('EEEE، d MMMM', times.date);

    return _Shell(
      colors: colors,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.near_me_rounded,
                size: 15,
                color: Colors.white70,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  times.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const _Pill('أم القرى'),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Text(
              showElapsed ? 'مضى على ${prev.label}' : 'متبقي على ${next.label}',
              key: ValueKey(showElapsed ? 'e${prev.name}' : 'r${next.name}'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          _Countdown(
            times: times,
            anchor: showElapsed ? prevTime : nextTime,
            elapsed: showElapsed,
            onCrossed: () {
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 14),
          _Progress(
            value: progress,
            startLabel: '${prev.label}  ${_hm(prevTime)}',
            endLabel: '${next.label}  ${_hm(nextTime)}',
          ),
          const SizedBox(height: 18),
          _PrayerRow(times: times, next: upcoming),
          const SizedBox(height: 14),
          _NightInfo(midnight: midnight, lastThird: lastThird),
          const SizedBox(height: 12),
          Text(
            times.hijriDate.isEmpty
                ? dateLabel
                : '$dateLabel  •  ${times.hijriDate}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The ticking HH:MM:SS. It owns its one-second timer and repaint boundary so
/// only these digits repaint every second, not the whole hero card.
class _Countdown extends StatefulWidget {
  const _Countdown({
    required this.times,
    required this.anchor,
    required this.elapsed,
    required this.onCrossed,
  });

  final PrayerTimes times;
  final DateTime anchor;

  /// Count up since [anchor] (true) or down until it (false).
  final bool elapsed;
  final VoidCallback onCrossed;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _ticker;
  late Duration _shown = _compute();

  Duration _compute() {
    final now = widget.times.wallClockNow;
    return widget.elapsed
        ? now.difference(widget.anchor)
        : widget.anchor.difference(now);
  }

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = _compute();
      final crossed = widget.elapsed
          ? next >= const Duration(minutes: 30)
          : next <= Duration.zero;
      setState(() => _shown = next.isNegative ? Duration.zero : next);
      if (crossed) widget.onCrossed();
    });
  }

  @override
  void didUpdateWidget(_Countdown old) {
    super.didUpdateWidget(old);
    _shown = _compute();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          _clock(_shown),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 54,
            height: 1.15,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.5,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

String _clock(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  return '${arTwo(h)}:${arTwo(m)}:${arTwo(s)}';
}

String _hm(DateTime t) => arTime(t);

class _Pill extends StatelessWidget {
  const _Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.value,
    required this.startLabel,
    required this.endLabel,
  });

  final double value;
  final String startLabel;
  final String endLabel;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white,
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
    );
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(height: 7, color: Colors.white.withValues(alpha: 0.25)),
              // Fills from the start (right in RTL) towards the next prayer.
              FractionallySizedBox(
                widthFactor: value,
                alignment: AlignmentDirectional.centerStart,
                child: Container(height: 7, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Text(startLabel, style: style),
            const Spacer(),
            Text(endLabel, style: style),
          ],
        ),
      ],
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({required this.times, required this.next});

  final PrayerTimes times;
  final Prayer? next;

  static const _icons = <Prayer, IconData>{
    Prayer.fajr: Icons.nights_stay_rounded,
    Prayer.sunrise: Icons.wb_twilight_rounded,
    Prayer.dhuhr: Icons.light_mode_rounded,
    Prayer.asr: Icons.wb_sunny_outlined,
    Prayer.maghrib: Icons.wb_twilight_rounded,
    Prayer.isha: Icons.bedtime_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          for (final prayer in Prayer.values)
            Expanded(
              child: _PrayerCell(
                label: prayer.label,
                icon: _icons[prayer]!,
                time: arDate('h:mm', times.times[prayer]!),
                period: arDate('a', times.times[prayer]!),
                highlighted: prayer == next,
              ),
            ),
        ],
      ),
    );
  }
}

class _PrayerCell extends StatelessWidget {
  const _PrayerCell({
    required this.label,
    required this.icon,
    required this.time,
    required this.period,
    required this.highlighted,
  });

  final String label;
  final IconData icon;
  final String time;
  final String period;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final fg = highlighted
        ? Colors.white
        : Colors.white.withValues(alpha: 0.92);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: highlighted
            ? Colors.white.withValues(alpha: 0.28)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: fg),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
              color: fg,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ),
          Text(
            period,
            style: TextStyle(fontSize: 10.5, color: fg.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

class _NightInfo extends StatelessWidget {
  const _NightInfo({required this.midnight, required this.lastThird});

  final DateTime midnight;
  final DateTime lastThird;

  @override
  Widget build(BuildContext context) {
    Widget item(String label, DateTime t) => Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          const SizedBox(width: 6),
          Text(
            arTime(t),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return Row(
      children: [
        item('منتصف الليل', midnight),
        Container(width: 1, height: 16, color: Colors.white30),
        item('الثلث الأخير', lastThird),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 220,
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
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
  const _Error({required this.info, required this.onRetry});

  final ErrorInfo info;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
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
