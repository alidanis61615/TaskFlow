import '../models/task.dart';

enum TaskSort { priority, newest, dueDate }

class TaskQuery {
  static List<Task> apply(
    List<Task> tasks, {
    String search = '',
    String category = 'Tümü',
    int filter = 0,
    TaskSort sort = TaskSort.priority,
  }) {
    final query = search.toLowerCase();
    final shown = tasks.where((task) {
      final matches = '${task.title} ${task.description}'
          .toLowerCase()
          .contains(query);
      final status =
          filter == 0 ||
          (filter == 1 && !task.completed) ||
          (filter == 2 && task.completed) ||
          (filter == 3 && task.priority == 2 && !task.completed);
      return matches &&
          status &&
          (category == 'Tümü' || task.category == category);
    }).toList();
    shown.sort((a, b) {
      if (sort == TaskSort.newest) return b.createdAt.compareTo(a.createdAt);
      if (sort == TaskSort.dueDate) {
        if (a.dueDate == null && b.dueDate != null) return 1;
        if (a.dueDate != null && b.dueDate == null) return -1;
        if (a.dueDate != null && b.dueDate != null) {
          final byDate = a.dueDate!.compareTo(b.dueDate!);
          if (byDate != 0) return byDate;
        }
      }
      if (a.completed != b.completed) return a.completed ? 1 : -1;
      final priority = b.priority.compareTo(a.priority);
      return priority == 0 ? b.createdAt.compareTo(a.createdAt) : priority;
    });
    return shown;
  }
}
