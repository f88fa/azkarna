abstract final class AppRoutes {
  static const String home = '/';

  // Pop-up sheets opened from the home screen's dock.
  static const String tasks = '/tasks';
  static const String quran = '/quran';
  static const String adhkar = '/adhkar';
  static const String settings = '/settings';
  static const String settingsLocation = '/settings/location';
  static const String settingsMuadhin = '/settings/muadhin';
  static const String settingsDhikr = '/settings/dhikr';
  static const String settingsReminders = '/settings/reminders';
  static const String tasbeeh = '/tasbeeh';

  // Full-screen pages pushed on top of a sheet or the home screen.
  static const String kahf = '/kahf';
  static const String mushafPagePattern = '/read/:page';
  static const String adhkarCategoryPattern = '/dhikr/:id';

  /// Opens the Mushaf reader at [page] (1–604).
  static String mushafPage(int page) => '/read/$page';

  static String adhkarCategory(String id) => '/dhikr/$id';
}
