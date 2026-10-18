import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';

class _DockItem {
  const _DockItem(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

const List<_DockItem> _items = [
  _DockItem('المهام', Icons.checklist_rounded, AppRoutes.tasks),
  _DockItem('القرآن', Icons.menu_book_rounded, AppRoutes.quran),
  _DockItem('الأذكار', Icons.auto_awesome_rounded, AppRoutes.adhkar),
  _DockItem('الإعدادات', Icons.settings_rounded, AppRoutes.settings),
];

/// Floating frosted-glass dock on the home screen. Every button opens a
/// pop-up sheet (closed with its X button), so the home screen is always one
/// tap away.
class HomeDock extends StatelessWidget {
  const HomeDock({super.key});

  static const double height = 70;
  static const double _radius = 35;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.14),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              child: Container(
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkSurface : Colors.white)
                      .withValues(alpha: isDark ? 0.72 : 0.78),
                  borderRadius: BorderRadius.circular(_radius),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.white).withValues(
                      alpha: isDark ? 0.12 : 0.8,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    for (final item in _items)
                      Expanded(child: _DockButton(item: item)),
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

class _DockButton extends StatefulWidget {
  const _DockButton({required this.item});

  final _DockItem item;

  @override
  State<_DockButton> createState() => _DockButtonState();
}

class _DockButtonState extends State<_DockButton> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final label = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.72);

    return Semantics(
      button: true,
      label: widget.item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: () {
          HapticFeedback.selectionClick();
          context.push(widget.item.route);
        },
        child: ExcludeSemantics(
          child: AnimatedScale(
            scale: _pressed ? 0.88 : 1,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.item.icon, size: 26, color: primary),
                const SizedBox(height: 3),
                Text(
                  widget.item.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: label,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
