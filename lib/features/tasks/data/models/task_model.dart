import '../../domain/entities/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    super.isCompleted,
    required super.createdAt,
    required super.dueDate,
  });

  factory TaskModel.fromEntity(Task task) => TaskModel(
    id: task.id,
    title: task.title,
    isCompleted: task.isCompleted,
    createdAt: task.createdAt,
    dueDate: task.dueDate,
  );

  static DateTime _due(Object? raw, DateTime createdAt) {
    final parsed = raw is String ? DateTime.tryParse(raw) : null;
    return dateOnly(parsed ?? createdAt);
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['created_at'] as String);
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: createdAt,
      dueDate: _due(json['due_date'], createdAt),
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
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'is_completed': isCompleted ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'due_date': dueDate.toIso8601String(),
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'is_completed': isCompleted,
    'created_at': createdAt.toIso8601String(),
    'due_date': dueDate.toIso8601String(),
  };
}
