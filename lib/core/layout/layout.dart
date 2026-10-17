import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Height of the floating navigation bar (without the safe area).
const double _navBarHeight = 70;
const double _navBarBottomPadding = 8;

/// Total space the floating navigation bar occupies at the bottom of the
/// screen, for a given device bottom [safeBottom] inset.
double navBarFootprint(double safeBottom) =>
    _navBarHeight + _navBarBottomPadding + math.max(safeBottom, 8);

/// Provided by the main shell so descendants can reserve space for the
/// floating navigation bar using the real device safe area.
class NavBarInset extends InheritedWidget {
  const NavBarInset({super.key, required this.inset, required super.child});

  final double inset;

  static double? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavBarInset>()?.inset;

  @override
  bool updateShouldNotify(NavBarInset old) => old.inset != inset;
}

/// Bottom padding that keeps scrollable content clear of the floating
/// navigation bar, including the device's home-indicator safe area.
double floatingNavBarInset(BuildContext context) {
  final fromShell = NavBarInset.maybeOf(context);
  if (fromShell != null) return fromShell;
  return navBarFootprint(MediaQuery.viewPaddingOf(context).bottom) + 24;
}

/// Bottom padding for full-screen routes (no navigation bar).
double screenBottomInset(BuildContext context, {double extra = 24}) =>
    MediaQuery.viewPaddingOf(context).bottom + extra;
