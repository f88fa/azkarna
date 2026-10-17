import '../../domain/entities/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    super.isCompleted,
    required super.createdAt,
  });

  factory TaskModel.fromEntity(Task task) => TaskModel(
    id: task.id,
    title: task.title,
    isCompleted: task.isCompleted,
    createdAt: task.createdAt,
  );

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: json['id'] as String,
    title: json['title'] as String,
    isCompleted: json['is_completed'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  factory TaskModel.fromMap(Map<String, Object?> map) => TaskModel(
    id: map['id'] as String,
    title: map['title'] as String,
    isCompleted: (map['is_completed'] as int? ?? 0) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'is_completed': isCompleted ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'is_completed': isCompleted,
    'created_at': createdAt.toIso8601String(),
  };
}
