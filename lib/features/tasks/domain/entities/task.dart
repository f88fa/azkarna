class Task {
  const Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
  });

  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  Task copyWith({String? title, bool? isCompleted}) => Task(
    id: id,
    title: title ?? this.title,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt,
  );
}
