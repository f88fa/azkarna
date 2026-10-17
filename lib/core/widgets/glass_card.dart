import 'package:flutter/material.dart';

/// Frosted-glass look: a soft translucent diagonal gradient, a thin light
/// border and a soft drop shadow.
///
/// There is deliberately no live background blur (`BackdropFilter`): the
/// backdrop is a smooth pastel gradient, so a blur is invisible, yet it forces
/// an off-screen layer per card and made long lists (surahs, adhkar) janky.
/// Every card is its own repaint boundary so scrolling stays cheap.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.tint,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Optional color mixed into the glass (e.g. brand green).
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(radius);
    final base = tint ?? (isDark ? Colors.white : Colors.white);

    final gradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: tint != null
          ? [
              base.withValues(alpha: isDark ? 0.55 : 0.88),
              base.withValues(alpha: isDark ? 0.35 : 0.68),
            ]
          : [
              base.withValues(alpha: isDark ? 0.14 : 0.78),
              base.withValues(alpha: isDark ? 0.06 : 0.46),
            ],
    );

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: (tint ?? Colors.black).withValues(
                alpha: isDark ? 0.28 : 0.10,
              ),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Ink(
              padding: padding,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: borderRadius,
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.7),
                  width: 1,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
