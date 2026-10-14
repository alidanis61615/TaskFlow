import 'package:flutter/material.dart';

import '../models/task.dart';

class TaskEditor extends StatefulWidget {
  const TaskEditor({super.key, this.task});
  final Task? task;
  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title;
  late final TextEditingController description;
  late int priority;
  late String category;
  DateTime? due;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.task?.title ?? '');
    description = TextEditingController(text: widget.task?.description ?? '');
    priority = widget.task?.priority ?? 1;
    category = widget.task?.category ?? 'Genel';
    due = widget.task?.dueDate;
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.task == null ? 'Yeni görev' : 'Görevi düzenle'),
    content: Form(
      key: form,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Başlık'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Görev başlığı gerekli'
                  : null,
            ),
            TextFormField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Açıklama'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    due == null
                        ? 'Son tarih: Yok'
                        : 'Son tarih: ${due!.day}.${due!.month}.${due!.year}',
                  ),
                ),
                IconButton(
                  tooltip: 'Tarih seç',
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: due ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (mounted && picked != null) setState(() => due = picked);
                  },
                ),
                IconButton(
                  tooltip: 'Tarihi kaldır',
                  icon: const Icon(Icons.close),
                  onPressed: due == null
                      ? null
                      : () => setState(() => due = null),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: Task.categories
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => category = value ?? 'Genel'),
            ),
            DropdownButtonFormField<int>(
              initialValue: priority,
              decoration: const InputDecoration(labelText: 'Öncelik'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Düşük')),
                DropdownMenuItem(value: 1, child: Text('Normal')),
                DropdownMenuItem(value: 2, child: Text('Yüksek')),
              ],
              onChanged: (value) => setState(() => priority = value ?? 1),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('İptal'),
      ),
      FilledButton(
        onPressed: () {
          if (!form.currentState!.validate()) return;
          Navigator.pop(
            context,
            Task(
              id: widget.task?.id,
              title: title.text.trim(),
              description: description.text.trim(),
              priority: priority,
              completed: widget.task?.completed ?? false,
              createdAt: widget.task?.createdAt ?? DateTime.now(),
              dueDate: due,
              category: category,
            ),
          );
        },
        child: const Text('Kaydet'),
      ),
    ],
  );
}
