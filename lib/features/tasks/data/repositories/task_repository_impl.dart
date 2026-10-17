import '../../../../core/error/failures.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  const TaskRepositoryImpl(this._local);

  final TaskLocalDataSource _local;

  @override
  Future<List<Task>> getTasks() => _guard(_local.getTasks);

  @override
  Future<void> saveTask(Task task) =>
      _guard(() => _local.saveTask(TaskModel.fromEntity(task)));

  @override
  Future<void> deleteTask(String id) => _guard(() => _local.deleteTask(id));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Failure {
      rethrow;
    } catch (e) {
      throw CacheFailure(e.toString());
    }
  }
}
