import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../providers/fraud_provider.dart';
import '../providers/financial_provider.dart';
import '../models/transaction.dart';
import '../models/spending_plan.dart';
import '../utils/snackbar_helper.dart';
import 'main_navigation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
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

    final transactions = txProvider.transactions;
    final hasTransactions = transactions.isNotEmpty;
    final spendingPlan = financialProvider.currentPlan;

    final balance = _calculateBalance(transactions);
    final weeklySpending = _calculateWeeklySpending(transactions);
    final monthlySpending = _calculateMonthlySpending(transactions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Dashboard'),
        actions: [
          IconButton(
            onPressed: _syncBalance,
            icon: const Icon(Icons.sync),
            tooltip: 'Sync M-Pesa Balance',
          ),
          _FraudStatusBadge(isActive: fraudProvider.lastResult?.isFraud == false),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final user = context.read<UserProvider>().currentUser;
          if (user != null) {
            await context.read<TransactionProvider>().loadTransactions(user.phone);
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderGreeting(name: user?.firstName ?? 'User'),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: _BalanceCard(balance: balance)),
                const SizedBox(width: 12),
                Expanded(child: _WeeklySpendingCard(spending: weeklySpending)),
              ],
            ),
            const SizedBox(height: 16),

            if (spendingPlan != null) ...[
              _FinancialHealthCard(plan: spendingPlan),
              const SizedBox(height: 16),
            ],


            if (hasTransactions) ...[
              _SpendingInsightsCard(
                transactions: transactions,
                monthlySpending: monthlySpending,
                plan: spendingPlan,
              ),
              const SizedBox(height: 16),
            ],

            Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_loading)
              const _LoadingState()
            else if (!hasTransactions)
              const _EmptyState()
            else
              ...transactions.take(5).map((t) => _TransactionTile(tx: t)),

            if (hasTransactions) ...[
              const SizedBox(height: 16),
              _QuickAccessCard(
                onViewAllTransactions: _onHistory,
                onViewPlanning: _onPlanning,
                transactionCount: transactions.length,
                hasPlan: spendingPlan != null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _calculateBalance(List<TransactionModel> txs) {
    // Start with the synced M-Pesa balance
    final user = context.read<UserProvider>().currentUser;
    double balance = user?.mpesaBalance ?? 0.0;

    // Adjust balance based on all transactions since account creation
    // Positive amount = outgoing (subtract), Negative amount = incoming (add)
    for (final t in txs) {
      if (t.amount > 0) {
        // Outgoing transaction
        balance -= t.amount;
      } else {
        // Incoming transaction (amount is negative, so we add the absolute value)
        balance += t.amount.abs();
      }
    }

    return balance >= 0 ? balance : 0.0;
  }

  double _calculateWeeklySpending(List<TransactionModel> txs) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentTxs = txs.where((t) => t.timestamp.isAfter(sevenDaysAgo) && t.amount > 0);
    return recentTxs.fold(0.0, (sum, t) => sum + t.amount);
  }

  double _calculateMonthlySpending(List<TransactionModel> txs) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentTxs = txs.where((t) => t.timestamp.isAfter(thirtyDaysAgo) && t.amount > 0);
    return recentTxs.fold(0.0, (sum, t) => sum + t.amount);
  }

  void _onNewTx() {
    _switchToTab(1); // Send Money tab
  }

  void _onHistory() {
    _switchToTab(2); // Transactions tab
  }

  void _onPlanning() {
    _switchToTab(3); // Financial Planning tab
  }

  void _switchToTab(int index) {
    final mainNavState = MainNavigation.of(context);
    if (mainNavState != null) {
      mainNavState.switchToTab(index);
    } else {
      // Fallback: try to navigate to the route (for when not in MainNavigation)
      final routes = ['/dashboard', '/send-money', '/transactions', '/financial-planning', '/settings'];
      if (index < routes.length) {
        Navigator.pushNamed(context, routes[index]);
      }
    }
  }

  void _syncBalance() {
    showDialog(
      context: context,
      builder: (context) => _BalanceSyncDialog(),
    );
  }

  void _onSettings() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings coming soon')));
  }
}

class _HeaderGreeting extends StatelessWidget {
  final String name;
  const _HeaderGreeting({required this.name});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Welcome $name to Shield AI',
            style: Theme.of(context).textTheme.titleLarge,
            overflow: TextOverflow.ellipsis,
          ),
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
                leading: Icon(Icons.logout),
                title: Text('Logout'),
              ),
            ),
          ],
          child: const CircleAvatar(radius: 20, child: Icon(Icons.person)),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF007B3E), Color(0xFF00A859)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Balance', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text('KSH ${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onNew;
  final VoidCallback onHistory;
  final VoidCallback onPlanning;
  final VoidCallback onSettings;
  const _QuickActions({
    required this.onNew,
    required this.onHistory,
    required this.onPlanning,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ActionButton(icon: Icons.send, label: 'Send Money', onPressed: onNew),
            _ActionButton(icon: Icons.history, label: 'History', onPressed: onHistory),
            _ActionButton(icon: Icons.account_balance_wallet, label: 'Planning', onPressed: onPlanning),
            _ActionButton(icon: Icons.settings, label: 'Settings', onPressed: onSettings),
          ],
        ),
      ],
    );
  }
}

