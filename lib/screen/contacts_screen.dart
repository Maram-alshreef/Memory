import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class ContactsScreen extends StatefulWidget {
const ContactsScreen({super.key});

@override
State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
final List<CareContact> _contacts = [];
final DatabaseHelper _database = DatabaseHelper.instance;
bool _isLoading = true;

@override
void initState() {
super.initState();
_loadContacts();
}

Future<void> _loadContacts() async {
try {
final rows = await _database.getContacts();

if (!mounted) return;

setState(() {
_contacts
..clear()
..addAll(rows.map(CareContact.fromMap));
_isLoading = false;
});
} catch (_) {
if (!mounted) return;

setState(() => _isLoading = false);

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('تعذر تحميل جهات الاتصال'),
),
);
}
}

Future<void> _openForm({CareContact? contact}) async {
final result = await showDialog<CareContact>(
context: context,
builder: (_) => ContactFormDialog(contact: contact),
);

if (!mounted || result == null) return;

try {
if (contact == null) {
final id = await _database.insertContact(result.toMap());
result.id = id;

setState(() => _contacts.add(result));
} else {
await _database.updateContact(
contact.id!,
result.toMap(),
);

result.id = contact.id;

setState(() {
_contacts[_contacts.indexOf(contact)] = result;
});
}
} catch (_) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('تعذر حفظ جهة الاتصال'),
),
);
}

return;
}

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
contact == null
? 'تمت إضافة جهة الاتصال'
    : 'تم تعديل جهة الاتصال',
),
),
);
}

Future<void> _deleteContact(CareContact contact) async {
final confirmed = await showDialog<bool>(
context: context,
builder: (dialogContext) => AlertDialog(
title: const Text('تأكيد الحذف'),
content: Text(
'هل تريد حذف «${contact.name}» من جهات الاتصال؟',
),
actions: [
TextButton(
onPressed: () => Navigator.pop(dialogContext, false),
child: const Text('إلغاء'),
),
FilledButton(
onPressed: () => Navigator.pop(dialogContext, true),
child: const Text('حذف'),
),
],
),
);

if (confirmed != true || !mounted) return;

try {
await _database.deleteContact(contact.id!);

setState(() => _contacts.remove(contact));

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('تم حذف جهة الاتصال'),
),
);
} catch (_) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('تعذر حذف جهة الاتصال'),
),
);
}
}

void _showContactAction(
String action,
CareContact contact,
) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'$action: ${contact.name} — ${contact.phone}',
),
),
);
}

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;

final primaryGreen = colorScheme.primary;
final titleColor = colorScheme.onSurface;

return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
backgroundColor: theme.scaffoldBackgroundColor,

appBar: AppBar(
title: const Text('العائلة ومقدم الرعاية'),
centerTitle: true,
backgroundColor: Colors.transparent,
foregroundColor: titleColor,
elevation: 0,
),

body: ListView(
padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
children: [
if (_isLoading)
const Padding(
padding: EdgeInsets.all(30),
child: Center(
child: CircularProgressIndicator(),
),
)
else ...[
Card(
elevation: 0,
color: primaryGreen,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(22),
),
child: Padding(
padding: const EdgeInsets.all(20),
child: Row(
children: [
CircleAvatar(
radius: 30,
backgroundColor: colorScheme.onPrimary.withOpacity(0.15),
child: Icon(
Icons.family_restroom_rounded,
color: colorScheme.onPrimary,
size: 32,
),
),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'دائرة الدعم',
style: TextStyle(
color: colorScheme.onPrimary,
fontSize: 19,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 5),
Text(
'أشخاص موثوقون يمكنهم مساعدتك عند الحاجة',
style: TextStyle(
color: colorScheme.onPrimary.withOpacity(0.7),
height: 1.4,
),
),
],
),
),
],
),
),
),

const SizedBox(height: 22),

Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
'جهات الاتصال',
style: TextStyle(
fontSize: 21,
fontWeight: FontWeight.bold,
color: titleColor,
),
),
Text(
'${_contacts.length} أشخاص',
style: TextStyle(
color: primaryGreen,
fontWeight: FontWeight.w600,
),
),
],
),

const SizedBox(height: 12),

..._contacts.map(_buildContactCard),
],
],
),

floatingActionButton: FloatingActionButton.extended(
onPressed: () => _openForm(),
backgroundColor: primaryGreen,
foregroundColor: colorScheme.onPrimary,
icon: const Icon(Icons.person_add_alt_1),
label: const Text('إضافة شخص'),
),
),
);
}

Widget _buildContactCard(CareContact contact) {
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;

final primaryGreen = colorScheme.primary;
final titleColor = colorScheme.onSurface;
final secondaryTextColor = colorScheme.onSurfaceVariant;

return Card(
elevation: 0,
margin: const EdgeInsets.only(bottom: 12),

// يتغير تلقائيًا مع Light / Dark Theme
color: theme.cardColor,

shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(18),
),

child: Padding(
padding: const EdgeInsets.all(14),
child: Column(
children: [
Row(
children: [
CircleAvatar(
radius: 27,

// لون خفيف مشتق من اللون الأساسي بدل اللون الثابت
backgroundColor: primaryGreen.withOpacity(0.15),

child: Text(
contact.name.characters.first,
style: TextStyle(
color: primaryGreen,
fontSize: 20,
fontWeight: FontWeight.bold,
),
),
),

const SizedBox(width: 12),

Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Flexible(
child: Text(
contact.name,
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
color: titleColor,
),
),
),

if (contact.isPrimary) ...[
const SizedBox(width: 8),

Chip(
label: Text(
'أساسي',
style: TextStyle(
fontSize: 11,
color: colorScheme.onSurface,
),
),
backgroundColor:
colorScheme.primary.withOpacity(0.12),
visualDensity: VisualDensity.compact,
),
],
],
),

const SizedBox(height: 5),

Text(
contact.relation,
style: TextStyle(
color: secondaryTextColor,
),
),

Text(
contact.phone,
style: TextStyle(
color: colorScheme.onSurfaceVariant,
fontSize: 13,
),
),
],
),
),

