import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../providers/fraud_provider.dart';
import '../providers/financial_provider.dart';
import '../providers/sms_provider.dart';
import '../models/transaction.dart';
import '../models/spending_plan.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/responsive_container.dart';
import 'main_navigation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  bool _syncingBalance = false;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    // Delay loading to allow UI to build initially
    await Future.delayed(const Duration(milliseconds: 300));
    
    final user = context.read<UserProvider>().currentUser;
    if (user != null) {
      final txProvider = context.read<TransactionProvider>();
      await txProvider.loadTransactions(user.phone);
    }
    
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final txProvider = context.watch<TransactionProvider>();
    final fraudProvider = context.watch<FraudProvider>();
    final financialProvider = context.watch<FinancialProvider>();
    final smsProvider = context.watch<SmsProvider>();

    final transactions = txProvider.transactions;
    final hasTransactions = transactions.isNotEmpty;
    final spendingPlan = financialProvider.currentPlan;

    final balance = _calculateBalance(transactions, smsProvider.latestBalance);
    final weeklySpending = _calculateWeeklySpending(transactions);
    final monthlySpending = _calculateMonthlySpending(transactions);

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _syncingBalance ? null : _syncBalance,
            icon: _syncingBalance
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Sync M-Pesa Balance',
          ),
          _FraudStatusBadge(isActive: fraudProvider.lastResult?.isFraud == false),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              ResponsiveContainer(
                child: _HeaderGreeting(name: user?.firstName ?? 'User'),
              ),
              const SizedBox(height: 16),

              // Quick Actions Section
              ResponsiveContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.send,
                            label: 'Send Money',
                            onPressed: () => _switchToTab(1),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.history,
                            label: 'Transactions',
                            onPressed: _onViewTransactions,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Balance Cards Section
              ResponsiveContainer(
                child: Row(
                  children: [
                    Expanded(
                      child: _BalanceCard(
                        balance: balance,
                        isLoading: _loading,
                      ),
                    ),
                    SizedBox(width: 12.responsiveW(context)),
                    Expanded(
                      child: _WeeklySpendingCard(
                        spending: weeklySpending,
                        isLoading: _loading,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Financial Health Section
              if (spendingPlan != null) ...[
                ResponsiveContainer(
                  child: _FinancialHealthCard(plan: spendingPlan),
                ),
                const SizedBox(height: 16),
              ],

              // Spending Insights Section
              if (hasTransactions) ...[
                ResponsiveContainer(
                  child: _SpendingInsightsCard(
                    transactions: transactions,
                    monthlySpending: monthlySpending,
                    plan: spendingPlan,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Recent Activity Section
              ResponsiveContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_loading)
                      const _LoadingState()
                    else if (!hasTransactions)
                      const _EmptyState()
                    else
                      ...transactions.take(5).map((t) => _TransactionTile(tx: t)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lottie Animation
              ResponsiveContainer(
                child: SizedBox(
                  height: 150,
                  child: Lottie.asset(
                    'assets/animations/money.json',
                    fit: BoxFit.contain,
                    repeat: true,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_balance_wallet,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Access Section
              if (hasTransactions) ...[
                ResponsiveContainer(
                  child: _QuickAccessCard(
                    onViewAllTransactions: _onViewTransactions,
                    onViewPlanning: _onViewPlanning,
                    transactionCount: transactions.length,
                    hasPlan: spendingPlan != null,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _calculateBalance(List<TransactionModel> txs, double? smsBalance) {
    try {
      // Priority: SMS-parsed balance > User-synced balance > 0.0
      final user = context.read<UserProvider>().currentUser;
      double balance = smsBalance ?? user?.mpesaBalance ?? 0.0;

      // Adjust balance based on all transactions since account creation
      // We assume initial balance was correct and all transactions affect it
      for (final t in txs) {
        if (t.amount > 0) {
          // Outgoing transaction - subtract
          balance -= t.amount;
        } else if (t.amount < 0) {
          // Incoming transaction - add (amount is negative)
          balance += t.amount.abs();
        }
      }

      return balance >= 0 ? balance : 0.0;
    } catch (e) {
      debugPrint('Error calculating balance: $e');
      return smsBalance ?? context.read<UserProvider>().currentUser?.mpesaBalance ?? 0.0;
    }
  }

  double _calculateWeeklySpending(List<TransactionModel> txs) {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentTxs = txs.where((t) => t.timestamp.isAfter(sevenDaysAgo) && t.amount > 0);
      return recentTxs.fold(0.0, (sum, t) => sum + t.amount);
    } catch (e) {
      debugPrint('Error calculating weekly spending: $e');
      return 0.0;
    }
  }

  double _calculateMonthlySpending(List<TransactionModel> txs) {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentTxs = txs.where((t) => t.timestamp.isAfter(thirtyDaysAgo) && t.amount > 0);
      return recentTxs.fold(0.0, (sum, t) => sum + t.amount);
    } catch (e) {
      debugPrint('Error calculating monthly spending: $e');
      return 0.0;
    }
  }

  void _onViewTransactions() {
    _switchToTab(2); // Transactions tab
  }

  void _onViewPlanning() {
    _switchToTab(3); // Financial Planning tab
  }

  void _switchToTab(int index) {
    final mainNavState = MainNavigation.of(context);
    if (mainNavState != null) {
      mainNavState.switchToTab(index);
    } else {
      // Fallback: Navigate to the main screen with tab index
      Navigator.pushNamed(context, '/main', arguments: index);
    }
  }

  Future<void> _handleRefresh() async {
    final user = context.read<UserProvider>().currentUser;
    if (user != null) {
      await context.read<TransactionProvider>().loadTransactions(user.phone);
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Dashboard refreshed');
      }
    }
  }

  Future<void> _syncBalance() async {
    if (_syncingBalance) return;

    setState(() => _syncingBalance = true);

    try {
      // First try to extract balance from recent SMS
      final smsProvider = context.read<SmsProvider>();
      final smsBalance = await smsProvider.extractLatestBalance();
      
      if (smsBalance != null) {
        // Update user balance with SMS-parsed value
        final userProvider = context.read<UserProvider>();
        await userProvider.updateMpesaBalance(smsBalance);
        
        if (mounted) {
          SnackbarHelper.showSuccess(
            context, 
            'Balance synced from SMS: KSH ${smsBalance.toStringAsFixed(2)}'
          );
        }
        return;
      }

      // Fallback to manual sync dialog
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => const _BalanceSyncDialog(),
        );
        
        if (result == true && mounted) {
          SnackbarHelper.showSuccess(context, 'Balance updated successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to sync balance: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _syncingBalance = false);
      }
    }
  }
}

class _HeaderGreeting extends StatelessWidget {
  final String name;
  const _HeaderGreeting({required this.name});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') {
              _logout(context);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final bool isLoading;

  const _BalanceCard({
    required this.balance,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007B3E), Color(0xFF00A859)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text('Available Balance', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const CircularProgressIndicator(color: Colors.white)
          else
            Text(
              'KSH ${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'M-Pesa Balance',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _WeeklySpendingCard extends StatelessWidget {
  final double spending;
  final bool isLoading;

  const _WeeklySpendingCard({
    required this.spending,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text('Weekly Spending', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const CircularProgressIndicator(color: Colors.white)
          else
            Text(
              'KSH ${spending.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Last 7 days',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FinancialHealthCard extends StatelessWidget {
  final SpendingPlan plan;

  const _FinancialHealthCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final score = plan.financialHealthScore;
    final color = _getScoreColor(score);
    final description = _getScoreDescription(score);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getScoreIcon(score),
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Health',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$score/100 - $description',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: color.withAlpha(50),
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/financial-planning'),
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              tooltip: 'View Details',
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF00C853);
    if (score >= 60) return const Color(0xFF00B0FF);
    if (score >= 40) return const Color(0xFFFF9100);
    return const Color(0xFFFF3D00);
  }

  IconData _getScoreIcon(int score) {
    if (score >= 80) return Icons.emoji_events_rounded;
    if (score >= 60) return Icons.thumb_up_rounded;
    if (score >= 40) return Icons.remove_red_eye_rounded;
    return Icons.warning_amber_rounded;
  }

  String _getScoreDescription(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Attention';
  }
}

class _SpendingInsightsCard extends StatelessWidget {
  final List<TransactionModel> transactions;
  final double monthlySpending;
  final SpendingPlan? plan;

  const _SpendingInsightsCard({
    required this.transactions,
    required this.monthlySpending,
    this.plan,
  });

  @override
  Widget build(BuildContext context) {
    final topCategories = _getTopSpendingCategories();
    final budgetStatus = plan != null ? _getBudgetStatus() : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.insights,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Spending Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _InsightItem(
                    label: 'This Month',
                    value: 'KSH ${monthlySpending.toStringAsFixed(0)}',
                    icon: Icons.calendar_month,
                    color: const Color(0xFF00C853),
                  ),
                ),
                if (budgetStatus != null) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _InsightItem(
                      label: 'Budget Status',
                      value: budgetStatus,
                      icon: Icons.account_balance_wallet,
                      color: _getBudgetStatusColor(budgetStatus),
                    ),
                  ),
                ],
              ],
            ),

            if (topCategories.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Top Categories',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...topCategories.take(3).map((category) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category['name'] as String),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(category['name'] as String),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${((category['amount'] as double) / monthlySpending * 100).toStringAsFixed(1)}% of monthly spending',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'KSH ${(category['amount'] as double).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getTopSpendingCategories() {
    final categoryMap = <String, double>{};

    for (final tx in transactions) {
      if (tx.amount > 0) {
        final category = _categorizeTransaction(tx.recipient);
        categoryMap[category] = (categoryMap[category] ?? 0) + tx.amount;
      }
    }

    return categoryMap.entries
        .map((e) => {'name': e.key, 'amount': e.value})
        .toList()
      ..sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
  }

  String _categorizeTransaction(String recipient) {
    final lowerRecipient = recipient.toLowerCase();
    if (lowerRecipient.contains('food') ||
        lowerRecipient.contains('restaurant') ||
        lowerRecipient.contains('lunch') ||
        lowerRecipient.contains('cafe')) {
      return 'Food & Dining';
    } else if (lowerRecipient.contains('transport') ||
        lowerRecipient.contains('matatu') ||
        lowerRecipient.contains('uber') ||
        lowerRecipient.contains('taxi') ||
        lowerRecipient.contains('bus')) {
      return 'Transport';
    } else if (lowerRecipient.contains('airtime') ||
        lowerRecipient.contains('data') ||
        lowerRecipient.contains('mobile')) {
      return 'Airtime & Data';
    } else if (lowerRecipient.contains('shop') ||
        lowerRecipient.contains('store') ||
        lowerRecipient.contains('market')) {
      return 'Shopping';
    } else if (lowerRecipient.contains('bill') ||
        lowerRecipient.contains('water') ||
        lowerRecipient.contains('electricity') ||
        lowerRecipient.contains('rent')) {
      return 'Bills & Utilities';
    } else {
      return 'Other';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food & Dining':
        return const Color(0xFFFF6B35);
      case 'Transport':
        return const Color(0xFF00B0FF);
      case 'Airtime & Data':
        return const Color(0xFF7B1FA2);
      case 'Shopping':
        return const Color(0xFF4CAF50);
      case 'Bills & Utilities':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food & Dining':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Airtime & Data':
        return Icons.phone_iphone;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Bills & Utilities':
        return Icons.receipt;
      default:
        return Icons.category;
    }
  }

  String? _getBudgetStatus() {
    if (plan == null) return null;

    final monthlyBudget = plan!.monthlyBudget.toDouble();
    if (monthlyBudget <= 0) return 'No Budget Set';

    final utilization = (monthlySpending / monthlyBudget) * 100;

    if (utilization <= 75) return 'On Track';
    if (utilization <= 90) return 'Watch Carefully';
    return 'Over Budget';
  }

  Color _getBudgetStatusColor(String status) {
    switch (status) {
      case 'On Track':
        return const Color(0xFF00C853);
      case 'Watch Carefully':
        return const Color(0xFFFF9800);
      case 'Over Budget':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }
}

class _InsightItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InsightItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final VoidCallback onViewAllTransactions;
  final VoidCallback onViewPlanning;
  final int transactionCount;
  final bool hasPlan;

  const _QuickAccessCard({
    required this.onViewAllTransactions,
    required this.onViewPlanning,
    required this.transactionCount,
    required this.hasPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Access',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickAccessButton(
                    icon: Icons.history,
                    label: 'All Transactions',
                    subtitle: '$transactionCount total',
                    onPressed: onViewAllTransactions,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAccessButton(
                    icon: Icons.account_balance_wallet,
                    label: hasPlan ? 'Update Plan' : 'Create Plan',
                    subtitle: hasPlan ? 'AI-powered' : 'Get started',
                    onPressed: onViewPlanning,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onPressed;
  final Color color;

  const _QuickAccessButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),

          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isFraud = tx.isFraudulent;
    final color = isFraud ? Colors.red : Colors.green;
    final icon = isFraud ? Icons.warning_amber_rounded : Icons.check_circle;
    final formattedDate = _formatDate(tx.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          'KSH ${tx.amount.abs().toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(tx.recipient),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withAlpha(100)),
              ),
              child: Text(
                isFraud ? 'Flagged' : 'Safe',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _FraudStatusBadge extends StatelessWidget {
  final bool isActive;

  const _FraudStatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.red;
    final text = isActive ? 'Protected' : 'Alert';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.shield : Icons.warning,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading transactions...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Start by making your first transaction',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final mainNavState = MainNavigation.of(context);
              if (mainNavState != null) {
                mainNavState.switchToTab(1); // Send Money tab
              }
            },
            child: const Text('Make First Transaction'),
          ),
        ],
      ),
    );
  }
}

class _BalanceSyncDialog extends StatefulWidget {
  const _BalanceSyncDialog();

  @override
  State<_BalanceSyncDialog> createState() => _BalanceSyncDialogState();
}

class _BalanceSyncDialogState extends State<_BalanceSyncDialog> {
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _balanceController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sync M-Pesa Balance'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your current M-Pesa balance to ensure accurate financial tracking.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _balanceController,
              decoration: const InputDecoration(
                labelText: 'Current M-Pesa Balance (KSH)',
                hintText: 'e.g. 2500.50',
                prefixIcon: Icon(Icons.account_balance_wallet),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              decoration: const InputDecoration(
                labelText: 'M-Pesa PIN',
                hintText: 'Enter your PIN to verify',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 4),
            Text(
              'Note: Your PIN is not stored and is only used for verification.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _syncBalance,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Sync Balance'),
        ),
      ],
    );
  }

  Future<void> _syncBalance() async {
    final balanceText = _balanceController.text.trim();
    final pinText = _pinController.text.trim();

    if (balanceText.isEmpty) {
      SnackbarHelper.showError(context, 'Please enter your balance');
      return;
    }

    final balance = double.tryParse(balanceText);
    if (balance == null || balance < 0) {
      SnackbarHelper.showError(context, 'Please enter a valid, non-negative balance');
      return;
    }

    if (pinText.length != 4) {
      SnackbarHelper.showError(context, 'Please enter a valid 4-digit PIN');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();
      final success = await userProvider.updateMpesaBalance(balance);

      if (success && mounted) {
        Navigator.of(context).pop(true);
      } else if (mounted) {
        SnackbarHelper.showError(
          context,
          userProvider.error ?? 'Failed to sync balance. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'An unexpected error occurred. Please try again later.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}