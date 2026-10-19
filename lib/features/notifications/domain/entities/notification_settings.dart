import 'adhan_sound.dart';
import 'dhikr_reminder.dart';

class ReminderTime {
  const ReminderTime({required this.hour, required this.minute});

  final int hour;
  final int minute;

  static const ReminderTime defaultKhatmah = ReminderTime(hour: 20, minute: 0);

  @override
  bool operator ==(Object other) =>
      other is ReminderTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

/// How long after the Adhan the Adhkar reminders fire.
abstract final class AdhkarReminderDelays {
  static const Duration morningAfterFajr = Duration(minutes: 30);
  static const Duration eveningAfterAsr = Duration(minutes: 20);
}

/// How long before the Friday Maghrib prayer the Surah Al-Kahf reminder fires.
enum KahfLead {
  oneHour(minutes: 60, label: 'قبل المغرب بساعة'),
  twoHours(minutes: 120, label: 'قبل المغرب بساعتين');

  const KahfLead({required this.minutes, required this.label});

  final int minutes;
  final String label;

  Duration get duration => Duration(minutes: minutes);

  static KahfLead fromMinutes(int? minutes) => KahfLead.values.firstWhere(
    (l) => l.minutes == minutes,
    orElse: () => KahfLead.oneHour,
  );
}

class NotificationSettings {
  const NotificationSettings({
    this.adhanEnabled = true,
    this.morningAdhkarEnabled = true,
    this.eveningAdhkarEnabled = true,
    this.khatmahReminderEnabled = true,
    this.khatmahReminderTime = ReminderTime.defaultKhatmah,
    this.adhanSound = AdhanSound.defaultSound,
    this.adhanDuration = AdhanDuration.full,
    this.dhikr = const DhikrReminderSettings(),
    this.kahfReminderEnabled = true,
    this.kahfLead = KahfLead.oneHour,
  });

  final bool adhanEnabled;

  /// Reminder [AdhkarReminderDelays.morningAfterFajr] after the Fajr Adhan.
  final bool morningAdhkarEnabled;

  /// Reminder [AdhkarReminderDelays.eveningAfterAsr] after the Asr Adhan.
  final bool eveningAdhkarEnabled;
  final bool khatmahReminderEnabled;
  final ReminderTime khatmahReminderTime;

  /// Sound played by the Adhan notifications.
  final AdhanSound adhanSound;

  /// Full recording or the short (about 10 s) version.
  final AdhanDuration adhanDuration;

  /// Periodic dhikr reminders (every 15 min … 3 h).
  final DhikrReminderSettings dhikr;

  /// Friday reminder to read Surah Al-Kahf, [kahfLead] before Maghrib.
  final bool kahfReminderEnabled;
  final KahfLead kahfLead;

  NotificationSettings copyWith({
    bool? adhanEnabled,
    bool? morningAdhkarEnabled,
    bool? eveningAdhkarEnabled,
    bool? khatmahReminderEnabled,
    ReminderTime? khatmahReminderTime,
    AdhanSound? adhanSound,
    AdhanDuration? adhanDuration,
    DhikrReminderSettings? dhikr,
    bool? kahfReminderEnabled,
    KahfLead? kahfLead,
  }) => NotificationSettings(
    adhanEnabled: adhanEnabled ?? this.adhanEnabled,
    morningAdhkarEnabled: morningAdhkarEnabled ?? this.morningAdhkarEnabled,
    eveningAdhkarEnabled: eveningAdhkarEnabled ?? this.eveningAdhkarEnabled,
    khatmahReminderEnabled:
        khatmahReminderEnabled ?? this.khatmahReminderEnabled,
    khatmahReminderTime: khatmahReminderTime ?? this.khatmahReminderTime,
    adhanSound: adhanSound ?? this.adhanSound,
    adhanDuration: adhanDuration ?? this.adhanDuration,
    dhikr: dhikr ?? this.dhikr,
    kahfReminderEnabled: kahfReminderEnabled ?? this.kahfReminderEnabled,
    kahfLead: kahfLead ?? this.kahfLead,
  );
}
