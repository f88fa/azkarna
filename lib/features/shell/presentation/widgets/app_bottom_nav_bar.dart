import 'dart:ui';

import 'package:flutter/material.dart';

class AppNavItem {
  const AppNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Floating, frosted-glass bottom navigation bar with an animated pill
/// indicator.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double _height = 68;
  static const double _radius = 34;
  static const Duration _duration = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final active = theme.colorScheme.primary;
    const inactive = Color(0xFF8E8E93);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.10),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: _height,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF1C1C1E) : Colors.white)
                      .withValues(alpha: isDark ? 0.72 : 0.78),
                  borderRadius: BorderRadius.circular(_radius),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.06,
                    ),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / items.length;
                    return Stack(
                      children: [
                        AnimatedPositionedDirectional(
                          duration: _duration,
                          curve: Curves.easeOutCubic,
                          start: itemWidth * currentIndex,
                          top: 0,
                          bottom: 0,
                          width: itemWidth,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: active.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(_radius - 6),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < items.length; i++)
                              Expanded(
                                child: _NavButton(
                                  item: items[i],
                                  selected: i == currentIndex,
                                  activeColor: active,
                                  inactiveColor: inactive,
                                  onTap: () => onTap(i),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1.0,
              duration: AppBottomNavBar._duration,
              curve: Curves.easeOutBack,
              child: Icon(
                selected ? item.activeIcon : item.icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: AppBottomNavBar._duration,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.1,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              child: Text(item.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
