
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
const LoginPage({super.key});

@override
State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
final _formKey = GlobalKey<FormState>();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();

final AuthService _authService = AuthService();

bool _isLoading = false;
bool _hidePassword = true;

@override
void dispose() {
_emailController.dispose();
_passwordController.dispose();
super.dispose();
}

Future<void> _login() async {
if (!_formKey.currentState!.validate()) return;

setState(() => _isLoading = true);

try {
await _authService.login(
email: _emailController.text.trim(),
password: _passwordController.text,
);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Login successful!'),
),
);
} on Exception catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Login failed: $e'),
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
size: 82,
color: blue,
),
const SizedBox(height: 20),
const Text(
'Welcome to MyWallet',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 8),
Text(
'Manage your money with confidence.',
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.grey.shade600,
fontSize: 15,
),
),
const SizedBox(height: 36),

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
const SizedBox(height: 18),

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
if (value == null || value.isEmpty) {
return 'Please enter your password';
}

return null;
},
),

const SizedBox(height: 24),

SizedBox(
height: 52,
child: FilledButton(
onPressed: _isLoading ? null : _login,
style: FilledButton.styleFrom(
backgroundColor: blue,
),
child: _isLoading
? const SizedBox(
height: 22,
width: 22,
child: CircularProgressIndicator(
color: Colors.white,
strokeWidth: 2,
),
)
    : const Text(
'Login',
style: TextStyle(fontSize: 16),
),
),
),
const SizedBox(height: 20),

Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Flexible(
child: Text("Don't have an account?"),
),
TextButton(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const RegisterPage(),
),
);
},
child: const Text('Register'),
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