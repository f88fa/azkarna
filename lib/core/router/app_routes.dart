abstract final class AppRoutes {
  static const String tasks = '/tasks';
  static const String quran = '/quran';
  static const String adhkar = '/adhkar';
  static const String settings = '/settings';

  // Child route patterns (relative to their parent branch).
  static const String surahPattern = 'surah/:number';
  static const String adhkarCategoryPattern = 'category/:id';

  static String surah(int number, {int? ayah}) =>
      '$quran/surah/$number${ayah == null ? '' : '?ayah=$ayah'}';

  static String adhkarCategory(String id) => '$adhkar/category/$id';
}
