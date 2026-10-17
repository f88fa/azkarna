import 'dart:ui';

abstract final class AppConstants {
  static const String appName = 'أواب';

  /// Tagline shown under the app name inside the app.
  static const String appTagline = 'صلاة وقرآن و أذكاري ومهامي اليومية';

  /// The app is Arabic-first and always laid out right-to-left.
  static const Locale locale = Locale('ar');
  static const List<Locale> supportedLocales = [locale];

  static const String fontFamily = 'Tajawal';

  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 320);
}
