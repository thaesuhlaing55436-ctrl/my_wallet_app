import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  runApp(
    BlocProvider(
      create: (_) => ThemeController(),
      child: const MyWalletApp(),
    ),
  );
}

class MyWalletApp extends StatelessWidget {
  const MyWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeController, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          title: 'MyWallet',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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
            themeController: context.read<ThemeController>(),
          );
        }

        return const LoginPage();
      },
    );
  }
}