 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/theme_controller.dart';

class ProfilePage extends StatefulWidget {
final ThemeController themeController;

const ProfilePage({
super.key,
required this.themeController,
});

@override
State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
final TextEditingController _nameController =
TextEditingController();

final TextEditingController _phoneController =
TextEditingController();

DateTime? _birthday;
bool _loading = true;
bool _saving = false;

@override
void initState() {
super.initState();
_loadProfile();
}

Future<void> _loadProfile() async {
try {
final user = FirebaseAuth.instance.currentUser;

if (user == null) return;

_nameController.text = user.displayName ?? '';

final doc = await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .get()
    .timeout(const Duration(seconds: 10));

final data = doc.data();

if (data != null) {
_nameController.text =
(data['name'] as String?) ??
user.displayName ??
'';

_phoneController.text =
data['phoneNumber']?.toString() ?? '';

final birthday = data['birthday'];

if (birthday is Timestamp) {
_birthday = birthday.toDate();
} else if (birthday is String &&
birthday.isNotEmpty) {
_birthday = DateTime.tryParse(birthday);
}
}
} catch (e) {
debugPrint('Profile load error: $e');
} finally {
if (mounted) {
setState(() => _loading = false);
}
}
}

Future<void> _pickBirthday() async {
final now = DateTime.now();

final selected = await showDatePicker(
context: context,
initialDate: _birthday ?? DateTime(2000, 1, 1),
firstDate: DateTime(1900),
lastDate: now,
helpText: 'Select Birthday',
);

if (selected != null && mounted) {
setState(() => _birthday = selected);
}
}

Future<void> _saveProfile() async {
final user = FirebaseAuth.instance.currentUser;

if (user == null) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Please login again.'),
),
);
return;
}

final name = _nameController.text.trim();

if (name.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Please enter your full name.'),
),
);
return;
}

setState(() => _saving = true);

try {
await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .set(
{
'name': name,
'email': user.email ?? '',
'phoneNumber': _phoneController.text.trim(),
'birthday': _birthday == null
? ''
    : Timestamp.fromDate(_birthday!),
'updatedAt': FieldValue.serverTimestamp(),
},
SetOptions(merge: true),
).timeout(const Duration(seconds: 15));

await user.updateDisplayName(name);

if (!mounted) return;

FocusScope.of(context).unfocus();

setState(() {});

ScaffoldMessenger.of(context).showSnackBar(
 const SnackBar(
  content: Text('Profile saved successfully!'),
 ),
);
} catch (e) {
debugPrint('Save profile error: $e');

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Save failed: $e'),
duration: const Duration(seconds: 6),
),
);
} finally {
if (mounted) {
setState(() => _saving = false);
}
}
}
 Future<void> _logout() async {
final confirm = await showDialog<bool>(
context: context,
builder: (dialogContext) => AlertDialog(
title: const Text('Logout'),
content: const Text(
'Are you sure you want to logout?',
),
actions: [
TextButton(
onPressed: () =>
Navigator.pop(dialogContext, false),
child: const Text('Cancel'),
),
FilledButton(
onPressed: () =>
Navigator.pop(dialogContext, true),
child: const Text('Logout'),
),
],
),
);

if (confirm != true) return;

try {
await FirebaseAuth.instance.signOut();
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Logout failed: $e'),
),
);
}
}

@override
void dispose() {
_nameController.dispose();
_phoneController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final user = FirebaseAuth.instance.currentUser;
final isDark = widget.themeController.isDarkMode;
final colors = Theme.of(context).colorScheme;

final birthdayText = _birthday == null
? 'Choose your birthday'
    : '${_birthday!.day.toString().padLeft(2, '0')}/'
'${_birthday!.month.toString().padLeft(2, '0')}/'
'${_birthday!.year}';

if (_loading) {
return Scaffold(
appBar: AppBar(
title: const Text('Profile'),
),
body: const Center(
child: CircularProgressIndicator(),
),
);
}

return Scaffold(
appBar: AppBar(
title: const Text('Profile'),
),
body: ListView(
padding: const EdgeInsets.all(20),
children: [
const SizedBox(height: 12),

CircleAvatar(
radius: 45,
backgroundColor: colors.primaryContainer,
child: Icon(
Icons.person_rounded,
size: 48,
color: colors.primary,
),
),

const SizedBox(height: 12),

Text(
_nameController.text.isNotEmpty
? _nameController.text
    : 'MyWallet User',
textAlign: TextAlign.center,
style: Theme.of(context)
    .textTheme
    .titleLarge
    ?.copyWith(
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 4),

Text(
user?.email ?? 'No email available',
textAlign: TextAlign.center,
style: TextStyle(
color: colors.onSurfaceVariant,
),
),

const SizedBox(height: 28),

Text(
'Personal Information',
style: Theme.of(context).textTheme.titleMedium,
),

const SizedBox(height: 12),

TextField(
controller: _nameController,
textCapitalization: TextCapitalization.words,
decoration: const InputDecoration(
labelText: 'Full Name',
prefixIcon: Icon(Icons.person_outline),
border: OutlineInputBorder(),
),
),

const SizedBox(height: 16),

TextField(
controller: _phoneController,
keyboardType: TextInputType.phone,
decoration: const InputDecoration(
labelText: 'Phone Number',
prefixIcon: Icon(Icons.phone_outlined),
border: OutlineInputBorder(),
),
),

const SizedBox(height: 16),

InkWell(
onTap: _pickBirthday,
 child: InputDecorator(
decoration: const InputDecoration(
labelText: 'Birthday Date',
prefixIcon: Icon(
Icons.calendar_month_outlined,
),
border: OutlineInputBorder(),
),
child: Text(birthdayText),
),
),

const SizedBox(height: 20),

SizedBox(
height: 50,
child: FilledButton(
onPressed: _saving ? null : _saveProfile,
child: _saving
? const SizedBox(
height: 22,
width: 22,
child: CircularProgressIndicator(
strokeWidth: 2,
),
)
    : const Text('Save Profile'),
),
),

const SizedBox(height: 24),

Card(
child: SwitchListTile(
secondary: Icon(
isDark
? Icons.dark_mode_rounded
    : Icons.light_mode_rounded,
),
title: const Text('Dark Mode'),
subtitle: Text(
isDark
? 'Dark theme enabled'
    : 'Light theme enabled',
),
value: isDark,
onChanged: widget.themeController.toggleTheme,
),
),

const SizedBox(height: 12),

Card(
child: ListTile(
leading: const Icon(
Icons.logout_rounded,
color: Colors.red,
),
title: const Text('Logout'),
onTap: _logout,
),
),
],
),
);
}
}