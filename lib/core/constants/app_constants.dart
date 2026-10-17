import 'dart:ui';

abstract final class AppConstants {
  static const String appName = 'Azkarna';

  static const List<Locale> supportedLocales = [Locale('en'), Locale('ar')];

  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 320);
}
