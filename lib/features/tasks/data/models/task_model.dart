import '../../domain/entities/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    super.isCompleted,
    required super.createdAt,
    required super.dueDate,
    super.timeMinutes,
    super.repeatDays,
    super.remind,
    super.completedDates,
  });

  factory TaskModel.fromEntity(Task task) => TaskModel(
    id: task.id,
    title: task.title,
    isCompleted: task.isCompleted,
    createdAt: task.createdAt,
    dueDate: task.dueDate,
    timeMinutes: task.timeMinutes,
    repeatDays: task.repeatDays,
    remind: task.remind,
    completedDates: task.completedDates,
  );

  static DateTime _due(Object? raw, DateTime createdAt) {
    final parsed = raw is String ? DateTime.tryParse(raw) : null;
    return dateOnly(parsed ?? createdAt);
  }

  static Set<int> _days(Object? raw) {
    final items = raw is String
        ? raw.split(',')
        : raw is List
        ? raw.map((e) => '$e')
        : const <String>[];
    return {
      for (final d in items.map(int.tryParse).whereType<int>())
        if (d >= 1 && d <= 7) d,
    };
  }

  static Set<String> _dates(Object? raw) {
    final items = raw is String
        ? raw.split(',')
        : raw is List
        ? raw.map((e) => '$e')
        : const <String>[];
    return {...items.where((item) => item.isNotEmpty)};
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['created_at'] as String);
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: createdAt,
      dueDate: _due(json['due_date'], createdAt),
      timeMinutes: json['time_minutes'] as int?,
      repeatDays: _days(json['repeat_days']),
      remind: json['remind'] as bool? ?? false,
      completedDates: _dates(json['completed_dates']),
    );
  }

  factory TaskModel.fromMap(Map<String, Object?> map) {
    final createdAt = DateTime.parse(map['created_at'] as String);
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: createdAt,
      dueDate: _due(map['due_date'], createdAt),
      timeMinutes: map['time_minutes'] as int?,
      repeatDays: _days(map['repeat_days']),
      remind: (map['remind'] as int? ?? 0) == 1,
      completedDates: _dates(map['completed_dates']),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'is_completed': isCompleted ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'due_date': dueDate.toIso8601String(),
    'time_minutes': timeMinutes,
    'repeat_days': (repeatDays.toList()..sort()).join(','),
    'remind': remind ? 1 : 0,
    'completed_dates': (completedDates.toList()..sort()).join(','),
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'is_completed': isCompleted,
    'created_at': createdAt.toIso8601String(),
    'due_date': dueDate.toIso8601String(),
    'time_minutes': timeMinutes,
    'repeat_days': (repeatDays.toList()..sort()),
    'remind': remind,
    'completed_dates': (completedDates.toList()..sort()),
  };
}
