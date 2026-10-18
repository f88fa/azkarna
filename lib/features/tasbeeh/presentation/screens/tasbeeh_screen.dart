import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/popup_scaffold.dart';
import '../providers/tasbeeh_providers.dart';

/// Interactive tasbeeh / istighfar counter.
class TasbeehScreen extends ConsumerWidget {
  const TasbeehScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(tasbeehProvider);
    final notifier = ref.read(tasbeehProvider.notifier);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return PopupScaffold(
      title: 'المسبحة',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < tasbeehAdhkar.length; i++)
                  ChoiceChip(
                    label: Text(tasbeehAdhkar[i]),
                    selected: i == s.dhikrIndex,
                    showCheckmark: false,
                    selectedColor: primary.withValues(alpha: 0.16),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: i == s.dhikrIndex
                          ? primary
                          : theme.colorScheme.onSurface,
                    ),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      notifier.selectDhikr(i);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              s.dhikr,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: primary,
              ),
            ),
            const SizedBox(height: 20),
            _CounterDial(
              state: s,
              onTap: () {
                notifier.tap();
                // Light tick per tasbeeh, a stronger one when a round ends.
                final done = ref.read(tasbeehProvider).justCompleted;
                done
                    ? HapticFeedback.heavyImpact()
                    : HapticFeedback.lightImpact();
              },
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final t in tasbeehTargets)
                  ChoiceChip(
                    label: Text(t == 0 ? 'بدون هدف' : arNum(t)),
                    selected: s.target == t,
                    showCheckmark: false,
                    selectedColor: primary.withValues(alpha: 0.16),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: s.target == t
                          ? primary
                          : theme.colorScheme.onSurface,
                    ),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      notifier.setTarget(t);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'تسبيحات اليوم',
                    value: arNum(s.today),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'المجموع الكلي',
                    value: arNum(s.total),
                    color: AppColors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: s.count == 0
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      notifier.reset();
                    },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('تصفير العدّاد'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterDial extends StatefulWidget {
  const _CounterDial({required this.state, required this.onTap});

  final TasbeehState state;
  final VoidCallback onTap;

  @override
  State<_CounterDial> createState() => _CounterDialState();
}

class _CounterDialState extends State<_CounterDial> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final s = widget.state;
    final rounds = s.target > 0 ? s.count ~/ s.target : 0;

    return Semantics(
      button: true,
      label: 'اضغط للتسبيح، العدد ${arNum(s.count)}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: SizedBox(
            width: 270,
            height: 270,
            child: CustomPaint(
              painter: _RingPainter(
                progress: s.progress,
                color: primary,
                track: primary.withValues(alpha: isDark ? 0.18 : 0.12),
                fill: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.8),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      arNum(s.count),
                      style: TextStyle(
                        fontSize: 76,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                    ),
                    Text(
                      s.target > 0 ? 'من ${arNum(s.target)}' : 'اضغط للتسبيح',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (rounds > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'أكملت ${arNum(rounds)} ${rounds == 1 ? 'دورة' : 'دورات'}',
                          style: TextStyle(
                            color: AppColors.amber,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color color;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - stroke / 2;

    canvas.drawShadow(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      color.withValues(alpha: 0.5),
      12,
      true,
    );
    canvas.drawCircle(center, radius, Paint()..color = fill);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.track != track ||
      old.fill != fill;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      radius: 22,
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
