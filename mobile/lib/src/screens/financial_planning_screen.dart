import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/financial_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../models/spending_plan.dart';

class FinancialPlanningScreen extends StatefulWidget {
  const FinancialPlanningScreen({super.key});

  @override
  State<FinancialPlanningScreen> createState() => _FinancialPlanningScreenState();
}

class _FinancialPlanningScreenState extends State<FinancialPlanningScreen> {
  @override
  void initState() {
    super.initState();
    _loadFinancialPlan();
  }

  Future<void> _loadFinancialPlan() async {
    final userProvider = context.read<UserProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final financialProvider = context.read<FinancialProvider>();

    if (userProvider.currentUser != null) {
      // Estimate current balance (this would come from actual balance in production)
      final currentBalance = _estimateCurrentBalance(transactionProvider.transactions);

      await financialProvider.generateSpendingPlan(
        transactionProvider.transactions,
        currentBalance,
      );
    }
  }

  double _estimateCurrentBalance(List transactions) {
    // Simple estimation: assume starting balance of 10,000 KSH minus recent spending
    double estimatedBalance = 10000.0;

    // Subtract recent outgoing transactions
    final recentTransactions = transactions.where((t) =>
      t.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 30))));

    for (final transaction in recentTransactions) {
      if (transaction.amount > 0) { // Outgoing
        estimatedBalance -= transaction.amount;
      }
    }

    return estimatedBalance > 0 ? estimatedBalance : 1000.0; // Minimum balance
  }

  @override
  Widget build(BuildContext context) {
    final financialProvider = context.watch<FinancialProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Planning'),
        actions: [
          IconButton(
            onPressed: _loadFinancialPlan,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Plan',
          ),
        ],
      ),
      body: financialProvider.isLoading
          ? const _LoadingView()
          : financialProvider.hasPlan
              ? _FinancialPlanView(plan: financialProvider.currentPlan!)
              : _EmptyStateView(onGenerate: _loadFinancialPlan),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Analyzing your spending patterns...'),
          SizedBox(height: 8),
          Text('This may take a few moments', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  final VoidCallback onGenerate;

  const _EmptyStateView({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Create Your Financial Plan',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Get personalized spending advice based on your transaction history and financial goals.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialPlanView extends StatelessWidget {
  final SpendingPlan plan;

  const _FinancialPlanView({required this.plan});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Financial Health Score
        _FinancialHealthCard(plan: plan),
        const SizedBox(height: 16),

        // Budget Overview
        _BudgetOverviewCard(plan: plan),
        const SizedBox(height: 16),

        // Spending Categories
        _SpendingCategoriesCard(plan: plan),
        const SizedBox(height: 16),

        // Recommendations
        if (plan.recommendations.isNotEmpty) ...[
          _RecommendationsCard(
            title: 'Recommendations',
            items: plan.recommendations,
            icon: Icons.lightbulb,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
        ],

        // Waste Alerts
        if (plan.wasteAlerts.isNotEmpty) ...[
          _RecommendationsCard(
            title: 'Spending Alerts',
            items: plan.wasteAlerts,
            icon: Icons.warning,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
        ],

        // Savings Tips
        if (plan.savingsTips.isNotEmpty) ...[
          _RecommendationsCard(
            title: 'Savings Tips',
            items: plan.savingsTips,
            icon: Icons.savings,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
        ],

        // Fraud Risks
        if (plan.fraudRisks.isNotEmpty) ...[
          _RecommendationsCard(
            title: 'Security Alerts',
            items: plan.fraudRisks,
            icon: Icons.security,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _FinancialHealthCard extends StatelessWidget {
  final SpendingPlan plan;

  const _FinancialHealthCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final score = plan.financialHealthScore;
    final description = _getScoreDescription(score);
    final color = _getScoreColor(score);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: color),
                const SizedBox(width: 8),
                Text(
                  'Financial Health Score',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    '$score/100',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              _getScoreAdvice(score),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _getScoreDescription(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Improvement';
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getScoreAdvice(int score) {
    if (score >= 80) {
      return 'Keep up the great work! Your financial habits are excellent.';
    } else if (score >= 60) {
      return 'You\'re doing well, but there\'s room for improvement in some areas.';
    } else if (score >= 40) {
      return 'Consider reviewing your spending patterns and building better habits.';
    } else {
      return 'Focus on creating a budget and building an emergency fund.';
    }
  }
}

class _BudgetOverviewCard extends StatelessWidget {
  final SpendingPlan plan;

  const _BudgetOverviewCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _BudgetItem(
                    label: 'Weekly Budget',
                    amount: plan.weeklyBudget.toDouble(),
                    icon: Icons.calendar_view_week,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _BudgetItem(
                    label: 'Monthly Budget',
                    amount: plan.monthlyBudget.toDouble(),
                    icon: Icons.calendar_month,
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

class _BudgetItem extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;

  const _BudgetItem({
    required this.label,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            'KSH ${amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SpendingCategoriesCard extends StatelessWidget {
  final SpendingPlan plan;

  const _SpendingCategoriesCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Categories',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...plan.categories.map((category) => _CategoryItem(category: category)),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final SpendingCategory category;

  const _CategoryItem({required this.category});

  @override
  Widget build(BuildContext context) {
    final isOverBudget = category.isOverBudget;
    final color = _getCategoryColor(category.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(_getCategoryIcon(category.category), color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      category.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allocated: KSH ${category.allocated}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Recommended: KSH ${category.recommended}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverBudget ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOverBudget ? Colors.red : Colors.green,
                  ),
                ),
                child: Text(
                  category.statusText,
                  style: TextStyle(
                    color: isOverBudget ? Colors.red : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'essential':
        return Colors.blue;
      case 'discretionary':
        return Colors.orange;
      case 'savings':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'essential':
        return Icons.home;
      case 'discretionary':
        return Icons.shopping_bag;
      case 'savings':
        return Icons.savings;
      default:
        return Icons.category;
    }
  }
}

class _RecommendationsCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  const _RecommendationsCard({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}