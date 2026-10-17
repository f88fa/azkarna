import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A route page that slides up over the previous page like a modal sheet.
/// The page underneath stays visible (dimmed) above the sheet's top edge, and
/// tapping that dimmed area closes the sheet.
CustomTransitionPage<void> appSheetPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    opaque: false,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    barrierLabel: 'إغلاق',
    transitionDuration: const Duration(milliseconds: 460),
    reverseTransitionDuration: const Duration(milliseconds: 340),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}
