import '../models/task.dart';

abstract class TaskRepository {
  Future<List<Task>> all();
  Future<void> save(Task task);
  Future<void> delete(int id);
}
