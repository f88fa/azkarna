import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/task.dart';
import '../models/task_model.dart';
import 'task_local_data_source.dart';

/// Task storage backed by SharedPreferences (localStorage on the web), used
/// where SQLite is unavailable. Optionally seeds a few demo tasks on first
/// run so the UI can be explored right away.
class SharedPrefsTaskLocalDataSource implements TaskLocalDataSource {
  SharedPrefsTaskLocalDataSource(this._prefs, {bool seedDemo = false}) {
    if (seedDemo && !_prefs.containsKey(_key)) _seed();
  }

  static const String _key = 'tasks_json';

  final SharedPreferences _prefs;

  List<TaskModel> _read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>) TaskModel.fromJson(item),
      ];
    } on FormatException {
      return [];
    }
  }

  Future<void> _write(List<TaskModel> tasks) =>
      _prefs.setString(_key, jsonEncode([for (final t in tasks) t.toJson()]));

  void _seed() {
    final now = DateTime.now();
    final today = dateOnly(now);
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    TaskModel make(int i, String title, DateTime due, {bool done = false}) =>
        TaskModel(
          id: 'demo_$i',
          title: title,
          isCompleted: done,
          createdAt: now.add(Duration(seconds: i)),
          dueDate: due,
        );
    _prefs.setString(
      _key,
      jsonEncode([
        for (final t in [
          make(1, 'قراءة وردي اليومي من القرآن', today),
          make(2, 'أذكار الصباح', today, done: true),
          make(3, 'صلاة الضحى', today),
          make(4, 'زيارة الوالدين', tomorrow),
        ])
          t.toJson(),
      ]),
    );
  }

  @override
  Future<List<TaskModel>> getTasks() async => _read();

  @override
  Future<void> saveTask(TaskModel task) async {
    final tasks = _read();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      tasks[index] = task;
    } else {
      tasks.add(task);
    }
    await _write(tasks);
  }

  @override
  Future<void> deleteTask(String id) async {
    await _write(_read()..removeWhere((t) => t.id == id));
  }
}
