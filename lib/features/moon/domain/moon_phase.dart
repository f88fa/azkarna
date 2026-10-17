import 'dart:math' as math;

/// Moon phase for a given date, computed from the mean synodic month.
class MoonPhase {
  const MoonPhase._(this.cycle);

  /// Position in the lunar cycle: 0 = new moon, 0.5 = full moon.
  final double cycle;

  static const double _synodicMonth = 29.530588853;

  // Reference new moon: 2000-01-06 18:14 UTC.
  static final DateTime _epoch = DateTime.utc(2000, 1, 6, 18, 14);

  factory MoonPhase.at(DateTime date) {
    final days =
        date.toUtc().difference(_epoch).inSeconds / Duration.secondsPerDay;
    final cycle = (days / _synodicMonth) % 1.0;
    return MoonPhase._(cycle < 0 ? cycle + 1 : cycle);
  }

  bool get isWaxing => cycle < 0.5;

  /// Lit fraction of the disc, 0..1.
  double get illumination => (1 - math.cos(2 * math.pi * cycle)) / 2;

  /// Age of the moon in days.
  int get ageDays => (cycle * _synodicMonth).floor();

  String get nameAr {
    final c = cycle;
    if (c < 0.03 || c >= 0.97) return 'المحاق';
    if (c < 0.22) return 'هلال متزايد';
    if (c < 0.28) return 'التربيع الأول';
    if (c < 0.47) return 'أحدب متزايد';
    if (c < 0.53) return 'بدر كامل';
    if (c < 0.72) return 'أحدب متناقص';
    if (c < 0.78) return 'التربيع الأخير';
    return 'هلال متناقص';
  }
}
