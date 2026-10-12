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
  final DateTime? dueDate;
  final String category;

  const Task({this.id, required this.title, this.description = '',
    this.priority = 1, this.completed = false, required this.createdAt,
    this.dueDate, this.category = 'Genel'});

  Map<String, Object?> toMap() => {
    'title': title, 'description': description, 'priority': priority,
    'completed': completed ? 1 : 0, 'created_at': createdAt.toIso8601String(),
    'due_date': dueDate?.toIso8601String(), 'category': category,
  };

  factory Task.fromMap(Map<String, Object?> map) => Task(
    id: map['id'] as int, title: map['title'] as String,
    description: map['description'] as String,
    priority: map['priority'] as int,
    completed: (map['completed'] as int) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
    dueDate: map['due_date'] == null ? null : DateTime.parse(map['due_date'] as String),
    category: (map['category'] as String?) ?? 'Genel',
  );

  Task copyWith({String? title, String? description, int? priority,
    bool? completed}) => Task(id: id, title: title ?? this.title,
    description: description ?? this.description,
    priority: priority ?? this.priority,
    completed: completed ?? this.completed, createdAt: createdAt,
    dueDate: dueDate, category: category);
}

class TaskDatabase {
  TaskDatabase._();
  static final instance = TaskDatabase._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await openDatabase(p.join(await getDatabasesPath(), 'taskflow.db'),
      version: 3, onCreate: (db, _) async {
        await db.execute('CREATE TABLE tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, description TEXT NOT NULL, priority INTEGER NOT NULL, completed INTEGER NOT NULL, created_at TEXT NOT NULL, due_date TEXT, category TEXT NOT NULL DEFAULT "Genel")');
      }, onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE tasks ADD COLUMN due_date TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE tasks ADD COLUMN category TEXT NOT NULL DEFAULT "Genel"');
        }
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
  bool newestFirst = false;
  bool dueFirst = false;
  String categoryFilter = 'Tümü';
  static const categories = ['Genel', 'İş', 'Okul', 'Kişisel', 'Alışveriş'];

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
    DateTime? due = task?.dueDate;
    String category = task?.category ?? 'Genel';
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
              const SizedBox(height: 12),
              Row(children: [Expanded(child: Text(due == null ? 'Son tarih: Yok' : 'Son tarih: ${due!.day}.${due!.month}.${due!.year}')),
                IconButton(tooltip: 'Tarih seç', icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final picked = await showDatePicker(context: context,
                      initialDate: due ?? DateTime.now(),
                      firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (picked != null) update(() => due = picked);
                  }),
                IconButton(tooltip: 'Tarihi kaldır', icon: const Icon(Icons.close),
                  onPressed: due == null ? null : () => update(() => due = null)),
              ]),
              DropdownButtonFormField<String>(initialValue: category,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => update(() => category = v ?? 'Genel')),
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
                createdAt: task?.createdAt ?? DateTime.now(), dueDate: due,
                category: category));
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
      return matches && (categoryFilter == 'Tümü' || t.category == categoryFilter) && (filter == 0 || (filter == 1 && !t.completed) ||
        (filter == 2 && t.completed) || (filter == 3 && t.priority == 2 && !t.completed));
    }).toList();
    if (newestFirst) {
      shown.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (dueFirst) {
      shown.sort((a,b) {
        if(a.dueDate == null) return b.dueDate == null ? 0 : 1;
        if(b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    }
    final done = tasks.where((t) => t.completed).length;
    final high = tasks.where((t) => t.priority == 2 && !t.completed).length;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final overdue = tasks.where((t) => !t.completed && t.dueDate != null && t.dueDate!.isBefore(today)).length;
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
          const SizedBox(height: 6),
          Text('${tasks.length - done} aktif · $high yüksek öncelikli · $overdue geciken'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: tasks.isEmpty ? 0 : done / tasks.length),
          const SizedBox(height: 16),
          TextField(decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search), hintText: 'Görev ara...',
            border: OutlineInputBorder()),
            onChanged: (v) => setState(() => search = v)),
          const SizedBox(height: 8),
          SingleChildScrollView(scrollDirection: Axis.horizontal,
            child: Row(children: ['Tümü', ...categories].map((c) =>
              Padding(padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(label: Text(c), selected: categoryFilter == c,
                  onSelected: (_) => setState(() => categoryFilter = c)))).toList())),
          const SizedBox(height: 8),
          SegmentedButton<int>(segments: const [
            ButtonSegment(value: 0, label: Text('Tümü')),
            ButtonSegment(value: 1, label: Text('Aktif')),
            ButtonSegment(value: 2, label: Text('Biten')),
            ButtonSegment(value: 3, label: Text('Önemli')),
          ], selected: {filter},
            onSelectionChanged: (v) => setState(() => filter = v.first)),
          Align(alignment: Alignment.centerRight, child: TextButton.icon(
            onPressed: () => setState(() {if (!newestFirst && !dueFirst) {dueFirst = true;} else if (dueFirst) {dueFirst = false; newestFirst = true;} else {newestFirst = false;}}),
            icon: const Icon(Icons.sort),
            label: Text(dueFirst ? 'Son tarihe göre' : newestFirst ? 'En yeni önce' : 'Önceliğe göre'))),
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
                  subtitle: Text('${task.description}\n${task.category} · Öncelik: ${['Düşük', 'Normal', 'Yüksek'][task.priority]}${task.dueDate == null ? '' : '\nSon tarih: ${task.dueDate!.day}.${task.dueDate!.month}.${task.dueDate!.year}'}${!task.completed && task.dueDate != null && task.dueDate!.isBefore(today) ? ' · GECİKTİ' : ''}'),
                  isThreeLine: true,
                  onTap: () => edit(task),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline),
                    tooltip: 'Sil', onPressed: () async {
                      if (task.id == null) return;
                      final confirmed = await showDialog<bool>(context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Görev silinsin mi?'),
                          content: Text('"${task.title}" kalıcı olarak silinecek.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dialogContext, false),
                              child: const Text('Vazgeç')),
                            FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
                              child: const Text('Sil')),
                          ],
                        ));
                      if (confirmed != true) return;
                      await TaskDatabase.instance.delete(task.id!);
                      await refresh();
                    }),
                ));
              })),
        ])),
    );
  }
}
