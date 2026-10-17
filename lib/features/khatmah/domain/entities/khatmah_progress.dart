class Bookmark {
  const Bookmark({required this.surahNumber, required this.ayahNumber});

  final int surahNumber;
  final int ayahNumber;

  @override
  bool operator ==(Object other) =>
      other is Bookmark &&
      other.surahNumber == surahNumber &&
      other.ayahNumber == ayahNumber;

  @override
  int get hashCode => Object.hash(surahNumber, ayahNumber);
}

class KhatmahProgress {
  const KhatmahProgress({
    this.bookmark,
    this.dailyTarget = defaultDailyTarget,
    this.todayRead = 0,
    this.progressDate,
  });

  static const int defaultDailyTarget = 20;

  /// Last reading position, or null if the user has not started yet.
  final Bookmark? bookmark;

  /// Daily reading goal, in ayahs.
  final int dailyTarget;

  /// Ayahs read on [progressDate].
  final int todayRead;
  final DateTime? progressDate;

  double get todayFraction =>
      dailyTarget <= 0 ? 0 : (todayRead / dailyTarget).clamp(0.0, 1.0);

  KhatmahProgress copyWith({
    Bookmark? bookmark,
    int? dailyTarget,
    int? todayRead,
    DateTime? progressDate,
  }) => KhatmahProgress(
    bookmark: bookmark ?? this.bookmark,
    dailyTarget: dailyTarget ?? this.dailyTarget,
    todayRead: todayRead ?? this.todayRead,
    progressDate: progressDate ?? this.progressDate,
  );
}
