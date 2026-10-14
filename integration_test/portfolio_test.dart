import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow/app.dart';
import 'package:taskflow/models/task.dart';
import 'package:taskflow/services/task_database.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android: filled tasks, search, completion filter and saved theme',
    (tester) async {
      final db = TaskDatabase.instance;
      expect(await db.all(), isEmpty);
      final now = DateTime.now();
      final titles = [
        'Portföy sunumunu hazırla',
        'Kalori Takip ekranlarını kontrol et',
        'Okuma hedefini tamamla',
        'Haftalık alışveriş listesi',
        'SQLite testlerini çalıştır',
        'Proje açıklamalarını güncelle',
      ];
      for (var i = 0; i < titles.length; i++) {
        await db.save(
          Task(
            title: titles[i],
            description: 'Portföy için oluşturulmuş örnek görev',
            category: Task.categories[i % Task.categories.length],
            priority: i == 0 ? 2 : 1,
            completed: i >= 4,
            createdAt: now.subtract(Duration(hours: i)),
            dueDate: i == 0 ? DateTime(now.year, now.month, now.day) : null,
          ),
        );
      }
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool('dark', false);
      await tester.pumpWidget(const TaskFlowApp());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      var recordingStarted = false;
      Future<void> capture(String name) async {
        if (!recordingStarted) {
          debugPrint('PORTFOLIO_VIDEO_START');
          recordingStarted = true;
        }
        await binding.takeScreenshot(name);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 6)),
        );
        await tester.pumpAndSettle();
      }

      expect(find.text('4 aktif'), findsOneWidget);
      await capture('taskflow-light');
      final search = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Görev ara...',
      );
      await tester.enterText(search, 'Portföy');
      await tester.pumpAndSettle();
      expect(find.text('Portföy sunumunu hazırla'), findsOneWidget);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await capture('taskflow-search');
      await tester.enterText(search, '');
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Biten'));
      await tester.tap(find.text('Biten'));
      await tester.pumpAndSettle();
      expect(find.text('SQLite testlerini çalıştır'), findsOneWidget);
      await capture('taskflow-completed');
      await tester.tap(
        find.descendant(
          of: find.byType(SegmentedButton<int>),
          matching: find.text('Tümü'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tema değiştir'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      await capture('taskflow-dark');
      debugPrint('PORTFOLIO_VIDEO_END');
      expect(preferences.getBool('dark'), true);
      expect((await db.all()).length, 6);
      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
      await tester.pumpWidget(const TaskFlowApp());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      await tester.pumpAndSettle();
      expect(find.text('4 aktif'), findsOneWidget);
      expect((await db.all()).length, 6);
      expect(preferences.getBool('dark'), true);
    },
  );
}
