import 'package:flutter/material.dart';

import 'medications_screen.dart';
import 'tasks_screen.dart';
import 'contacts_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<_DailyTask> _tasks = [
    _DailyTask(title: 'تناول دواء الصباح', time: '08:00 صباحًا', icon: Icons.medication_outlined),
    _DailyTask(title: 'موعد الطبيب', time: '11:30 صباحًا', icon: Icons.event_outlined),
    _DailyTask(title: 'شرب كوب من الماء', time: '01:00 ظهرًا', icon: Icons.water_drop_outlined),
    _DailyTask(title: 'المشي لمدة 15 دقيقة', time: '05:00 مساءً', icon: Icons.directions_walk_outlined),
  ];

  static const Color primaryGreen = Color(0xFF2E7D6E);
  static const Color darkGreen = Color(0xFF1F5E53);
  static const Color background = Color(0xFFF4FAF7);

  int get _completedTasks => _tasks.where((task) => task.isDone).length;

  void _toggleTask(int index, bool value) {
    setState(() => _tasks[index].isDone = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'تم إنجاز المهمة' : 'تمت إعادة المهمة إلى القائمة'),
        duration: const Duration(milliseconds: 1200),
        backgroundColor: primaryGreen,
      ),
    );
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('سيتم فتح شاشة $title في الخطوة التالية')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _completedTasks / _tasks.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Memora', style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              tooltip: 'الإشعارات',
              onPressed: () => _showComingSoon('الإشعارات'),
              icon: const Icon(Icons.notifications_none_rounded, color: darkGreen),
            ),
            IconButton(
              tooltip: 'الملف الشخصي',
              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ProfileScreen(userName: widget.userName))),
              icon: const Icon(Icons.account_circle_outlined, color: darkGreen),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text('صباح الخير، ${widget.userName}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: darkGreen)),
              const SizedBox(height: 6),
              const Text('لنحافظ على يوم هادئ ومنظم اليوم', style: TextStyle(fontSize: 15, color: Color(0xFF42645D))),
              const SizedBox(height: 20),
              _buildProgressCard(progress),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _buildStatCard(Icons.medication_outlined, 'الأدوية', '2 متبقية', const Color(0xFFE4F1ED))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(Icons.event_available_outlined, 'المواعيد', 'موعد واحد', const Color(0xFFE9F0F8))),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('مهام اليوم', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGreen)),
                  Text('$_completedTasks/${_tasks.length} مكتملة', style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              ...List.generate(_tasks.length, (index) => _buildTaskCard(index)),
              const SizedBox(height: 18),
              const Text('الوصول السريع', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGreen)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildQuickAction(Icons.medication_rounded, 'الأدوية', () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const MedicationsScreen())))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildQuickAction(Icons.calendar_month_rounded, 'المواعيد', () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const TasksScreen())))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildQuickAction(Icons.family_restroom_rounded, 'العائلة', () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ContactsScreen())))),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFD8EEE7),
          onDestinationSelected: (index) {
            if (index == 1) Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const TasksScreen()));
            if (index == 2) Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ProfileScreen(userName: widget.userName)));
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'المهام'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'الإعدادات'),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(double progress) {
    return Card(
      elevation: 0,
      color: primaryGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 74,
              height: 74,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(value: progress, strokeWidth: 7, backgroundColor: Colors.white24, color: Colors.white),
                  Text('${(progress * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 18),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ملخص اليوم', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('أحسنت! استمر في متابعة مهامك اليومية.', style: TextStyle(color: Colors.white70, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, Color color) {
    return Card(
      elevation: 0,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: primaryGreen, size: 30),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: darkGreen, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(color: Color(0xFF42645D), fontSize: 13)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(int index) {
    final task = _tasks[index];
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: task.isDone ? const Color(0xFFD8EEE7) : const Color(0xFFEFF6F3),
          child: Icon(task.icon, color: primaryGreen),
        ),
        title: Text(task.title, style: TextStyle(fontWeight: FontWeight.w600, decoration: task.isDone ? TextDecoration.lineThrough : null)),
        subtitle: Text(task.time),
        trailing: Checkbox(value: task.isDone, activeColor: primaryGreen, onChanged: (value) => _toggleTask(index, value ?? false)),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(children: [Icon(icon, color: primaryGreen, size: 30), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 13, color: darkGreen, fontWeight: FontWeight.w600))]),
        ),
      ),
    );
  }
}

class _DailyTask {
  final String title;
  final String time;
  final IconData icon;
  bool isDone;

  _DailyTask({required this.title, required this.time, required this.icon}) : isDone = false;
}
