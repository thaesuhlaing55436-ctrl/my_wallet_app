 import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'login_page.dart';


class RegisterPage extends StatefulWidget {
const RegisterPage({super.key});

@override
State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
final _formKey = GlobalKey<FormState>();
final _nameController = TextEditingController();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();
final _confirmPasswordController = TextEditingController();

final AuthService _authService = AuthService();

bool _isLoading = false;
bool _hidePassword = true;
bool _hideConfirmPassword = true;

@override
void dispose() {
_nameController.dispose();
_emailController.dispose();
_passwordController.dispose();
_confirmPasswordController.dispose();
super.dispose();
}

Future<void> _register() async {
if (!_formKey.currentState!.validate()) return;

setState(() => _isLoading = true);

try {
  final credential = await _authService.register(
    email: _emailController.text.trim(),
    password: _passwordController.text,
    fullName: _nameController.text.trim(),
  );

  debugPrint(
    'REGISTER UID: ${credential.user?.uid}',
  );
  debugPrint(
    'CURRENT UID: ${FirebaseAuth.instance.currentUser?.uid}',
  );
  debugPrint('AUTH STATE: ${FirebaseAuth.instance.currentUser}');
  debugPrint(
    'REGISTER UID: ${credential.user?.uid}',
  );

  debugPrint(
    'CURRENT UID: ${FirebaseAuth.instance.currentUser?.uid}',
  );

  if (!mounted) return;

  // Firebase AuthGate က Home ကို အလိုအလျောက် ပြောင်းပေးပါမယ်။


} on Exception catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Registration failed: $e'),
),
);
} finally {
if (mounted) {
setState(() => _isLoading = false);
}
}
}

@override
Widget build(BuildContext context) {
const blue = Color(0xFF4B9FE1);

return Scaffold(
appBar: AppBar(
title: const Text('Create Account'),
),
body: SafeArea(
child: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
const Icon(
Icons.account_balance_wallet_rounded,
size: 76,
color: blue,
),
const SizedBox(height: 16),
const Text(
'Join MyWallet',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 8),
const Text(
'Create an account to manage your money.',
textAlign: TextAlign.center,
),
const SizedBox(height: 28),

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
const SizedBox(height: 16),

TextFormField(
controller: _emailController,
 keyboardType: TextInputType.emailAddress,
decoration: const InputDecoration(
labelText: 'Email',
prefixIcon: Icon(Icons.email_outlined),
border: OutlineInputBorder(),
),
validator: (value) {
final email = value?.trim() ?? '';
if (!RegExp(
r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
).hasMatch(email)) {
return 'Enter a valid email address';
}
return null;
},
),
const SizedBox(height: 16),

TextFormField(
controller: _passwordController,
obscureText: _hidePassword,
decoration: InputDecoration(
labelText: 'Password',
prefixIcon: const Icon(Icons.lock_outline),
border: const OutlineInputBorder(),
suffixIcon: IconButton(
onPressed: () {
setState(() {
_hidePassword = !_hidePassword;
});
},
icon: Icon(
_hidePassword
? Icons.visibility_outlined
    : Icons.visibility_off_outlined,
),
),
),
validator: (value) {
if ((value ?? '').length < 6) {
return 'Password must be at least 6 characters';
}
return null;
},
),
const SizedBox(height: 16),

TextFormField(
controller: _confirmPasswordController,
obscureText: _hideConfirmPassword,
decoration: InputDecoration(
labelText: 'Confirm Password',
prefixIcon: const Icon(Icons.lock_reset),
border: const OutlineInputBorder(),
suffixIcon: IconButton(
onPressed: () {
setState(() {
_hideConfirmPassword =
!_hideConfirmPassword;
});
},
icon: Icon(
_hideConfirmPassword
? Icons.visibility_outlined
    : Icons.visibility_off_outlined,
),
),
),
validator: (value) {
if (value != _passwordController.text) {
return 'Passwords do not match';
}
return null;
},
),
const SizedBox(height: 24),

SizedBox(
height: 52,
child: FilledButton(
onPressed: _isLoading ? null : _register,
style: FilledButton.styleFrom(
backgroundColor: blue,
),
child: _isLoading
? const SizedBox(
height: 22,
width: 22,
child: CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
 ),
)
    : const Text(
'Create Account',
style: TextStyle(fontSize: 16),
),
),
),
const SizedBox(height: 16),

Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Text('Already have an account?'),
TextButton(
onPressed: () {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) => const LoginPage(),
),
);
},
child: const Text('Login'),
),
],
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