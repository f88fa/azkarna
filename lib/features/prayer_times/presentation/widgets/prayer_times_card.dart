import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/prayer_times.dart';
import '../providers/prayer_times_providers.dart';

const _gradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0A7C66), Color(0xFF064E40)],
);

class PrayerTimesCard extends ConsumerWidget {
  const PrayerTimesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prayerTimesProvider);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: _gradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A7C66).withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: state.when(
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

class _Content extends StatelessWidget {
  const _Content({super.key, required this.times});

  final PrayerTimes times;

  @override
  Widget build(BuildContext context) {
    final next = times.nextPrayer(DateTime.now());
    final dateLabel = DateFormat('EEEE, d MMM').format(times.date);

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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (times.isCached) const _OfflineBadge(),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          next == null ? 'Prayers completed' : 'Next: ${next.label}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
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

class _Row extends StatelessWidget {
  const _Row({required this.prayers, required this.times, required this.next});

  final List<Prayer> prayers;
  final PrayerTimes times;
  final Prayer? next;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('h:mm a');
    return Row(
      children: [
        for (var i = 0; i < prayers.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _Tile(
              label: prayers[i].label,
              time: format.format(times.times[prayers[i]]!),
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
            ? Colors.white
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: highlighted ? const Color(0xFF0A7C66) : Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: highlighted ? const Color(0xFF064E40) : Colors.white,
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

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Offline',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
