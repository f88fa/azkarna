import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/popup_scaffold.dart';
import '../providers/tasbeeh_providers.dart';

/// Interactive tasbeeh / istighfar counter: one big dial, nothing else to
/// distract from it.
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dial = math.min(constraints.maxWidth - 48, 340.0);
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(0, constraints.maxHeight - 22),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Dhikr picker: one swipeable row.
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: tasbeehAdhkar.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => ChoiceChip(
                        label: Text(tasbeehAdhkar[i]),
                        selected: i == s.dhikrIndex,
                        showCheckmark: false,
                        selectedColor: primary.withValues(alpha: 0.18),
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
                    ),
                  ),
                  const SizedBox(height: 22),
                  _CounterDial(
                    size: dial,
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
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final t in tasbeehTargets)
                              ChoiceChip(
                                label: Text(t == 0 ? 'مفتوح' : arNum(t)),
                                selected: s.target == t,
                                showCheckmark: false,
                                selectedColor: primary.withValues(alpha: 0.18),
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
                      ),
                      const SizedBox(width: 12),
                      Tooltip(
                        message: 'تصفير العدّاد',
                        child: IconButton.filledTonal(
                          onPressed: s.count == 0
                              ? null
                              : () {
                                  HapticFeedback.mediumImpact();
                                  notifier.reset();
                                },
                          style: IconButton.styleFrom(
                            minimumSize: const Size(52, 52),
                            backgroundColor: AppColors.red.withValues(
                              alpha: 0.14,
                            ),
                            foregroundColor: AppColors.red,
                          ),
                          icon: const Icon(Icons.restart_alt_rounded, size: 28),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CounterDial extends StatefulWidget {
  const _CounterDial({
    required this.size,
    required this.state,
    required this.onTap,
  });

  final double size;
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
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Semantics(
      button: true,
      label: '${s.dhikr}، اضغط للتسبيح، العدد ${arNum(s.count)}',
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
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _RingPainter(
                progress: s.progress,
                color: primary,
                track: primary.withValues(alpha: isDark ? 0.2 : 0.12),
                fill: isDark ? AppColors.darkCard : Colors.white,
              ),
              child: Padding(
                padding: EdgeInsets.all(widget.size * 0.14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.dhikr,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        // Latin digits: the Arabic zero (٠) is drawn as a dot/diamond.
                        '${s.count}',
                        style: TextStyle(
                          fontSize: widget.size * 0.34,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      s.target > 0 ? 'من ${arNum(s.target)}' : 'اضغط للتسبيح',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w600,
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
    const stroke = 16.0;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - stroke / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawShadow(
      Path()..addOval(rect),
      color.withValues(alpha: 0.55),
      14,
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
        rect,
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
