import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/popup_scaffold.dart';
import '../providers/tasbeeh_providers.dart';

/// Beads drawn around the dial (one lap of a 33-bead misbaha).
const int _beads = 33;

/// Interactive tasbeeh counter: one big dial of beads with a single counter,
/// a target and a reset button.
class TasbeehScreen extends ConsumerWidget {
  const TasbeehScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(tasbeehProvider);
    final notifier = ref.read(tasbeehProvider.notifier);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    void tap() {
      notifier.tap();
      if (!s.haptics) return;
      // Light tick per tasbeeh, a stronger one when a round ends.
      final done = ref.read(tasbeehProvider).justCompleted;
      done ? HapticFeedback.heavyImpact() : HapticFeedback.lightImpact();
    }

    return PopupScaffold(
      title: 'المسبحة',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dial = math.min(constraints.maxWidth - 32, 380.0);
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
                  // Completed rounds: appears once the first round is done.
                  SizedBox(
                    height: 34,
                    child: AnimatedOpacity(
                      opacity: s.rounds > 0 ? 1 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'أتممت ${arNum(s.rounds)} ${s.rounds == 1 ? 'دورة' : 'دورات'}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _CounterDial(size: dial, state: s, onTap: tap),
                  const SizedBox(height: 14),
                  Text(
                    'اضغط على الدائرة للتسبيح',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
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
                      const SizedBox(width: 8),
                      Tooltip(
                        message: s.haptics
                            ? 'إيقاف الاهتزاز'
                            : 'تشغيل الاهتزاز',
                        child: IconButton.filledTonal(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            notifier.setHaptics(!s.haptics);
                          },
                          style: IconButton.styleFrom(
                            minimumSize: const Size(52, 52),
                            backgroundColor: primary.withValues(alpha: 0.14),
                            foregroundColor: s.haptics ? primary : muted,
                          ),
                          icon: Icon(
                            s.haptics
                                ? Icons.vibration_rounded
                                : Icons.phonelink_erase_rounded,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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

    // Which bead is lit: progress inside the round, or inside a 33 lap when
    // counting without a target.
    final lit = s.count == 0
        ? 0
        : s.target > 0
        ? (s.progress * _beads).round()
        : (s.count % _beads == 0 ? _beads : s.count % _beads);

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
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _BeadsPainter(
                lit: lit,
                color: primary,
                track: primary.withValues(alpha: isDark ? 0.25 : 0.16),
                fill: isDark ? AppColors.darkCard : Colors.white,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 130),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: Tween(begin: 0.85, end: 1.0).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: FittedBox(
                        key: ValueKey(s.count),
                        fit: BoxFit.scaleDown,
                        child: Text(
                          // Latin digits: the Arabic zero (٠) is drawn as a
                          // dot/diamond.
                          '${s.count}',
                          style: TextStyle(
                            fontSize: widget.size * 0.30,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    if (s.target > 0)
                      Text(
                        'من ${arNum(s.target)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: muted,
                          fontWeight: FontWeight.w700,
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

/// A round dial: soft disc, a ring of [_beads] beads, the first [lit] of
/// them lit and the last one drawn larger.
class _BeadsPainter extends CustomPainter {
  _BeadsPainter({
    required this.lit,
    required this.color,
    required this.track,
    required this.fill,
  });

  final int lit;
  final Color color;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.width / 2 - 6;
    final disc = outer - size.width * 0.07;
    final rect = Rect.fromCircle(center: center, radius: disc);

    canvas.drawShadow(
      Path()..addOval(rect),
      color.withValues(alpha: 0.5),
      16,
      true,
    );
    canvas.drawCircle(center, disc, Paint()..color = fill);
    canvas.drawCircle(
      center,
      disc,
      Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final ringR = (outer + disc) / 2 + size.width * 0.012;
    final beadR = size.width * 0.021;
    for (var i = 0; i < _beads; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / _beads;
      final pos = center + Offset(math.cos(angle), math.sin(angle)) * ringR;
      final isLit = i < lit;
      final isCurrent = isLit && i == lit - 1;
      if (isCurrent) {
        canvas.drawCircle(
          pos,
          beadR * 2.1,
          Paint()..color = color.withValues(alpha: 0.25),
        );
      }
      canvas.drawCircle(
        pos,
        isCurrent ? beadR * 1.45 : beadR,
        Paint()..color = isLit ? color : track,
      );
    }
  }

  @override
  bool shouldRepaint(_BeadsPainter old) =>
      old.lit != lit ||
      old.color != color ||
      old.track != track ||
      old.fill != fill;
}
