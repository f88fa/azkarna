import 'package:flutter/material.dart';

/// Text with a strikethrough line that animates across each line when
/// [struck] becomes true (and retracts when it becomes false).
class AnimatedStrikeText extends StatefulWidget {
  const AnimatedStrikeText({
    super.key,
    required this.text,
    required this.struck,
    required this.style,
    this.lineColor,
    this.duration = const Duration(milliseconds: 320),
  });

  final String text;
  final bool struck;
  final TextStyle style;
  final Color? lineColor;
  final Duration duration;

  @override
  State<AnimatedStrikeText> createState() => _AnimatedStrikeTextState();
}

class _AnimatedStrikeTextState extends State<AnimatedStrikeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.struck ? 1 : 0,
  );

  @override
  void didUpdateWidget(AnimatedStrikeText old) {
    super.didUpdateWidget(old);
    if (old.struck != widget.struck) {
      widget.struck ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final color = widget.lineColor ?? widget.style.color ?? Colors.grey;

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textDirection: direction,
          textScaler: scaler,
        )..layout(maxWidth: constraints.maxWidth);
        final lines = painter.computeLineMetrics();
        final size = painter.size;
        painter.dispose();

        return CustomPaint(
          foregroundPainter: _StrikePainter(
            animation: _controller,
            lines: lines,
            rtl: direction == TextDirection.rtl,
            width: size.width,
            color: color,
          ),
          child: AnimatedDefaultTextStyle(
            duration: widget.duration,
            style: widget.style,
            child: Text(widget.text, textScaler: scaler),
          ),
        );
      },
    );
  }
}

class _StrikePainter extends CustomPainter {
  _StrikePainter({
    required this.animation,
    required this.lines,
    required this.rtl,
    required this.width,
    required this.color,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final List<LineMetrics> lines;
  final bool rtl;
  final double width;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeInOut.transform(animation.value);
    if (t <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (final line in lines) {
      final y = line.baseline - line.ascent * 0.32;
      // `left` is measured from the paint origin for both text directions.
      final start = rtl ? line.left + line.width : line.left;
      final end = rtl ? start - line.width * t : start + line.width * t;
      canvas.drawLine(Offset(start, y), Offset(end, y), paint);
    }
  }

  @override
  bool shouldRepaint(_StrikePainter old) =>
      old.lines != lines || old.color != color || old.rtl != rtl;
}
