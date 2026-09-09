import 'package:flutter/material.dart';

import '../services/theme_controller.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const ProfileScreen({
    super.key,
    this.userName = 'المستخدم',
    this.userEmail = 'user@example.com',
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  bool _medicationNotifications = true;
  bool _taskNotifications = true;
  bool _soundEnabled = true;

  static const Color primaryGreen = Color(0xFF2E7D6E);
  static const Color darkGreen = Color(0xFF1F5E53);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _emailController = TextEditingController(text: widget.userEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _editProfile() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل الملف الشخصي'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'الاسم مطلوب'
                      : null,
                ),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                  const InputDecoration(labelText: 'البريد الإلكتروني'),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'البريد غير صحيح'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(dialogContext);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حفظ بيانات الملف الشخصي'),
                    backgroundColor: primaryGreen,
                  ),
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  void _openInfoPage(String title, String content) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => InformationScreen(title: title, content: content),
      ),
    );
  }

  static const String _aboutContent =
      'Memora هو تطبيق مساعد لمرضى الزهايمر ومقدمي الرعاية، يساعد على تنظيم الأدوية والمواعيد والمهام اليومية وحفظ جهات الاتصال المهمة. التطبيق أداة تنظيمية تعليمية ولا يُعد بديلًا عن الطبيب أو الرعاية الطبية المتخصصة.';

  static const String _privacyContent =
      'يحفظ التطبيق بيانات المشروع محليًا على الجهاز لأغراض تعليمية. يجب عدم إدخال معلومات طبية حساسة أو مشاركة كلمة المرور مع الآخرين. استخدم التطبيق كوسيلة مساعدة للتنظيم، واستشر مقدم الرعاية أو الطبيب عند الحاجة.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final cardColor = theme.cardColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('الملف الشخصي والإعدادات'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.primary,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Color(0xFFD8EEE7),
                      child: Icon(Icons.person, color: primaryGreen, size: 40),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _emailController.text,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit_outlined, color: primaryGreen),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'المظهر',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeController.mode,
                builder: (context, mode, _) {
                  final isDark = mode == ThemeMode.dark;
                  return SwitchListTile(
                    value: isDark,
                    onChanged: ThemeController.setDarkMode,
                    activeThumbColor: primaryGreen,
                    secondary: Icon(
                      isDark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: primaryGreen,
                    ),
                    title: const Text('الوضع الداكن'),
                    subtitle: Text(
                      isDark ? 'الوضع الداكن مفعّل' : 'الوضع العادي مفعّل',
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'التنبيهات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _medicationNotifications,
                    onChanged: (value) => setState(
                          () => _medicationNotifications = value,
                    ),
                    activeThumbColor: primaryGreen,
                    secondary: const Icon(
                      Icons.medication_outlined,
                      color: primaryGreen,
                    ),
                    title: const Text('تذكير الأدوية'),
                    subtitle: const Text('تنبيه قبل موعد الدواء'),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _taskNotifications,
                    onChanged: (value) => setState(
                          () => _taskNotifications = value,
                    ),
                    activeThumbColor: primaryGreen,
                    secondary: const Icon(
                      Icons.notifications_active_outlined,
                      color: primaryGreen,
                    ),
                    title: const Text('تذكير المهام والمواعيد'),
                    subtitle: const Text('لا تفوّت مواعيدك اليومية'),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _soundEnabled,
                    onChanged: (value) => setState(
                          () => _soundEnabled = value,
                    ),
                    activeThumbColor: primaryGreen,
                    secondary: const Icon(
                      Icons.volume_up_outlined,
                      color: primaryGreen,
                    ),
                    title: const Text('الأصوات'),
                    subtitle: const Text('تشغيل صوت التنبيهات'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'حول التطبيق',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  ListTile(
                    onTap: () => _openInfoPage(
                      'عن تطبيق Memora',
                      _aboutContent,
                    ),
                    leading: const Icon(Icons.info_outline, color: primaryGreen),
                    title: const Text('عن تطبيق Memora'),
                    trailing: const Icon(Icons.chevron_left),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    onTap: () => _openInfoPage(
                      'الخصوصية والأمان',
                      _privacyContent,
                    ),
                    leading: const Icon(
                      Icons.privacy_tip_outlined,
                      color: primaryGreen,
                    ),
                    title: const Text('الخصوصية والأمان'),
                    trailing: const Icon(Icons.chevron_left),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: Colors.redAccent),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'Memora • الإصدار 1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InformationScreen extends StatelessWidget {
  final String title;
  final String content;

  const InformationScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.primary,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 0,
            color: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