PopupMenuButton<String>(
onSelected: (value) {
if (value == 'edit') {
_openForm(contact: contact);
}

if (value == 'delete') {
_deleteContact(contact);
}
},
itemBuilder: (_) => const [
PopupMenuItem(
value: 'edit',
child: Text('تعديل'),
),
PopupMenuItem(
value: 'delete',
child: Text('حذف'),
),
],
),
],
),

const Divider(height: 22),

Row(
children: [
Expanded(
child: OutlinedButton.icon(
onPressed: () => _showContactAction(
'الاتصال',
contact,
),
icon: const Icon(
Icons.phone_outlined,
size: 19,
),
label: const Text('اتصال'),
style: OutlinedButton.styleFrom(
foregroundColor: primaryGreen,
),
),
),

const SizedBox(width: 10),

Expanded(
child: OutlinedButton.icon(
onPressed: () => _showContactAction(
'رسالة',
contact,
),
icon: const Icon(
Icons.message_outlined,
size: 19,
),
label: const Text('رسالة'),
style: OutlinedButton.styleFrom(
foregroundColor: primaryGreen,
),
),
),
],
),
],
),
),
);
}
}

class ContactFormDialog extends StatefulWidget {
final CareContact? contact;

const ContactFormDialog({
super.key,
this.contact,
});

@override
State<ContactFormDialog> createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends State<ContactFormDialog> {
final _formKey = GlobalKey<FormState>();

late final TextEditingController _nameController;
late final TextEditingController _relationController;
late final TextEditingController _phoneController;

bool _isPrimary = false;

@override
void initState() {
super.initState();

_nameController = TextEditingController(
text: widget.contact?.name ?? '',
);

_relationController = TextEditingController(
text: widget.contact?.relation ?? '',
);

_phoneController = TextEditingController(
text: widget.contact?.phone ?? '',
);

_isPrimary = widget.contact?.isPrimary ?? false;
}

@override
void dispose() {
_nameController.dispose();
_relationController.dispose();
_phoneController.dispose();

super.dispose();
}

String? _required(String? value) {
return value == null || value.trim().isEmpty
? 'هذا الحقل مطلوب'
    : null;
}

String? _phoneValidator(String? value) {
if (value == null || value.trim().isEmpty) {
return 'يرجى إدخال رقم الهاتف';
}

if (value.trim().length < 7) {
return 'رقم الهاتف غير صحيح';
}

return null;
}

void _save() {
if (!_formKey.currentState!.validate()) return;

Navigator.pop(
context,
CareContact(
id: widget.contact?.id,
name: _nameController.text.trim(),
relation: _relationController.text.trim(),
phone: _phoneController.text.trim(),
isPrimary: _isPrimary,
),
);
}

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: AlertDialog(
title: Text(
widget.contact == null
? 'إضافة جهة اتصال'
    : 'تعديل جهة الاتصال',
),

content: Form(
key: _formKey,
child: SingleChildScrollView(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
TextFormField(
controller: _nameController,
decoration: const InputDecoration(
labelText: 'الاسم',
prefixIcon: Icon(Icons.person_outline),
),
validator: _required,
),

TextFormField(
controller: _relationController,
decoration: const InputDecoration(
labelText: 'صلة القرابة أو الدور',
prefixIcon: Icon(Icons.people_outline),
),
validator: _required,
),

TextFormField(
controller: _phoneController,
keyboardType: TextInputType.phone,
decoration: const InputDecoration(
labelText: 'رقم الهاتف',
prefixIcon: Icon(Icons.phone_outlined),
),
validator: _phoneValidator,
),

CheckboxListTile(
value: _isPrimary,
onChanged: (value) {
setState(() {
_isPrimary = value ?? false;
});
},
contentPadding: EdgeInsets.zero,
title: const Text('جهة اتصال أساسية'),
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

FilledButton(
onPressed: _save,
child: const Text('حفظ'),
),
],
),
);
}
}

class CareContact {
int? id;
String name;
String relation;
String phone;
bool isPrimary;

CareContact({
this.id,
required this.name,
required this.relation,
required this.phone,
this.isPrimary = false,
});

factory CareContact.fromMap(Map<String, Object?> map) {
return CareContact(
id: map['id'] as int?,
name: map['name'] as String,
relation: map['relation'] as String,
phone: map['phone'] as String,
isPrimary: (map['is_primary'] as int? ?? 0) == 1,
);
}

Map<String, Object?> toMap() => {
'name': name,
'relation': relation,
'phone': phone,
'is_primary': isPrimary ? 1 : 0,
};
}
