class Task {
  const Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
    required this.dueDate,
  });

  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  /// Day the task belongs to (date only, no time component).
  final DateTime dueDate;

  Task copyWith({String? title, bool? isCompleted, DateTime? dueDate}) => Task(
    id: id,
    title: title ?? this.title,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt,
    dueDate: dueDate ?? this.dueDate,
  );
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
