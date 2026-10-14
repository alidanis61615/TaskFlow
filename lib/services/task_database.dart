import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/task.dart';
import 'task_repository.dart';

class TaskDatabase implements TaskRepository {
  TaskDatabase({DatabaseFactory? factory, String? databasePath})
    : _factory = factory,
      _path = databasePath;
  static final instance = TaskDatabase();
  final DatabaseFactory? _factory;
  final String? _path;
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final factory = _factory ?? databaseFactory;
    final path =
        _path ?? p.join(await factory.getDatabasesPath(), 'taskflow.db');
    _db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, description TEXT NOT NULL, priority INTEGER NOT NULL, completed INTEGER NOT NULL, created_at TEXT NOT NULL, due_date TEXT, category TEXT NOT NULL DEFAULT "Genel")',
          );
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE tasks ADD COLUMN due_date TEXT');
          }
          if (oldVersion < 3) {
            await db.execute(
              'ALTER TABLE tasks ADD COLUMN category TEXT NOT NULL DEFAULT "Genel"',
            );
          }
        },
      ),
    );
    return _db!;
  }

  @override
  Future<List<Task>> all() async {
    final db = await database;
    final rows = await db.query(
      'tasks',
      orderBy: 'completed ASC, priority DESC, created_at DESC',
    );
    return rows.map(Task.fromMap).toList();
  }

  @override
  Future<void> save(Task task) async {
    if (task.title.trim().isEmpty ||
        task.priority < 0 ||
        task.priority > 2 ||
        !Task.categories.contains(task.category)) {
      throw ArgumentError('Geçersiz görev');
    }
    final db = await database;
    if (task.id == null) {
      await db.insert('tasks', task.toMap());
    } else {
      await db.update(
        'tasks',
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  @override
  Future<void> delete(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
