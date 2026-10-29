import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_wallet_app/ui/design_system/theme/app_theme.dart';
import 'package:my_wallet_app/ui/design_system/theme/theme_controller.dart';
import 'package:my_wallet_app/ui/pages/auth/login_page.dart';
import 'package:my_wallet_app/ui/pages/main_navigation_page.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyWalletApp());
}

class MyWalletApp extends StatefulWidget {
  const MyWalletApp({super.key});

  @override
  State<MyWalletApp> createState() => _MyWalletAppState();
}

class _MyWalletAppState extends State<MyWalletApp> {
  final ThemeController _themeController = ThemeController();

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, child) {
        return MaterialApp(
          title: 'MyWallet',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeController.themeMode,
          home: AuthGate(
            themeController: _themeController,
          ),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  final ThemeController themeController;

  const AuthGate({
    super.key,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return MainNavigationPage(
            themeController: themeController,
          );
        }

        return const LoginPage();
      },
    );
  }
}