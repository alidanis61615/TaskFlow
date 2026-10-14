import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:taskflow/models/task.dart';
import 'package:taskflow/services/task_database.dart';

void main() {
  sqfliteFfiInit();
  late TaskDatabase store;
  setUp(
    () => store = TaskDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    ),
  );
  tearDown(() async => store.close());

  test(
    'Ekleme, düzenleme, tamamlama ve silme SQLite üzerinde çalışır',
    () async {
      await store.save(
        Task(
          title: "Görev ' özel karakter",
          category: 'Okul',
          createdAt: DateTime(2026),
          dueDate: DateTime(2026, 10, 15),
        ),
      );
      final first = (await store.all()).single;
      expect(first.id, isNotNull);
      expect(first.category, 'Okul');
      expect(first.dueDate, DateTime(2026, 10, 15));
      await store.save(first.copyWith(title: 'Güncellendi', completed: true));
      final updated = (await store.all()).single;
      expect(updated.title, 'Güncellendi');
      expect(updated.completed, isTrue);
      await store.delete(updated.id!);
      expect(await store.all(), isEmpty);
    },
  );
  test('Geçersiz görev mevcut kayıtları değiştirmez', () async {
    await store.save(Task(title: 'Korunacak', createdAt: DateTime(2026)));
    await expectLater(
      store.save(Task(title: ' ', createdAt: DateTime(2026))),
      throwsArgumentError,
    );
    expect((await store.all()).single.title, 'Korunacak');
  });
  test('Sürüm 1 kayıtları kaybolmadan sürüm 3 alanları eklenir', () async {
    final directory = await Directory.systemTemp.createTemp(
      'taskflow-migration-',
    );
    final path = '${directory.path}/tasks.db';
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, description TEXT NOT NULL, priority INTEGER NOT NULL, completed INTEGER NOT NULL, created_at TEXT NOT NULL)',
          );
        },
      ),
    );
    await old.insert('tasks', {
      'title': 'Eski görev',
      'description': '',
      'priority': 1,
      'completed': 0,
      'created_at': '2026-01-01T00:00:00.000',
    });
    await old.close();
    final migrated = TaskDatabase(
      factory: databaseFactoryFfi,
      databasePath: path,
    );
    try {
      final task = (await migrated.all()).single;
      expect(task.title, 'Eski görev');
      expect(task.category, 'Genel');
      expect(task.dueDate, isNull);
      expect(await (await migrated.database).getVersion(), 3);
    } finally {
      await migrated.close();
      await directory.delete(recursive: true);
    }
  });
}
