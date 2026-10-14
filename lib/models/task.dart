class Task {
  static const categories = ['Genel', 'İş', 'Okul', 'Kişisel', 'Alışveriş'];
  final int? id;
  final String title;
  final String description;
  final int priority;
  final bool completed;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String category;

  const Task({
    this.id,
    required this.title,
    this.description = '',
    this.priority = 1,
    this.completed = false,
    required this.createdAt,
    this.dueDate,
    this.category = 'Genel',
  });

  Map<String, Object?> toMap() => {
    'title': title,
    'description': description,
    'priority': priority,
    'completed': completed ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'due_date': dueDate?.toIso8601String(),
    'category': category,
  };

  factory Task.fromMap(Map<String, Object?> map) => Task(
    id: map['id'] as int,
    title: map['title'] as String,
    description: map['description'] as String,
    priority: map['priority'] as int,
    completed: (map['completed'] as int) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
    dueDate: map['due_date'] == null
        ? null
        : DateTime.parse(map['due_date'] as String),
    category: (map['category'] as String?) ?? 'Genel',
  );

  Task copyWith({
    String? title,
    String? description,
    int? priority,
    bool? completed,
  }) => Task(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    priority: priority ?? this.priority,
    completed: completed ?? this.completed,
    createdAt: createdAt,
    dueDate: dueDate,
    category: category,
  );
}
