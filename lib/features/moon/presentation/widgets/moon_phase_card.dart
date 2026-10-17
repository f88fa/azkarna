import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/moon_phase.dart';

/// Glass card showing today's moon phase with a painted moon.
class MoonPhaseCard extends StatelessWidget {
  const MoonPhaseCard({super.key, this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = MoonPhase.at(date ?? DateTime.now());
    final percent = (phase.illumination * 100).round();
    final secondary = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          MoonPhaseView(phase: phase, size: 62),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طور القمر',
                  style: theme.textTheme.bodySmall?.copyWith(color: secondary),
                ),
                const SizedBox(height: 2),
                Text(
                  phase.nameAr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: phase.illumination,
                    minHeight: 5,
                    backgroundColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.08,
                    ),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFF5B301)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${arNum(percent)}٪',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'إضاءة',
                style: theme.textTheme.bodySmall?.copyWith(color: secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MoonPhaseView extends StatelessWidget {
  const MoonPhaseView({super.key, required this.phase, this.size = 64});

  final MoonPhase phase;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MoonPainter(phase)),
    );
  }
}

class _MoonPainter extends CustomPainter {
  _MoonPainter(this.phase);

  final MoonPhase phase;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = Offset(size.width / 2, size.height / 2);
    final disc = Rect.fromCircle(center: c, radius: r);

    // Soft glow.
    canvas.drawCircle(
      c,
      r * 1.12,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE9A8).withValues(alpha: 0.35),
            const Color(0xFFFFE9A8).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.12)),
    );

    // Dark side.
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF263042));

    // Lit side: half circle on the lit edge + half ellipse for the terminator.
    final k = math.cos(2 * math.pi * phase.cycle); // 1 new .. -1 full
    final s = phase.isWaxing ? 1.0 : -1.0; // +1: lit side is the right
    final terminator = Rect.fromCenter(
      center: c,
      width: 2 * r * k.abs(),
      height: 2 * r,
    );
    final bulge = k > 0 ? s : -s;

    final lit = Path()
      ..arcTo(disc, -math.pi / 2, s * math.pi, true)
      ..arcTo(terminator, math.pi / 2, -bulge * math.pi, false)
      ..close();

    canvas.drawPath(
      lit,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3C4), Color(0xFFF5C84C)],
        ).createShader(disc),
    );

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_MoonPainter old) => old.phase.cycle != phase.cycle;
}
