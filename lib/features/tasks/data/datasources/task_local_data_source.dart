import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/task_model.dart';

abstract interface class TaskLocalDataSource {
  Future<List<TaskModel>> getTasks();
  Future<void> saveTask(TaskModel task);
  Future<void> deleteTask(String id);
}

class SqliteTaskLocalDataSource implements TaskLocalDataSource {
  const SqliteTaskLocalDataSource(this._db);

  final Database _db;

  @override
  Future<List<TaskModel>> getTasks() async {
    final rows = await _db.query(DbTables.tasks, orderBy: 'created_at ASC');
    return rows.map(TaskModel.fromMap).toList();
  }

  @override
  Future<void> saveTask(TaskModel task) async {
    await _db.insert(
      DbTables.tasks,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    await _db.delete(DbTables.tasks, where: 'id = ?', whereArgs: [id]);
  }
}
