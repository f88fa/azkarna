class Task {
  const Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
    required this.dueDate,
    this.timeMinutes,
    this.repeatDays = const {},
    this.remind = false,
    this.completedDates = const {},
  });

  final String id;
  final String title;

  /// Completion flag of a one-off task. Repeating tasks use
  /// [completedDates] instead (one entry per finished occurrence).
  final bool isCompleted;
  final DateTime createdAt;

  /// Day of a one-off task, or the first day of a repeating one.
  final DateTime dueDate;

  /// Time of day as minutes since midnight, or null when the task has no
  /// specific time.
  final int? timeMinutes;

  /// Weekdays (`DateTime.monday`..`DateTime.sunday`) a task repeats on at the
  /// same [timeMinutes]. Empty for a one-off task.
  final Set<int> repeatDays;

  /// Whether to notify at [timeMinutes].
  final bool remind;

  /// Finished occurrences of a repeating task, as `yyyy-MM-dd` keys.
  final Set<String> completedDates;

  bool get isRepeating => repeatDays.isNotEmpty;
  int? get hour => timeMinutes == null ? null : timeMinutes! ~/ 60;
  int? get minute => timeMinutes == null ? null : timeMinutes! % 60;

  /// Whether the task shows up on [day].
  bool occursOn(DateTime day) {
    final d = dateOnly(day);
    if (!isRepeating) return isSameDay(dueDate, d);
    return !d.isBefore(dateOnly(dueDate)) && repeatDays.contains(d.weekday);
  }

  bool isDoneOn(DateTime day) =>
      isRepeating ? completedDates.contains(dateKey(day)) : isCompleted;

  /// Flips completion for [day] (only that occurrence for repeating tasks).
  Task toggledOn(DateTime day) {
    if (!isRepeating) return copyWith(isCompleted: !isCompleted);
    final key = dateKey(day);
    final next = {...completedDates};
    if (!next.remove(key)) next.add(key);
    return copyWith(completedDates: next);
  }

  Task copyWith({
    String? title,
    bool? isCompleted,
    DateTime? dueDate,
    Set<String>? completedDates,
  }) => Task(
    id: id,
    title: title ?? this.title,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt,
    dueDate: dueDate ?? this.dueDate,
    timeMinutes: timeMinutes,
    repeatDays: repeatDays,
    remind: remind,
    completedDates: completedDates ?? this.completedDates,
  );
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
