
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
final _formKey = GlobalKey<FormState>();
final _nameController = TextEditingController();
final _phoneController = TextEditingController();

DateTime? _birthday;
bool _isSaving = false;

@override
void initState() {
super.initState();
_loadProfile();
}

Future<void> _loadProfile() async {
final user = FirebaseAuth.instance.currentUser;
if (user == null) return;

_nameController.text = user.displayName ?? '';

try {
final doc = await FirebaseFirestore.instance
.collection('users')
.doc(user.uid)
.get();

if (!mounted || !doc.exists) return;

final data = doc.data()!;
_phoneController.text = data['phoneNumber'] ?? '';

final birthday = data['birthday'];
if (birthday is Timestamp) {
setState(() => _birthday = birthday.toDate());
} else if (birthday is String && birthday.isNotEmpty) {
setState(() => _birthday = DateTime.tryParse(birthday));
}
} catch (e) {
debugPrint('Load profile error: $e');
}
}

Future<void> _pickBirthday() async {
final now = DateTime.now();

final selected = await showDatePicker(
context: context,
initialDate: _birthday ?? DateTime(now.year - 18, now.month, now.day),
firstDate: DateTime(1900),
lastDate: now,
helpText: 'Select Birthday',
);

if (selected != null && mounted) {
setState(() => _birthday = selected);
}
}

Future<void> _saveProfile() async {
if (!_formKey.currentState!.validate()) return;

setState(() => _isSaving = true);

try {
final user = FirebaseAuth.instance.currentUser;

if (user == null) {
throw Exception('Please login again.');
}

await user.updateDisplayName(_nameController.text.trim());

await FirebaseFirestore.instance
.collection('users')
.doc(user.uid)
.set({
'name': _nameController.text.trim(),
'email': user.email ?? '',
'phoneNumber': _phoneController.text.trim(),
'birthday': _birthday == null
? ''
: Timestamp.fromDate(_birthday!),
'updatedAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));

await user.reload();

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Profile updated successfully!'),
),
);

Navigator.pop(context, true);
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Failed to update profile: $e')),
);
} finally {
if (mounted) {
setState(() => _isSaving = false);
}
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
final birthdayText = _birthday == null
? 'Select your birthday'
: '${_birthday!.day.toString().padLeft(2, '0')}/'
'${_birthday!.month.toString().padLeft(2, '0')}/'
'${_birthday!.year}';

return Scaffold(
appBar: AppBar(title: const Text('Edit Profile')),
body: ListView(
padding: const EdgeInsets.all(20),
children: [
const SizedBox(height: 12),
const CircleAvatar(
radius: 42,
  child: Icon(Icons.person, size: 44),
),
  const SizedBox(height: 28),
  Form(
    key: _formKey,
    child: Column(
      children: [
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),
        InkWell(
          onTap: _pickBirthday,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Birthday Date',
              prefixIcon: Icon(Icons.calendar_month_outlined),
              border: OutlineInputBorder(),
            ),
            child: Text(birthdayText),
          ),
        ),
      ],
    ),
  ),
  const SizedBox(height: 24),
  SizedBox(
    height: 50,
    child: FilledButton(
      onPressed: _isSaving ? null : _saveProfile,
      child: _isSaving
          ? const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      )
          : const Text('Save Changes'),
    ),
  ),
],
),
);
}
}