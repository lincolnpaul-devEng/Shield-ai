import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fraud_provider.dart';
import 'dashboard_screen.dart';
import 'send_money_screen.dart';
import 'transactions_screen.dart';
import 'financial_planning_screen.dart';
import 'settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    SendMoneyScreen(),
    TransactionsScreen(),
    FinancialPlanningScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fraudProvider = context.watch<FraudProvider>();

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.send),
            label: 'Send Money',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Transactions',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Planning',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        onTap: _onItemTapped,
      ),

      // Floating fraud status indicator
      floatingActionButton: fraudProvider.lastResult != null
          ? FloatingActionButton(
              onPressed: () {
                // Show fraud status
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      fraudProvider.lastResult!.isFraud
                          ? '⚠️ Last transaction was flagged as suspicious'
                          : '✅ Last transaction was safe',
                    ),
                    backgroundColor: fraudProvider.lastResult!.isFraud
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              backgroundColor: fraudProvider.lastResult!.isFraud
                  ? Colors.red.shade600
                  : Colors.green.shade600,
              child: Icon(
                fraudProvider.lastResult!.isFraud
                    ? Icons.warning
                    : Icons.shield,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}