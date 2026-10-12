import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaskFlowApp());
}

class Task {
  final int? id;
  final String title;
  final String description;
  final int priority;
  final bool completed;
  final DateTime createdAt;

  const Task({this.id, required this.title, this.description = '',
    this.priority = 1, this.completed = false, required this.createdAt});

  Map<String, Object?> toMap() => {
    'title': title, 'description': description, 'priority': priority,
    'completed': completed ? 1 : 0, 'created_at': createdAt.toIso8601String(),
  };

  factory Task.fromMap(Map<String, Object?> map) => Task(
    id: map['id'] as int, title: map['title'] as String,
    description: map['description'] as String,
    priority: map['priority'] as int,
    completed: (map['completed'] as int) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  Task copyWith({String? title, String? description, int? priority,
    bool? completed}) => Task(id: id, title: title ?? this.title,
    description: description ?? this.description,
    priority: priority ?? this.priority,
    completed: completed ?? this.completed, createdAt: createdAt);
}

class TaskDatabase {
  TaskDatabase._();
  static final instance = TaskDatabase._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await openDatabase(p.join(await getDatabasesPath(), 'taskflow.db'),
      version: 1, onCreate: (db, _) async {
        await db.execute('CREATE TABLE tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, description TEXT NOT NULL, priority INTEGER NOT NULL, completed INTEGER NOT NULL, created_at TEXT NOT NULL)');
      });
    return _db!;
  }

  Future<List<Task>> all() async {
    final db = await database;
    final rows = await db.query('tasks',
      orderBy: 'completed ASC, priority DESC, created_at DESC');
    return rows.map(Task.fromMap).toList();
  }

  Future<void> save(Task task) async {
    final db = await database;
    if (task.id == null) {
      await db.insert('tasks', task.toMap());
    } else {
      await db.update('tasks', task.toMap(),
        where: 'id = ?', whereArgs: [task.id]);
    }
  }

  Future<void> delete(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}

class TaskFlowApp extends StatefulWidget {
  const TaskFlowApp({super.key});
  @override
  State<TaskFlowApp> createState() => _TaskFlowAppState();
}

class _TaskFlowAppState extends State<TaskFlowApp> {
  bool dark = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => dark = prefs.getBool('dark') ?? false);
  }

  Future<void> _toggle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark', !dark);
    if (mounted) setState(() => dark = !dark);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TaskFlow', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    darkTheme: ThemeData(colorSchemeSeed: Colors.indigo,
      brightness: Brightness.dark, useMaterial3: true),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: TaskHome(onThemeToggle: _toggle, dark: dark),
  );
}

class TaskHome extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool dark;
  const TaskHome({super.key, required this.onThemeToggle, required this.dark});
  @override
  State<TaskHome> createState() => _TaskHomeState();
}

class _TaskHomeState extends State<TaskHome> {
  List<Task> tasks = [];
  String search = '';
  int filter = 0;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final result = await TaskDatabase.instance.all();
    if (mounted) setState(() => tasks = result);
  }

  Future<void> edit([Task? task]) async {
    final title = TextEditingController(text: task?.title ?? '');
    final description = TextEditingController(text: task?.description ?? '');
    int priority = task?.priority ?? 1;
    final saved = await showDialog<Task>(context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(task == null ? 'Yeni görev' : 'Görevi düzenle'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(
                labelText: 'Başlık')),
              TextField(controller: description, decoration: const InputDecoration(
                labelText: 'Açıklama')),
              DropdownButtonFormField<int>(initialValue: priority,
                decoration: const InputDecoration(labelText: 'Öncelik'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Düşük')),
                  DropdownMenuItem(value: 1, child: Text('Normal')),
                  DropdownMenuItem(value: 2, child: Text('Yüksek')),
                ], onChanged: (v) => update(() => priority = v ?? 1)),
            ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('İptal')),
            FilledButton(onPressed: () {
              if (title.text.trim().isEmpty) return;
              Navigator.pop(context, Task(id: task?.id,
                title: title.text.trim(), description: description.text.trim(),
                priority: priority, completed: task?.completed ?? false,
                createdAt: task?.createdAt ?? DateTime.now()));
            }, child: const Text('Kaydet')),
          ],
        ),
      ));
    title.dispose();
    description.dispose();
    if (saved != null) {
      await TaskDatabase.instance.save(saved);
      await refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = tasks.where((t) {
      final matches = ('${t.title} ${t.description}')
        .toLowerCase().contains(search.toLowerCase());
      return matches && (filter == 0 || (filter == 1 && !t.completed) ||
        (filter == 2 && t.completed));
    }).toList();
    final done = tasks.where((t) => t.completed).length;
    return Scaffold(
      appBar: AppBar(title: const Text('TaskFlow'),
        actions: [IconButton(
          onPressed: widget.onThemeToggle,
          icon: Icon(widget.dark ? Icons.light_mode : Icons.dark_mode),
          tooltip: 'Tema değiştir')]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => edit(), icon: const Icon(Icons.add),
        label: const Text('Görev ekle')),
      body: Padding(padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text('$done / ${tasks.length} görev tamamlandı'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: tasks.isEmpty ? 0 : done / tasks.length),
          const SizedBox(height: 16),
          TextField(decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search), hintText: 'Görev ara...',
            border: OutlineInputBorder()),
            onChanged: (v) => setState(() => search = v)),
          const SizedBox(height: 8),
          SegmentedButton<int>(segments: const [
            ButtonSegment(value: 0, label: Text('Tümü')),
            ButtonSegment(value: 1, label: Text('Aktif')),
            ButtonSegment(value: 2, label: Text('Biten')),
          ], selected: {filter},
            onSelectionChanged: (v) => setState(() => filter = v.first)),
          const SizedBox(height: 8),
          Expanded(child: shown.isEmpty
            ? const Center(child: Text('Görev bulunamadı'))
            : ListView.builder(itemCount: shown.length,
              itemBuilder: (context, i) {
                final task = shown[i];
                return Card(child: ListTile(
                  leading: Checkbox(value: task.completed,
                    onChanged: (v) async {
                      await TaskDatabase.instance.save(
                        task.copyWith(completed: v ?? false));
                      await refresh();
                    }),
                  title: Text(task.title, style: TextStyle(
                    decoration: task.completed
                      ? TextDecoration.lineThrough : null)),
                  subtitle: Text('${task.description}\nÖncelik: ${['Düşük', 'Normal', 'Yüksek'][task.priority]}'),
                  isThreeLine: true,
                  onTap: () => edit(task),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline),
                    tooltip: 'Sil', onPressed: () async {
                      if (task.id == null) return;
                      await TaskDatabase.instance.delete(task.id!);
                      await refresh();
                    }),
                ));
              })),
        ])),
    );
  }
}
