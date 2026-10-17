import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

abstract final class DbTables {
  static const String tasks = 'tasks';
}

class AppDatabase {
  AppDatabase._();

  static const String _name = 'azkarna.db';
  static const int _version = 2;

  static Future<Database> open() async {
    final path = p.join(await getDatabasesPath(), _name);
    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${DbTables.tasks} (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            due_date TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Tasks are now scheduled per day; existing tasks belong to the
          // day they were created.
          await db.execute(
            'ALTER TABLE ${DbTables.tasks} ADD COLUMN due_date TEXT',
          );
          await db.execute(
            'UPDATE ${DbTables.tasks} SET due_date = created_at WHERE due_date IS NULL',
          );
        }
      },
    );
  }
}

final databaseProvider = FutureProvider<Database>((ref) async {
  final db = await AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});
