import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Bottom padding that keeps scrollable content clear of the floating
/// navigation bar, including the device's home-indicator safe area.
double floatingNavBarInset(BuildContext context) {
  final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
  return 100 + math.max(safeBottom, 8);
}

/// Bottom padding for full-screen routes (no navigation bar).
double screenBottomInset(BuildContext context, {double extra = 24}) =>
    MediaQuery.viewPaddingOf(context).bottom + extra;
