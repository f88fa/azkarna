import '../entities/task.dart';

/// Contract consumed by the presentation/domain layers. Implementations may
/// be backed by local storage today and a Laravel API tomorrow.
abstract interface class TaskRepository {
  Future<List<Task>> getTasks();
  Future<void> saveTask(Task task);
  Future<void> deleteTask(String id);
}
