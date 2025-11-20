import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/financial_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../models/spending_plan.dart';
import '../models/financial_enhancements.dart';

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

      // Load enhanced features
      await Future.wait([
        financialProvider.generatePredictions(transactionProvider.transactions, 3),
        financialProvider.detectAnomalies(transactionProvider.transactions),
        financialProvider.generateSmartSuggestions(
          transactionProvider.transactions,
          currentBalance,
        ),
      ]);
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

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Financial Planning'),
          actions: [
            IconButton(
              onPressed: _loadFinancialPlan,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Plan',
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Plan', icon: Icon(Icons.account_balance)),
              Tab(text: 'Chat', icon: Icon(Icons.chat)),
              Tab(text: 'Predictions', icon: Icon(Icons.trending_up)),
              Tab(text: 'Alerts', icon: Icon(Icons.warning)),
              Tab(text: 'Suggestions', icon: Icon(Icons.lightbulb)),
            ],
          ),
        ),
        body: financialProvider.isLoading
            ? const _LoadingView()
            : financialProvider.hasPlan
                ? TabBarView(
                    children: [
                      _FinancialPlanView(plan: financialProvider.currentPlan!),
                      _ConversationsView(),
                      _PredictionsView(),
                      _AnomaliesView(),
                      _SuggestionsView(),
                    ],
                  )
                : _EmptyStateView(onGenerate: _loadFinancialPlan),
      ),
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

class _ConversationsView extends StatefulWidget {
  const _ConversationsView();

  @override
  State<_ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends State<_ConversationsView> {
  final TextEditingController _questionController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final financialProvider = context.watch<FinancialProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    return Column(
      children: [
        Expanded(
          child: financialProvider.conversations.isEmpty
              ? const Center(
                  child: Text('Ask questions about your financial plan'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: financialProvider.conversations.length,
                  itemBuilder: (context, index) {
                    final message = financialProvider.conversations[index];
                    return _ConversationBubble(message: message);
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  decoration: const InputDecoration(
                    hintText: 'Ask about your financial plan...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _askQuestion(financialProvider, transactionProvider),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _askQuestion(financialProvider, transactionProvider),
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _askQuestion(FinancialProvider provider, TransactionProvider transactionProvider) {
    final question = _questionController.text.trim();
    if (question.isNotEmpty) {
      provider.askQuestion(question, transactionProvider.transactions);
      _questionController.clear();
    }
  }
}

class _ConversationBubble extends StatelessWidget {
  final ConversationMessage message;

  const _ConversationBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.question,
              style: TextStyle(
                color: isUser
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (message.answer.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.answer,
                style: TextStyle(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.9)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PredictionsView extends StatelessWidget {
  const _PredictionsView();

  @override
  Widget build(BuildContext context) {
    final financialProvider = context.watch<FinancialProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => financialProvider.generatePredictions(
              transactionProvider.transactions,
              3, // 3 months ahead
            ),
            icon: const Icon(Icons.trending_up),
            label: const Text('Generate Predictions'),
          ),
        ),
        Expanded(
          child: financialProvider.predictions.isEmpty
              ? const Center(
                  child: Text('No predictions available'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: financialProvider.predictions.length,
                  itemBuilder: (context, index) {
                    final prediction = financialProvider.predictions[index];
                    return _PredictionCard(prediction: prediction);
                  },
                ),
        ),
      ],
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final SpendingPrediction prediction;

  const _PredictionCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  prediction.category,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(prediction.confidence * 100).toStringAsFixed(0)}% confidence',
                    style: const TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Predicted: KSH ${prediction.predictedAmount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              prediction.reasoning,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnomaliesView extends StatelessWidget {
  const _AnomaliesView();

  @override
  Widget build(BuildContext context) {
    final financialProvider = context.watch<FinancialProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => financialProvider.detectAnomalies(
              transactionProvider.transactions,
            ),
            icon: const Icon(Icons.search),
            label: const Text('Detect Anomalies'),
          ),
        ),
        Expanded(
          child: financialProvider.anomalies.isEmpty
              ? const Center(
                  child: Text('No anomalies detected'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: financialProvider.anomalies.length,
                  itemBuilder: (context, index) {
                    final anomaly = financialProvider.anomalies[index];
                    return _AnomalyCard(anomaly: anomaly);
                  },
                ),
        ),
      ],
    );
  }
}

class _AnomalyCard extends StatelessWidget {
  final SpendingAnomaly anomaly;

  const _AnomalyCard({required this.anomaly});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: anomaly.severityColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    anomaly.description,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: anomaly.severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    anomaly.severityText,
                    style: TextStyle(
                      color: anomaly.severityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: KSH ${anomaly.amount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Category: ${anomaly.category}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              anomaly.recommendation,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionsView extends StatelessWidget {
  const _SuggestionsView();

  @override
  Widget build(BuildContext context) {
    final financialProvider = context.watch<FinancialProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final userProvider = context.read<UserProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              final currentBalance = _estimateCurrentBalance(transactionProvider.transactions);
              financialProvider.generateSmartSuggestions(
                transactionProvider.transactions,
                currentBalance,
              );
            },
            icon: const Icon(Icons.lightbulb),
            label: const Text('Generate Suggestions'),
          ),
        ),
        Expanded(
          child: financialProvider.suggestions.isEmpty
              ? const Center(
                  child: Text('No suggestions available'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: financialProvider.suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = financialProvider.suggestions[index];
                    return _SuggestionCard(suggestion: suggestion);
                  },
                ),
        ),
      ],
    );
  }

  double _estimateCurrentBalance(List transactions) {
    double estimatedBalance = 10000.0;
    final recentTransactions = transactions.where((t) =>
      t.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 30))));

    for (final transaction in recentTransactions) {
      if (transaction.amount > 0) {
        estimatedBalance -= transaction.amount;
      }
    }

    return estimatedBalance > 0 ? estimatedBalance : 1000.0;
  }
}

class _SuggestionCard extends StatelessWidget {
  final SmartSuggestion suggestion;

  const _SuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final financialProvider = context.read<FinancialProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: suggestion.priorityColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: suggestion.priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    suggestion.priorityText,
                    style: TextStyle(
                      color: suggestion.priorityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Potential savings: KSH ${suggestion.potentialSavings.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (!suggestion.isImplemented)
                  TextButton(
                    onPressed: () => financialProvider.markSuggestionImplemented(suggestion.id),
                    child: const Text('Mark as Done'),
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