 import 'package:flutter/material.dart';
import '../../../data/services/auth_service.dart';


class ForgotPasswordPage extends StatefulWidget {
const ForgotPasswordPage({super.key});

@override
State<ForgotPasswordPage> createState() =>
_ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
final _formKey = GlobalKey<FormState>();
final _emailController = TextEditingController();
final AuthService _authService = AuthService();

bool _isLoading = false;

@override
void dispose() {
_emailController.dispose();
super.dispose();
}

Future<void> _sendResetEmail() async {
if (!_formKey.currentState!.validate()) return;

setState(() {
_isLoading = true;
});

try {
await _authService.resetPassword(
email: _emailController.text.trim(),
);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Password reset email sent. Please check your inbox.',
),
backgroundColor: Colors.green,
),
);
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Failed to send reset email: $e'),
backgroundColor: Colors.red,
),
);
} finally {
if (mounted) {
setState(() {
_isLoading = false;
});
}
}
}

@override
Widget build(BuildContext context) {
const blue = Color(0xFF4B9FE1);

return Scaffold(
appBar: AppBar(
title: const Text('Forgot Password'),
backgroundColor: blue,
foregroundColor: Colors.white,
),
body: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
const Icon(
Icons.lock_reset,
size: 80,
color: blue,
),
const SizedBox(height: 24),
const Text(
'Reset Your Password',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 12),
const Text(
'Enter your email address and we will send '
'you a password reset link.',
textAlign: TextAlign.center,
),
const SizedBox(height: 28),
TextFormField(
controller: _emailController,
keyboardType: TextInputType.emailAddress,
decoration: const InputDecoration(
labelText: 'Email',
hintText: 'Enter your email address',
prefixIcon: Icon(Icons.email_outlined),
border: OutlineInputBorder(),
),
validator: (value) {
if (value == null || value.trim().isEmpty) {
return 'Please enter your email';
}

if (!value.trim().contains('@') ||
!value.trim().contains('.')) {
return 'Please enter a valid email';
}

return null;
},
),
const SizedBox(height: 24),
ElevatedButton(
onPressed:
_isLoading ? null : _sendResetEmail,
style: ElevatedButton.styleFrom(
backgroundColor: blue,
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(
vertical: 16,
),
),
child: _isLoading
? const SizedBox(
width: 22,
height: 22,
child: CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
)
    : const Text('Send Reset Link'),
),
],
),
),
),
),
);
}
}