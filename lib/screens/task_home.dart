import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_database.dart';
import '../services/task_repository.dart';
import '../services/task_query.dart';
import '../widgets/task_editor.dart';

class TaskHome extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool dark;
  final TaskRepository? repository;
  const TaskHome({
    super.key,
    required this.onThemeToggle,
    required this.dark,
    this.repository,
  });
  @override
  State<TaskHome> createState() => _TaskHomeState();
}

class _TaskHomeState extends State<TaskHome> {
  TaskRepository get repository => widget.repository ?? TaskDatabase.instance;
  List<Task> tasks = [];
  String? loadError;
  String search = '';
  int filter = 0;
  bool newestFirst = false;
  bool dueFirst = false;
  String categoryFilter = 'Tümü';
  static const categories = Task.categories;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    try {
      final result = await repository.all();
      if (mounted) {
        setState(() {
          tasks = result;
          loadError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => loadError = 'Görevler yüklenemedi. Yeniden deneyebilirsiniz.',
        );
      }
    }
  }

  void showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> edit([Task? task]) async {
    final saved = await showDialog<Task>(
      context: context,
      builder: (_) => TaskEditor(task: task),
    );
    if (saved != null) {
      try {
        await repository.save(saved);
        await refresh();
      } catch (_) {
        showError('Görev kaydedilemedi. Lütfen yeniden deneyin.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = TaskQuery.apply(
      tasks,
      search: search,
      category: categoryFilter,
      filter: filter,
      sort: newestFirst
          ? TaskSort.newest
          : dueFirst
          ? TaskSort.dueDate
          : TaskSort.priority,
    );
    final done = tasks.where((t) => t.completed).length;
    final high = tasks.where((t) => t.priority == 2 && !t.completed).length;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final overdue = tasks
        .where(
          (t) =>
              !t.completed && t.dueDate != null && t.dueDate!.isBefore(today),
        )
        .length;
    final dueToday = tasks
        .where(
          (t) =>
              !t.completed &&
              t.dueDate != null &&
              DateUtils.isSameDay(t.dueDate, today),
        )
        .toList();
    final dueTomorrow = tasks
        .where(
          (t) =>
              !t.completed &&
              t.dueDate != null &&
              DateUtils.isSameDay(
                t.dueDate,
                today.add(const Duration(days: 1)),
              ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskFlow'),
        actions: [
          IconButton(
            onPressed: widget.onThemeToggle,
            icon: Icon(widget.dark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Tema değiştir',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => edit(),
        icon: const Icon(Icons.add),
        label: const Text('Görev ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          if (loadError != null)
            Card(
              child: ListTile(
                title: Text(loadError!),
                trailing: TextButton(
                  onPressed: refresh,
                  child: const Text('Yeniden dene'),
                ),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Görev özeti',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('$done / ${tasks.length} görev tamamlandı'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: tasks.isEmpty ? 0 : done / tasks.length,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.pending_actions, size: 18),
                        label: Text('${tasks.length - done} aktif'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.priority_high, size: 18),
                        label: Text('$high önemli'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.warning_amber, size: 18),
                        label: Text('$overdue geciken'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (overdue > 0 || dueToday.isNotEmpty || dueTomorrow.isNotEmpty)
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications_active_outlined),
                        SizedBox(width: 8),
                        Text(
                          'Yaklaşan görevler',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (overdue > 0) Text('$overdue geciken görevin var.'),
                    if (dueToday.isNotEmpty)
                      Text(
                        'Bugün bitmesi gereken: ${dueToday.map((t) => t.title).take(3).join(', ')}',
                      ),
                    if (dueTomorrow.isNotEmpty)
                      Text(
                        'Yarın bitmesi gereken: ${dueTomorrow.map((t) => t.title).take(3).join(', ')}',
                      ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bu uyarılar uygulama açıkken gösterilir.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Görev ara...',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => search = v),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Tümü', ...categories]
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: categoryFilter == c,
                        onSelected: (_) => setState(() => categoryFilter = c),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Tümü')),
                ButtonSegment(value: 1, label: Text('Aktif')),
                ButtonSegment(value: 2, label: Text('Biten')),
                ButtonSegment(value: 3, label: Text('Önemli')),
              ],
              selected: {filter},
              onSelectionChanged: (v) => setState(() => filter = v.first),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() {
                if (!newestFirst && !dueFirst) {
                  dueFirst = true;
                } else if (dueFirst) {
                  dueFirst = false;
                  newestFirst = true;
                } else {
                  newestFirst = false;
                }
              }),
              icon: const Icon(Icons.sort),
              label: Text(
                dueFirst
                    ? 'Son tarihe göre'
                    : newestFirst
                    ? 'En yeni önce'
                    : 'Önceliğe göre',
              ),
            ),
          ),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Görev bulunamadı')),
            )
          else
            ...shown.map(
              (task) => Card(
                child: ListTile(
                  leading: Checkbox(
                    value: task.completed,
                    onChanged: (v) async {
                      try {
                        await repository.save(
                          task.copyWith(completed: v ?? false),
                        );
                        await refresh();
                      } catch (_) {
                        showError(
                          'Görev güncellenemedi. Lütfen yeniden deneyin.',
                        );
                      }
                    },
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: task.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    '${task.description}\n${task.category} · Öncelik: ${['Düşük', 'Normal', 'Yüksek'][task.priority]}${task.dueDate == null ? '' : '\nSon tarih: ${task.dueDate!.day}.${task.dueDate!.month}.${task.dueDate!.year}'}${!task.completed && task.dueDate != null && task.dueDate!.isBefore(today) ? ' · GECİKTİ' : ''}',
                  ),
                  isThreeLine: true,
                  tileColor:
                      !task.completed &&
                          task.dueDate != null &&
                          task.dueDate!.isBefore(today)
                      ? Theme.of(context).colorScheme.errorContainer
                            .withValues(alpha: 0.35)
                      : null,
                  onTap: () => edit(task),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Sil',
                    onPressed: () async {
                      if (task.id == null) return;
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Görev silinsin mi?'),
                          content: Text(
                            '"${task.title}" kalıcı olarak silinecek.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Vazgeç'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('Sil'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      try {
                        await repository.delete(task.id!);
                        await refresh();
                      } catch (_) {
                        showError('Görev silinemedi. Lütfen yeniden deneyin.');
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
