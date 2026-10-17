import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/adhkar_category.dart';

class DhikrCounterCard extends StatelessWidget {
  const DhikrCounterCard({
    super.key,
    required this.dhikr,
    required this.current,
    required this.onTap,
  });

  final Dhikr dhikr;
  final int current;
  final VoidCallback onTap;

  bool get _done => current >= dhikr.count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _done
            ? primary.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _done
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap();
              },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                dhikr.text,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 24, height: 1.9),
              ),
              if (dhikr.translation.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  dhikr.translation,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: secondary),
                ),
              ],
              if (dhikr.reference.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  dhikr.reference,
                  style: theme.textTheme.labelSmall?.copyWith(color: secondary),
                ),
              ],
              const SizedBox(height: 16),
              _CounterBadge(current: current, target: dhikr.count, done: _done),
            ],
          ),
        ),
      ),
    );
  }
}

class _CounterBadge extends StatelessWidget {
  const _CounterBadge({
    required this.current,
    required this.target,
    required this.done,
  });

  final int current;
  final int target;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: current / target),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                backgroundColor: primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: done
                ? Icon(
                    Icons.check_rounded,
                    key: const ValueKey('done'),
                    size: 32,
                    color: primary,
                  )
                : Text(
                    '$current/$target',
                    key: ValueKey(current),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
