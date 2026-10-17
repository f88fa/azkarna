import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/utils/arabic_format.dart';
import '../../domain/moon_phase.dart';

/// Compact pill: a small painted moon, the phase name and its illumination.
class MoonPhasePill extends StatelessWidget {
  const MoonPhasePill({super.key, this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = MoonPhase.at(date ?? DateTime.now());
    final percent = (phase.illumination * 100).round();

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 5, 12, 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MoonPhaseView(phase: phase, size: 24),
          const SizedBox(width: 8),
          Text(
            '${phase.nameAr} · ${arNum(percent)}٪',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
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
