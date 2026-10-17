import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

abstract final class DbTables {
  static const String tasks = 'tasks';
}

class AppDatabase {
  AppDatabase._();

  static const String _name = 'azkarna.db';
  static const int _version = 1;

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
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }
}

final databaseProvider = FutureProvider<Database>((ref) async {
  final db = await AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});
