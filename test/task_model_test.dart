import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/models/task.dart';

void main() {
  test('Task serializes completion', () {
    final task = Task(title: 'Study', createdAt: DateTime(2026));
    expect(task.toMap()['completed'], 0);
    expect(task.copyWith(completed: true).toMap()['completed'], 1);
  });
}
