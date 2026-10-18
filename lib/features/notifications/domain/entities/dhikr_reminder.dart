import 'notification_settings.dart';

/// How often the periodic dhikr reminder fires.
enum DhikrInterval {
  quarterHour(minutes: 15, label: 'كل ١٥ دقيقة'),
  halfHour(minutes: 30, label: 'كل نصف ساعة'),
  hour(minutes: 60, label: 'كل ساعة'),
  threeHours(minutes: 180, label: 'كل ٣ ساعات');

  const DhikrInterval({required this.minutes, required this.label});

  final int minutes;
  final String label;

  static DhikrInterval fromMinutes(int? minutes) =>
      DhikrInterval.values.firstWhere(
        (i) => i.minutes == minutes,
        orElse: () => DhikrInterval.hour,
      );
}

class DhikrReminderSettings {
  const DhikrReminderSettings({
    this.enabled = false,
    this.interval = DhikrInterval.hour,
    this.quietHoursEnabled = true,
    this.quietStart = const ReminderTime(hour: 23, minute: 0),
    this.quietEnd = const ReminderTime(hour: 5, minute: 0),
  });

  final bool enabled;
  final DhikrInterval interval;

  /// No reminders while the user sleeps.
  final bool quietHoursEnabled;
  final ReminderTime quietStart;
  final ReminderTime quietEnd;

  /// Whether [hour]:[minute] falls inside the quiet window (which may wrap
  /// past midnight, e.g. 23:00 → 05:00).
  bool isQuiet(int hour, int minute) {
    if (!quietHoursEnabled) return false;
    final now = hour * 60 + minute;
    final start = quietStart.hour * 60 + quietStart.minute;
    final end = quietEnd.hour * 60 + quietEnd.minute;
    if (start == end) return false;
    return start < end ? now >= start && now < end : now >= start || now < end;
  }

  DhikrReminderSettings copyWith({
    bool? enabled,
    DhikrInterval? interval,
    bool? quietHoursEnabled,
    ReminderTime? quietStart,
    ReminderTime? quietEnd,
  }) => DhikrReminderSettings(
    enabled: enabled ?? this.enabled,
    interval: interval ?? this.interval,
    quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    quietStart: quietStart ?? this.quietStart,
    quietEnd: quietEnd ?? this.quietEnd,
  );
}

/// One rotating dhikr shown by a periodic reminder.
class DhikrMessage {
  const DhikrMessage(this.title, this.body);

  final String title;
  final String body;
}

/// Messages cycle through istighfar, tasbeeh, hawqala and salawat so every
/// reminder differs from the previous one.
abstract final class DhikrMessages {
  static const List<List<DhikrMessage>> _groups = [
    [
      DhikrMessage('استغفار', 'أستغفر الله العظيم وأتوب إليه'),
      DhikrMessage(
        'استغفار',
        'أستغفر الله الذي لا إله إلا هو الحي القيوم وأتوب إليه',
      ),
      DhikrMessage('استغفار', 'رب اغفر لي وتب عليّ إنك أنت التواب الرحيم'),
    ],
    [
      DhikrMessage('تسبيح', 'سبحان الله وبحمده، سبحان الله العظيم'),
      DhikrMessage(
        'تسبيح',
        'سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر',
      ),
      DhikrMessage('تسبيح', 'سبحان الله وبحمده عدد خلقه ورضا نفسه'),
    ],
    [
      DhikrMessage('حوقلة', 'لا حول ولا قوة إلا بالله'),
      DhikrMessage(
        'حوقلة',
        'لا حول ولا قوة إلا بالله العلي العظيم · كنز من كنوز الجنة',
      ),
    ],
    [
      DhikrMessage('صلاة على النبي ﷺ', 'اللهم صلِّ وسلم على نبينا محمد'),
      DhikrMessage('صلاة على النبي ﷺ', 'صلى الله عليه وسلم'),
      DhikrMessage(
        'صلاة على النبي ﷺ',
        'اللهم صلِّ على محمد وعلى آل محمد كما صليت على إبراهيم',
      ),
    ],
  ];

  /// Deterministic message for the n-th reminder.
  static DhikrMessage at(int sequence) {
    final n = sequence.abs();
    final group = _groups[n % _groups.length];
    return group[(n ~/ _groups.length) % group.length];
  }
}
