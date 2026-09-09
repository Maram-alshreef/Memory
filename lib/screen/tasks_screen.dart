import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<DailyTask> _tasks = [];
  final DatabaseHelper _database = DatabaseHelper.instance;
  bool _isLoading = true;

  static const Color primaryGreen = Color(0xFF2E7D6E);
  static const Color darkGreen = Color(0xFF1F5E53);
  static const Color background = Color(0xFFF4FAF7);

  int get _completed => _tasks.where((task) => task.isDone).length;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final rows = await _database.getTasks();
      if (!mounted) return;
      setState(() {
        _tasks
          ..clear()
          ..addAll(rows.map(DailyTask.fromMap));
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحميل المهام')));
    }
  }

  Future<void> _openForm({DailyTask? task}) async {
    final result = await showDialog<DailyTask>(
      context: context,
      builder: (_) => TaskFormDialog(task: task),
    );
    if (!mounted || result == null) return;

    try {
      if (task == null) {
        final id = await _database.insertTask(result.toMap());
        result.id = id;
        setState(() => _tasks.add(result));
      } else {
        await _database.updateTask(task.id!, result.toMap());
        result.id = task.id;
        setState(() => _tasks[_tasks.indexOf(task)] = result);
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ المهمة')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(task == null ? 'تمت إضافة المهمة' : 'تم تعديل المهمة'), backgroundColor: primaryGreen));
  }

  Future<void> _deleteTask(DailyTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف «${task.title}»؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _database.deleteTask(task.id!);
      setState(() => _tasks.remove(task));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المهمة')));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حذف المهمة')));
    }
  }

  Future<void> _toggleTask(DailyTask task) async {
    final newValue = !task.isDone;
    try {
      await _database.updateTask(task.id!, {'is_done': newValue ? 1 : 0});
      if (!mounted) return;
      setState(() => task.isDone = newValue);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newValue ? 'تم إنجاز المهمة' : 'تمت إعادة المهمة')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديث حالة المهمة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _tasks.isEmpty ? 0.0 : _completed / _tasks.length;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(title: const Text('المواعيد والمهام'), centerTitle: true, backgroundColor: Colors.transparent, foregroundColor: darkGreen, elevation: 0),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
          children: [
            if (_isLoading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())) else ...[
              Card(
                elevation: 0,
                color: primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    SizedBox(width: 70, height: 70, child: Stack(alignment: Alignment.center, children: [CircularProgressIndicator(value: progress, color: Colors.white, backgroundColor: Colors.white24, strokeWidth: 7), Text('${(progress * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('إنجاز اليوم', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text('أنجزت $_completed من ${_tasks.length} مهام', style: const TextStyle(color: Colors.white70))])),
                  ]),
                ),
              ),
              const SizedBox(height: 22),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('قائمة اليوم', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: darkGreen)), Text('${_tasks.length} مهام', style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w600))]),
              const SizedBox(height: 12),
              ..._tasks.map(_buildTaskCard),
            ],
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(onPressed: () => _openForm(), backgroundColor: primaryGreen, foregroundColor: Colors.white, icon: const Icon(Icons.add_task), label: const Text('إضافة مهمة')),
      ),
    );
  }

  Widget _buildTaskCard(DailyTask task) {
    final priorityColor = task.priority == 'عالية' ? Colors.redAccent : task.priority == 'متوسطة' ? Colors.orange : primaryGreen;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(backgroundColor: const Color(0xFFEFF6F3), child: Icon(task.icon, color: primaryGreen)),
        title: Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen, decoration: task.isDone ? TextDecoration.lineThrough : null)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 4), Text('${task.date} • ${task.time}'), const SizedBox(height: 4), Text('أولوية ${task.priority}', style: TextStyle(color: priorityColor, fontSize: 12, fontWeight: FontWeight.w600))]),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'done') _toggleTask(task);
            if (value == 'edit') _openForm(task: task);
            if (value == 'delete') _deleteTask(task);
          },
          itemBuilder: (_) => [PopupMenuItem(value: 'done', child: Text(task.isDone ? 'إلغاء الإنجاز' : 'تحديد كمكتملة')), const PopupMenuItem(value: 'edit', child: Text('تعديل')), const PopupMenuItem(value: 'delete', child: Text('حذف'))],
        ),
      ),
    );
  }
}

class TaskFormDialog extends StatefulWidget {
  final DailyTask? task;
  const TaskFormDialog({super.key, this.task});
  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  String _priority = 'متوسطة';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _dateController = TextEditingController(text: widget.task?.date ?? 'اليوم');
    _timeController = TextEditingController(text: widget.task?.time ?? '');
    _priority = widget.task?.priority ?? 'متوسطة';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, DailyTask(id: widget.task?.id, title: _titleController.text.trim(), date: _dateController.text.trim(), time: _timeController.text.trim(), priority: _priority, icon: widget.task?.icon ?? Icons.task_alt, isDone: widget.task?.isDone ?? false));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(widget.task == null ? 'إضافة مهمة' : 'تعديل المهمة'),
        content: Form(key: _formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'اسم المهمة'), validator: _required), TextFormField(controller: _dateController, decoration: const InputDecoration(labelText: 'التاريخ'), validator: _required), TextFormField(controller: _timeController, decoration: const InputDecoration(labelText: 'الوقت'), validator: _required), DropdownButtonFormField<String>(initialValue: _priority, decoration: const InputDecoration(labelText: 'الأولوية'), items: const [DropdownMenuItem(value: 'عالية', child: Text('عالية')), DropdownMenuItem(value: 'متوسطة', child: Text('متوسطة')), DropdownMenuItem(value: 'منخفضة', child: Text('منخفضة'))], onChanged: (value) => setState(() => _priority = value ?? 'متوسطة'))]))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), FilledButton(onPressed: _save, child: const Text('حفظ'))],
      ),
    );
  }
}

class DailyTask {
  int? id;
  String title;
  String date;
  String time;
  String priority;
  IconData icon;
  bool isDone;
  DailyTask({this.id, required this.title, required this.date, required this.time, required this.priority, required this.icon, this.isDone = false});

  factory DailyTask.fromMap(Map<String, Object?> map) {
    return DailyTask(id: map['id'] as int?, title: map['title'] as String, date: map['date'] as String, time: map['time'] as String, priority: map['priority'] as String, icon: Icons.task_alt, isDone: (map['is_done'] as int? ?? 0) == 1);
  }

  Map<String, Object?> toMap() => {'title': title, 'date': date, 'time': time, 'priority': priority, 'is_done': isDone ? 1 : 0};
}
