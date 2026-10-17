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

class NotificationSettings {
  const NotificationSettings({
    this.adhanEnabled = true,
    this.khatmahReminderEnabled = true,
    this.khatmahReminderTime = ReminderTime.defaultKhatmah,
  });

  final bool adhanEnabled;
  final bool khatmahReminderEnabled;
  final ReminderTime khatmahReminderTime;

  NotificationSettings copyWith({
    bool? adhanEnabled,
    bool? khatmahReminderEnabled,
    ReminderTime? khatmahReminderTime,
  }) => NotificationSettings(
    adhanEnabled: adhanEnabled ?? this.adhanEnabled,
    khatmahReminderEnabled:
        khatmahReminderEnabled ?? this.khatmahReminderEnabled,
    khatmahReminderTime: khatmahReminderTime ?? this.khatmahReminderTime,
  );
}
