import '../../domain/entities/khatmah_progress.dart';

class KhatmahModel extends KhatmahProgress {
  const KhatmahModel({
    super.bookmark,
    super.dailyTarget,
    super.todayRead,
    super.progressDate,
  });

  factory KhatmahModel.fromEntity(KhatmahProgress p) => KhatmahModel(
    bookmark: p.bookmark,
    dailyTarget: p.dailyTarget,
    todayRead: p.todayRead,
    progressDate: p.progressDate,
  );

  /// Tolerant parser: invalid fields fall back to defaults.
  factory KhatmahModel.fromJson(Map<String, dynamic> json) {
    final surah = json['surah'];
    final ayah = json['ayah'];
    final target = json['daily_target'];
    final read = json['today_read'];
    final date = json['progress_date'];

    return KhatmahModel(
      bookmark: surah is int && ayah is int
          ? Bookmark(surahNumber: surah, ayahNumber: ayah)
          : null,
      dailyTarget: target is int && target > 0
          ? target
          : KhatmahProgress.defaultDailyTarget,
      todayRead: read is int && read >= 0 ? read : 0,
      progressDate: date is String ? DateTime.tryParse(date) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'surah': bookmark?.surahNumber,
    'ayah': bookmark?.ayahNumber,
    'daily_target': dailyTarget,
    'today_read': todayRead,
    'progress_date': progressDate?.toIso8601String(),
  };
}
