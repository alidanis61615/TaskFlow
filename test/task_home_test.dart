import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/models/task.dart';
import 'package:taskflow/screens/task_home.dart';
import 'package:taskflow/services/task_repository.dart';

class MemoryTasks implements TaskRepository {
  final tasks = <Task>[];
  @override
  Future<List<Task>> all() async => List.of(tasks);
  @override
  Future<void> save(Task task) async {
    if (task.id == null) {
      tasks.add(
        Task(
          id: tasks.length + 1,
          title: task.title,
          description: task.description,
          priority: task.priority,
          completed: task.completed,
          createdAt: task.createdAt,
          dueDate: task.dueDate,
          category: task.category,
        ),
      );
    } else {
      tasks[tasks.indexWhere((item) => item.id == task.id)] = task;
    }
  }

  @override
  Future<void> delete(int id) async =>
      tasks.removeWhere((task) => task.id == id);
}

void main() {
  testWidgets('Ekrandan görev eklenir, aranır, tamamlanır ve onayla silinir', (
    tester,
  ) async {
    final repository = MemoryTasks();
    await tester.pumpWidget(
      MaterialApp(
        home: TaskHome(
          onThemeToggle: () {},
          dark: false,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Görev ekle'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Başlık',
      ),
      'Portföyü tamamla',
    );
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(repository.tasks.single.title, 'Portföyü tamamla');
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Görev ara...',
      ),
      'bulunmayan',
    );
    await tester.pumpAndSettle();
    expect(find.text('Görev bulunamadı'), findsOneWidget);
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Görev ara...',
      ),
      'Portföy',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(repository.tasks.single.completed, isTrue);
    await tester.tap(find.byTooltip('Sil'));
    await tester.pumpAndSettle();
    expect(find.text('Görev silinsin mi?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Sil'));
    await tester.pumpAndSettle();
    expect(repository.tasks, isEmpty);
  });
  testWidgets('Boş başlık kaydedilmez ve kullanıcıya açıklanır', (
    tester,
  ) async {
    final repository = MemoryTasks();
    await tester.pumpWidget(
      MaterialApp(
        home: TaskHome(
          onThemeToggle: () {},
          dark: false,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Görev ekle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Görev başlığı gerekli'), findsOneWidget);
    expect(repository.tasks, isEmpty);
  });

  testWidgets('Klavye ve küçük ekranda görev özeti taşmaz', (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final repository = MemoryTasks();
    repository.tasks.add(
      Task(
        id: 1,
        title: 'Küçük ekran görevi',
        createdAt: DateTime.now(),
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TaskHome(
          onThemeToggle: () {},
          dark: false,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Biten'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Biten'), findsOneWidget);
  });
}
