import 'dart:ui';

abstract final class AppConstants {
  static const String appName = 'أذكارنا';

  /// The app is Arabic-first and always laid out right-to-left.
  static const Locale locale = Locale('ar');
  static const List<Locale> supportedLocales = [locale];

  static const String fontFamily = 'Tajawal';

  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 320);
}
