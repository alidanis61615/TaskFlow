import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/models/task.dart';
import 'package:taskflow/services/task_query.dart';

void main() {
  final tasks = [
    Task(
      id: 1,
      title: 'Matematik',
      description: 'DGS çalış',
      priority: 2,
      category: 'Okul',
      createdAt: DateTime(2026, 10, 1),
      dueDate: DateTime(2026, 10, 15),
    ),
    Task(
      id: 2,
      title: 'Proje',
      priority: 1,
      category: 'İş',
      createdAt: DateTime(2026, 10, 2),
    ),
    Task(
      id: 3,
      title: 'Kitap',
      priority: 2,
      category: 'Okul',
      completed: true,
      createdAt: DateTime(2026, 10, 3),
      dueDate: DateTime(2026, 10, 14),
    ),
  ];
  test('Arama açıklamayı ve büyük/küçük harfleri kapsar', () {
    expect(TaskQuery.apply(tasks, search: 'dgs').map((item) => item.id), [1]);
    expect(TaskQuery.apply(tasks, search: 'PROJE').map((item) => item.id), [2]);
  });
  test('Kategori ve durum filtreleri birlikte uygulanır', () {
    expect(
      TaskQuery.apply(
        tasks,
        category: 'Okul',
        filter: 1,
      ).map((item) => item.id),
      [1],
    );
    expect(TaskQuery.apply(tasks, filter: 2).map((item) => item.id), [3]);
    expect(TaskQuery.apply(tasks, filter: 3).map((item) => item.id), [1]);
  });
  test('Öncelik sırası aktif görevleri öne alır', () {
    expect(TaskQuery.apply(tasks).map((item) => item.id), [1, 2, 3]);
  });
  test('Son tarih sırası tarihi olmayanları sona alır', () {
    expect(
      TaskQuery.apply(tasks, sort: TaskSort.dueDate).map((item) => item.id),
      [3, 1, 2],
    );
  });
  test('Yeni görev sırası özgün listeyi değiştirmez', () {
    expect(
      TaskQuery.apply(tasks, sort: TaskSort.newest).map((item) => item.id),
      [3, 2, 1],
    );
    expect(tasks.map((item) => item.id), [1, 2, 3]);
  });
}
