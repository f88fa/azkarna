import 'dart:ui';

import 'package:flutter/material.dart';

/// Frosted-glass surface: background blur, a soft diagonal gradient, a thin
/// translucent border and a soft drop shadow.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.tint,
    this.blur = 22,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Optional color mixed into the glass (e.g. brand green).
  final Color? tint;
  final double blur;
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

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: (tint ?? Colors.black).withValues(
              alpha: isDark ? 0.35 : 0.14,
            ),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
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
      ),
    );
  }
}
