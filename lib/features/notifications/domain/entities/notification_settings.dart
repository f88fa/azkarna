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

class NotificationSettings {
  const NotificationSettings({
    this.adhanEnabled = true,
    this.morningAdhkarEnabled = true,
    this.eveningAdhkarEnabled = true,
    this.khatmahReminderEnabled = true,
    this.khatmahReminderTime = ReminderTime.defaultKhatmah,
  });

  final bool adhanEnabled;

  /// Reminder [AdhkarReminderDelays.morningAfterFajr] after the Fajr Adhan.
  final bool morningAdhkarEnabled;

  /// Reminder [AdhkarReminderDelays.eveningAfterAsr] after the Asr Adhan.
  final bool eveningAdhkarEnabled;
  final bool khatmahReminderEnabled;
  final ReminderTime khatmahReminderTime;

  NotificationSettings copyWith({
    bool? adhanEnabled,
    bool? morningAdhkarEnabled,
    bool? eveningAdhkarEnabled,
    bool? khatmahReminderEnabled,
    ReminderTime? khatmahReminderTime,
  }) => NotificationSettings(
    adhanEnabled: adhanEnabled ?? this.adhanEnabled,
    morningAdhkarEnabled: morningAdhkarEnabled ?? this.morningAdhkarEnabled,
    eveningAdhkarEnabled: eveningAdhkarEnabled ?? this.eveningAdhkarEnabled,
    khatmahReminderEnabled:
        khatmahReminderEnabled ?? this.khatmahReminderEnabled,
    khatmahReminderTime: khatmahReminderTime ?? this.khatmahReminderTime,
  );
}
