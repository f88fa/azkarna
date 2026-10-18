import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Soft gradient background with blurred color blobs; gives the glass cards
/// something to refract.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF0B2E2C), bg]
                  : [const Color(0xFFDDF3EC), bg],
            ),
          ),
        ),
        PositionedDirectional(
          top: -70,
          start: -60,
          child: _Blob(color: AppColors.teal, size: 240, isDark: isDark),
        ),
        PositionedDirectional(
          top: 140,
          end: -90,
          child: _Blob(color: AppColors.blue, size: 220, isDark: isDark),
        ),
        PositionedDirectional(
          top: 420,
          start: -100,
          child: _Blob(color: AppColors.amber, size: 200, isDark: isDark),
        ),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size, required this.isDark});

  final Color color;
  final double size;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: isDark ? 0.32 : 0.30),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
