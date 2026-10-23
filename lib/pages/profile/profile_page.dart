import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_profile_page.dart';
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
Future<void> _editProfile() async {
final updated = await Navigator.push<bool>(
context,
MaterialPageRoute(
builder: (context) => const EditProfilePage(),
),
);

if (!mounted) return;

if (updated == true) {
await FirebaseAuth.instance.currentUser?.reload();

if (!mounted) return;
setState(() {});
}
}

Future<void> _logout() async {
final shouldLogout = await showDialog<bool>(
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

if (shouldLogout != true) return;

try {
await FirebaseAuth.instance.signOut();
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Logout failed: $e')),
);
}
}

@override
Widget build(BuildContext context) {
final user = FirebaseAuth.instance.currentUser;
final isDark = widget.themeController.isDarkMode;
final colors = Theme.of(context).colorScheme;

return Scaffold(
appBar: AppBar(
title: const Text('Profile'),
),
body: ListView(
padding: const EdgeInsets.all(20),
children: [
const SizedBox(height: 20),
CircleAvatar(
radius: 45,
backgroundColor: colors.primaryContainer,
child: Icon(
Icons.person_rounded,
size: 48,
color: colors.primary,
),
),
const SizedBox(height: 16),
Text(
user?.displayName?.isNotEmpty == true
? user!.displayName!
    : 'MyWallet User',
textAlign: TextAlign.center,
style: Theme.of(context)
    .textTheme
    .titleLarge
    ?.copyWith(fontWeight: FontWeight.bold),
),
const SizedBox(height: 6),
Text(
user?.email ?? 'No email available',
textAlign: TextAlign.center,
style: Theme.of(context)
    .textTheme
    .bodyMedium
    ?.copyWith(color: colors.onSurfaceVariant),
),
const SizedBox(height: 32),
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
leading: const Icon(Icons.edit_outlined),
 title: const Text('Edit Profile'),
subtitle: const Text('Update your name'),
trailing: const Icon(Icons.chevron_right),
onTap: _editProfile,
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