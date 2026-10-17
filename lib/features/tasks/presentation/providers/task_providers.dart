import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../data/datasources/task_local_data_source.dart';
import '../../data/datasources/task_prefs_data_source.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

final taskLocalDataSourceProvider = FutureProvider<TaskLocalDataSource>((
  ref,
) async {
  if (kIsWeb) {
    // SQLite is unavailable on the web: use localStorage with demo data.
    return SharedPrefsTaskLocalDataSource(
      ref.watch(sharedPreferencesProvider),
      seedDemo: true,
    );
  }
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

  /// Adds a task. Throws if it could not be saved so callers can show an
  /// error. [repeatDays] (weekdays) repeats it weekly at the same
  /// [timeMinutes]; [remind] notifies at that time.
  Future<void> add(
    String title, {
    DateTime? dueDate,
    int? timeMinutes,
    Set<int> repeatDays = const {},
    bool remind = false,
  }) async {
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
        timeMinutes: timeMinutes,
        repeatDays: repeatDays,
        remind: remind && timeMinutes != null,
      ),
    );
    state = AsyncData(await repository.getTasks());
  }

  /// Completes/uncompletes the occurrence of [task] on [day].
  Future<void> toggle(Task task, DateTime day) async {
    final repository = await _repository;
    await repository.saveTask(task.toggledOn(day));
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

int _byTimeThenCreated(Task a, Task b) {
  final ta = a.timeMinutes, tb = b.timeMinutes;
  if (ta != null && tb != null && ta != tb) return ta.compareTo(tb);
  if (ta != null && tb == null) return -1;
  if (ta == null && tb != null) return 1;
  return a.createdAt.compareTo(b.createdAt);
}

List<Task> _tasksOn(List<Task> all, DateTime day) =>
    all.where((t) => t.occursOn(day)).toList()..sort(_byTimeThenCreated);

/// Tasks of the selected day (including repeating ones), ordered by time.
final selectedDayTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final day = ref.watch(selectedTaskDateProvider);
  return ref.watch(tasksProvider).whenData((all) => _tasksOn(all, day));
});

/// Today's tasks (including repeating ones), ordered by time. Used by the
/// home screen, independent of the day selected in the calendar.
final todayTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  return ref
      .watch(tasksProvider)
      .whenData((all) => _tasksOn(all, dateOnly(DateTime.now())));
});
