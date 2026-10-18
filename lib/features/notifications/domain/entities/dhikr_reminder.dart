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
    this.soundEnabled = true,
    this.quietHoursEnabled = true,
    this.quietStart = const ReminderTime(hour: 23, minute: 0),
    this.quietEnd = const ReminderTime(hour: 5, minute: 0),
  });

  final bool enabled;
  final DhikrInterval interval;

  /// Spoken dhikr with each reminder; off = a silent notification.
  final bool soundEnabled;

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
    bool? soundEnabled,
    bool? quietHoursEnabled,
    ReminderTime? quietStart,
    ReminderTime? quietEnd,
  }) => DhikrReminderSettings(
    enabled: enabled ?? this.enabled,
    interval: interval ?? this.interval,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    quietStart: quietStart ?? this.quietStart,
    quietEnd: quietEnd ?? this.quietEnd,
  );
}

/// One rotating dhikr shown by a periodic reminder.
class DhikrMessage {
  const DhikrMessage(this.title, this.body, this.sound);

  final String title;
  final String body;

  /// Base name of the spoken recording (`dhikr_<id>`): `ios/Runner/<sound>.caf`
  /// and `android/app/src/main/res/raw/<sound>.wav`.
  final String sound;

  String get iosFile => '$sound.caf';
}

/// The eight voiced adhkar, in rotation order, so every reminder differs from
/// the previous one. Each text matches its recording.
abstract final class DhikrMessages {
  static const List<DhikrMessage> all = [
    DhikrMessage('تسبيح', 'سبحان الله', 'dhikr_subhan_allah'),
    DhikrMessage('تهليل', 'لا إله إلا الله', 'dhikr_la_ilaha_illa_allah'),
    DhikrMessage('استغفار', 'أستغفر الله', 'dhikr_astaghfirullah'),
    DhikrMessage(
      'صلاة على النبي ﷺ',
      'اللهم صلِّ على محمد',
      'dhikr_allahumma_salli',
    ),
    DhikrMessage('تكبير', 'الله أكبر', 'dhikr_allahu_akbar'),
    DhikrMessage(
      'اذكر الله',
      'اذكر الله · ألا بذكر الله تطمئن القلوب',
      'dhikr_uthkur_allah',
    ),
    DhikrMessage(
      'تسبيح',
      'سبحان الله وبحمده، سبحان الله العظيم',
      'dhikr_subhan_allah_wa_bihamdihi',
    ),
    DhikrMessage('حمد', 'الحمد لله', 'dhikr_alhamdulillah'),
  ];

  /// Deterministic message for the n-th reminder.
  static DhikrMessage at(int sequence) => all[sequence.abs() % all.length];
}
