import 'package:flutter/material.dart';
import 'package:my_wallet_app/ui/pages/profile/profile_page.dart';
import 'package:my_wallet_app/ui/pages/transactions/transactions_page.dart';
import '../../data/services/wallet_service.dart';

import '../design_system/theme/theme_controller.dart';
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

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final WalletService _walletService = WalletService();

  late final List<Widget> _pages = [
    HomePage(walletService: _walletService),
    AnalyticsPage(walletService: _walletService),
    TransactionsPage(walletService: _walletService),
    ProfilePage(
      themeController: widget.themeController,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
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
    );
  }
}

