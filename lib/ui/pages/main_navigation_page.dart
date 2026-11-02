
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/wallet_cubit/wallet_cubit.dart';
import '../design_system/theme/theme_controller.dart';

import 'profile/profile_page.dart';
import 'transactions/transactions_page.dart';
import 'analytics/analytics_page.dart';
import 'home/home_page.dart';

class MainNavigationPage extends StatefulWidget {
  final ThemeController themeController;

  const MainNavigationPage({
    super.key,
    required this.themeController,
  });

  @override
  State<MainNavigationPage> createState() =>
      _MainNavigationPageState();
}

class _MainNavigationPageState
    extends State<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletCubit(),
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomePage(),
            AnalyticsPage(),
            TransactionsPage(),
            ProfilePage(
              themeController: widget.themeController,
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Transactions',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
