import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/datasources/task_local_data_source.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

final taskLocalDataSourceProvider = FutureProvider<TaskLocalDataSource>((
  ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return SqliteTaskLocalDataSource(db);
});

/// Single switch point: replace the implementation here to migrate to a
/// remote (Laravel) repository.
final taskRepositoryProvider = FutureProvider<TaskRepository>((ref) async {
  final local = await ref.watch(taskLocalDataSourceProvider.future);
  return TaskRepositoryImpl(local);
});

final tasksProvider = AsyncNotifierProvider<TasksNotifier, List<Task>>(
  TasksNotifier.new,
);

class TasksNotifier extends AsyncNotifier<List<Task>> {
  Future<TaskRepository> get _repository =>
      ref.read(taskRepositoryProvider.future);

  @override
  Future<List<Task>> build() async {
    final repository = await ref.watch(taskRepositoryProvider.future);
    return repository.getTasks();
  }

  Future<void> add(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    final repository = await _repository;
    await repository.saveTask(
      Task(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: trimmed,
        createdAt: DateTime.now(),
      ),
    );
    state = AsyncData(await repository.getTasks());
  }

  Future<void> toggle(Task task) async {
    final repository = await _repository;
    await repository.saveTask(task.copyWith(isCompleted: !task.isCompleted));
    state = AsyncData(await repository.getTasks());
  }

  Future<void> remove(String id) async {
    final repository = await _repository;
    await repository.deleteTask(id);
    state = AsyncData(await repository.getTasks());
  }
}