class _WeeklySpendingCard extends StatelessWidget {
  final double spending;
  const _WeeklySpendingCard({required this.spending});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This Week', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            'KSH ${spending.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('spent', style: TextStyle(color: Colors.white70, fontSize: 12)),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getScoreIcon(score),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Health',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$score/100 - ${_getScoreDescription(score)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/financial-planning'),
              child: const Text('View Plan'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(int score) {
    if (score >= 80) return Icons.sentiment_very_satisfied;
    if (score >= 60) return Icons.sentiment_satisfied;
    if (score >= 40) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
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
                const Icon(Icons.insights),
                const SizedBox(width: 8),
                Text('Spending Insights', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _InsightItem(
                    label: 'This Month',
                    value: 'KSH ${monthlySpending.toStringAsFixed(0)}',
                    icon: Icons.calendar_month,
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
              const SizedBox(height: 16),
              Text('Top Spending Categories', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...topCategories.take(3).map((category) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(category['name'] as String),
                    ),
                    Expanded(
                      child: Text(
                        'KSH ${(category['amount'] as double).toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w500),
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
    if (lowerRecipient.contains('food') || lowerRecipient.contains('restaurant') || lowerRecipient.contains('lunch')) {
      return 'Food & Dining';
    } else if (lowerRecipient.contains('transport') || lowerRecipient.contains('matatu') || lowerRecipient.contains('uber')) {
      return 'Transport';
    } else if (lowerRecipient.contains('airtime') || lowerRecipient.contains('data')) {
      return 'Airtime & Data';
    } else if (lowerRecipient.contains('shop') || lowerRecipient.contains('store')) {
      return 'Shopping';
    } else {
      return 'Other';
    }
  }

  String? _getBudgetStatus() {
    if (plan == null) return null;

    final monthlyBudget = plan!.monthlyBudget.toDouble();
    final utilization = (monthlySpending / monthlyBudget) * 100;

    if (utilization <= 75) return 'On Track';
    if (utilization <= 90) return 'Watch Carefully';
    return 'Over Budget';
  }

  Color _getBudgetStatusColor(String status) {
    switch (status) {
      case 'On Track': return Colors.green;
      case 'Watch Carefully': return Colors.orange;
      case 'Over Budget': return Colors.red;
      default: return Colors.grey;
    }
  }
}

class _InsightItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _InsightItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color ?? Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
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
            Text('Quick Access', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickAccessButton(
                    icon: Icons.history,
                    label: 'View All\nTransactions',
                    subtitle: '$transactionCount total',
                    onPressed: onViewAllTransactions,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAccessButton(
                    icon: Icons.account_balance_wallet,
                    label: hasPlan ? 'Update\nPlan' : 'Create\nPlan',
                    subtitle: hasPlan ? 'AI-powered' : 'Get started',
                    onPressed: onViewPlanning,
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

  const _QuickAccessButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, textAlign: TextAlign.center),
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
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text('KSH ${tx.amount.toStringAsFixed(2)} - ${tx.recipient}'),
        subtitle: Text(tx.timestamp.toIso8601String()),
        trailing: Text(isFraud ? 'Flagged' : 'Safe', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
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
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(isActive ? Icons.shield : Icons.warning, color: color, size: 18),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: Colors.grey.shade300),
         ),
         child: Row(
           children: const [
             Icon(Icons.info_outline),
             SizedBox(width: 8),
             Expanded(child: Text('No recent transactions yet. Start by making a new transaction.')),
           ],
         ),
       );
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter your current M-Pesa balance to sync with Shield AI. This will ensure accurate balance calculations.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _balanceController,
            decoration: const InputDecoration(
              labelText: 'Current M-Pesa Balance (KSH)',
              hintText: 'e.g. 2500.50',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            decoration: const InputDecoration(
              labelText: 'M-Pesa PIN',
              hintText: 'Enter your PIN to verify',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
    final pin = _pinController.text.trim();

    if (balanceText.isEmpty || pin.isEmpty) {
      SnackbarHelper.showError(context, 'Please enter both balance and PIN');
      return;
    }

    final balance = double.tryParse(balanceText);
    if (balance == null || balance < 0) {
      SnackbarHelper.showError(context, 'Please enter a valid, non-negative balance');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();
      final success = await userProvider.updateMpesaBalance(balance, pin);

      if (success && mounted) {
        Navigator.of(context).pop();
        SnackbarHelper.showSuccess(context, 'Balance synced successfully!');
      } else if (mounted) {
        SnackbarHelper.showError(context, userProvider.error ?? 'Failed to sync balance. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'An unexpected error occurred. Please try again later.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
