import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF0A7C66);
  static const Color primaryDark = Color(0xFF2DD4A7);
  static const Color primaryDeep = Color(0xFF064E40);

  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightLabel = Color(0xFF1C1C1E);
  static const Color lightSecondaryLabel = Color(0xFF8E8E93);

  // Deep navy-emerald night palette (easy on the eyes, matches the brand).
  static const Color darkBackground = Color(0xFF07181D);
  static const Color darkSurface = Color(0xFF0F2A2F);
  static const Color darkCard = Color(0xFF12333A);
  static const Color darkLabel = Color(0xFFEAF4F1);
  static const Color darkSecondaryLabel = Color(0xFF93AAAA);

  /// Clean, TickTick-style canvas used by the tasks screen.
  static const Color tasksLightBackground = Color(0xFFF6F7F9);

  // Accent colors used for settings icons and highlights.
  static const Color blue = Color(0xFF3B82F6);
  static const Color orange = Color(0xFFFF9500);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFEC4899);
  static const Color red = Color(0xFFEF4444);
  static const Color teal = Color(0xFF14B8A6);
  static const Color indigo = Color(0xFF6366F1);
  static const Color amber = Color(0xFFF5B301);
}
