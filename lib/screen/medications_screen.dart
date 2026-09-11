import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final List<Medication> _medications = [];
  final DatabaseHelper _database = DatabaseHelper.instance;
  bool _isLoading = true;

  static const Color primaryGreen = Color(0xFF2E7D6E);

  int get _takenCount => _medications.where((medication) => medication.isTaken).length;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    try {
      final rows = await _database.getMedications();
      if (!mounted) return;
      setState(() {
        _medications
          ..clear()
          ..addAll(rows.map(Medication.fromMap));
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحميل الأدوية')),
      );
    }
  }

  Future<void> _openMedicationForm({Medication? medication}) async {
    final result = await showDialog<Medication>(
      context: context,
      builder: (_) => MedicationFormDialog(medication: medication),
    );

    if (!mounted || result == null) return;

    try {
      if (medication == null) {
        final id = await _database.insertMedication(result.toMap());
        result.id = id;
        setState(() => _medications.add(result));
      } else {
        await _database.updateMedication(medication.id!, result.toMap());
        setState(() => _medications[_medications.indexOf(medication)] = result);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ الدواء')),
        );
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          medication == null
              ? 'تمت إضافة الدواء بنجاح'
              : 'تم تعديل الدواء بنجاح',
        ),
        backgroundColor: primaryGreen,
      ),
    );
  }

  Future<void> _deleteMedication(Medication medication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف دواء «${medication.name}»؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await _database.deleteMedication(medication.id!);
      setState(() => _medications.remove(medication));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الدواء')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حذف الدواء')),
      );
    }
  }

  Future<void> _toggleTaken(Medication medication, bool value) async {
    try {
      await _database.updateMedication(
        medication.id!,
        {'is_taken': value ? 1 : 0},
      );
      setState(() => medication.isTaken = value);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحديث حالة الدواء')),
        );
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'تم تسجيل تناول الدواء' : 'تمت إعادة الدواء إلى القائمة',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('الأدوية والتذكيرات'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: scheme.primary,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _buildSummaryCard(),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'قائمة الأدوية',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    '${_medications.length} أدوية',
                    style: const TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_medications.isEmpty) _buildEmptyState(),
              ..._medications.map(_buildMedicationCard),
            ],
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openMedicationForm(),
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('إضافة دواء'),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 0,
      color: primaryGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white24,
              child: Icon(
                Icons.medication_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'متابعة أدوية اليوم',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'تم تناول $_takenCount من ${_medications.length}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            CircularProgressIndicator(
              value: _medications.isEmpty ? 0 : _takenCount / _medications.length,
              color: Colors.white,
              backgroundColor: Colors.white24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: medication.isTaken
                  ? scheme.secondaryContainer
                  : scheme.surfaceContainerHighest,
              child: Icon(medication.icon, color: primaryGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                      decoration: medication.isTaken
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${medication.dose} • ${medication.time}',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    medication.isTaken
                        ? 'تم التناول'
                        : 'لم يتم التناول بعد',
                    style: TextStyle(
                      color: medication.isTaken
                          ? primaryGreen
                          : Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: medication.isTaken,
                  activeThumbColor: primaryGreen,
                  onChanged: (value) => _toggleTaken(medication, value),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: primaryGreen,
                      onPressed: () =>
                          _openMedicationForm(medication: medication),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.redAccent,
                      onPressed: () => _deleteMedication(medication),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(
              Icons.medication_outlined,
              size: 54,
              color: primaryGreen,
            ),
            const SizedBox(height: 12),
            const Text('لا توجد أدوية مضافة بعد'),
            const SizedBox(height: 6),
            Text(
              'اضغط على إضافة دواء للبدء',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class MedicationFormDialog extends StatefulWidget {
  final Medication? medication;

  const MedicationFormDialog({super.key, this.medication});

  @override
  State<MedicationFormDialog> createState() => _MedicationFormDialogState();
}

class _MedicationFormDialogState extends State<MedicationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _doseController;
  late final TextEditingController _timeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication?.name ?? '');
    _doseController = TextEditingController(text: widget.medication?.dose ?? '');
    _timeController = TextEditingController(text: widget.medication?.time ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Medication(
        id: widget.medication?.id,
        name: _nameController.text.trim(),
        dose: _doseController.text.trim(),
        time: _timeController.text.trim(),
        icon: widget.medication?.icon ?? Icons.medication_rounded,
        isTaken: widget.medication?.isTaken ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(widget.medication == null ? 'إضافة دواء' : 'تعديل الدواء'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الدواء',
                    prefixIcon: Icon(Icons.medication_outlined),
                  ),
                  validator: _required,
                ),
                TextFormField(
                  controller: _doseController,
                  decoration: const InputDecoration(
                    labelText: 'الجرعة',
                    prefixIcon: Icon(Icons.format_list_numbered),
                  ),
                  validator: _required,
                ),
                TextFormField(
                  controller: _timeController,
                  decoration: const InputDecoration(
                    labelText: 'وقت التناول',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  validator: _required,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(onPressed: _save, child: const Text('حفظ')),
        ],
      ),
    );
  }
}

class Medication {
  int? id;
  String name;
  String dose;
  String time;
  IconData icon;
  bool isTaken;

  Medication({
    this.id,
    required this.name,
    required this.dose,
    required this.time,
    required this.icon,
    this.isTaken = false,
  });

  factory Medication.fromMap(Map<String, Object?> map) {
    return Medication(
      id: map['id'] as int?,
      name: map['name'] as String,
      dose: map['dose'] as String,
      time: map['time'] as String,
      icon: Icons.medication_rounded,
      isTaken: (map['is_taken'] as int? ?? 0) == 1,
    );
  }

  Map<String, Object?> toMap() => {
    'name': name,
    'dose': dose,
    'time': time,
    'is_taken': isTaken ? 1 : 0,
  };
}
