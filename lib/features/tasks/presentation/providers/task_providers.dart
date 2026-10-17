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

  /// Adds a task to [dueDate] (defaults to the selected day). Throws if the
  /// task could not be saved so callers can show an error.
  Future<void> add(String title, {DateTime? dueDate}) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    final repository = await _repository;
    final now = DateTime.now();
    await repository.saveTask(
      Task(
        id: now.microsecondsSinceEpoch.toString(),
        title: trimmed,
        createdAt: now,
        dueDate: dateOnly(dueDate ?? ref.read(selectedTaskDateProvider)),
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

/// Day currently shown in the weekly calendar strip.
final selectedTaskDateProvider =
    NotifierProvider<SelectedTaskDateNotifier, DateTime>(
      SelectedTaskDateNotifier.new,
    );

class SelectedTaskDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(DateTime.now());

  void select(DateTime day) => state = dateOnly(day);
}

/// Tasks of the selected day.
final selectedDayTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final day = ref.watch(selectedTaskDateProvider);
  return ref
      .watch(tasksProvider)
      .whenData((all) => all.where((t) => isSameDay(t.dueDate, day)).toList());
});

/// Days that still have unfinished tasks (for the calendar strip dots).
final pendingTaskDaysProvider = Provider<Set<DateTime>>((ref) {
  final all = ref.watch(tasksProvider).asData?.value ?? const <Task>[];
  return {
    for (final t in all)
      if (!t.isCompleted) dateOnly(t.dueDate),
  };
});
