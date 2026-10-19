import 'dart:ui';

abstract final class AppConstants {
  static const String appName = 'أواب';

  /// Tagline shown under the app name inside the app.
  /// Keep in sync with `version:` in pubspec.yaml (a test checks it).
  static const String appVersion = '1.0.0';
  static const String buildNumber = '9';

  static const String appTagline = 'صلاتي أذكاري ومهامي اليومية';

  /// The app is Arabic-first and always laid out right-to-left.
  static const Locale locale = Locale('ar');
  static const List<Locale> supportedLocales = [locale];

  static const String fontFamily = 'Tajawal';

  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 320);
}
