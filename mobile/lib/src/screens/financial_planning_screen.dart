import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/financial_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../models/spending_plan.dart';
import '../models/financial_enhancements.dart';
import '../models/user_budget_plan.dart';
import '../models/user.dart';
import '../services/sound_service.dart';
import '../services/clipboard_service.dart';
import '../services/share_service.dart';
import '../widgets/pin_prompt_dialog.dart';

class FinancialPlanningScreen extends StatefulWidget {
  const FinancialPlanningScreen({super.key});

  @override
  State<FinancialPlanningScreen> createState() => _FinancialPlanningScreenState();
}

class _FinancialPlanningScreenState extends State<FinancialPlanningScreen> {
  @override
  void initState() {
    super.initState();
    // Defer loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFinancialPlan();
    });
  }

  Future<void> _loadFinancialPlan() async {
    final userProvider = context.read<UserProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final financialProvider = context.read<FinancialProvider>();

    if (userProvider.currentUser != null) {
      final currentBalance = _estimateCurrentBalance(transactionProvider.transactions);

      // Only generate AI plan if no user plan exists
      if (!financialProvider.hasUserPlan) {
        await financialProvider.generateSpendingPlan(
          transactionProvider.transactions,
          currentBalance,
        );
      }

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

  Future<void> _loadUserPlansWithPin() async {
    final userProvider = context.read<UserProvider>();
    final financialProvider = context.read<FinancialProvider>();

    if (userProvider.currentUser == null) return;

    final pin = await PinPromptDialog.show(
      context,
      title: 'Load Budget Plans',
      message: 'Enter your M-Pesa PIN to load your budget plans.',
    );

    if (pin != null && mounted) {
      await financialProvider.loadUserPlans(
        userProvider.currentUser!.phone,
        pin,
      );

      if (financialProvider.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load plans: ${financialProvider.error}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final financialProvider = context.watch<FinancialProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final userProvider = context.watch<UserProvider>();

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
            IconButton(
              onPressed: _loadUserPlansWithPin,
              icon: const Icon(Icons.account_balance_wallet),
              tooltip: 'Load Budget Plans',
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
            : TabBarView(
                children: [
                  _FinancialPlanView(),
                  _ConversationsView(userProvider: userProvider),
                  _PredictionsView(),
                  _AnomaliesView(),
                  _SuggestionsView(),
                ],
              ),
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
              color: Theme.of(context).colorScheme.primary.withAlpha(128),
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
  const _FinancialPlanView();

  @override
  Widget build(BuildContext context) {
    return Consumer<FinancialProvider>(
      builder: (context, financialProvider, child) {
        final userPlan = financialProvider.activeUserPlan;
        final aiPlan = financialProvider.currentPlan;

        if (userPlan != null) {
          return _UserPlanView(userPlan: userPlan);
        } else if (aiPlan != null) {
          return _PlanAnalysisView();
        } else {
          return _PlanCreationPrompt();
        }
      },
    );
  }
}

class _UserPlanView extends StatelessWidget {
  final UserBudgetPlan userPlan;

  const _UserPlanView({required this.userPlan});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _UserPlanHeader(plan: userPlan),
        const SizedBox(height: 16),
        _UserBudgetOverviewCard(plan: userPlan),
        const SizedBox(height: 16),
        _UserSpendingCategoriesCard(plan: userPlan),
        const SizedBox(height: 16),
        _PlanActionsCard(plan: userPlan),
        const SizedBox(height: 16),
        _CreateNewPlanCard(),
      ],
    );
  }
}

class _PlanAnalysisView extends StatelessWidget {
  const _PlanAnalysisView();

  @override
  Widget build(BuildContext context) {
    final financialProvider = context.watch<FinancialProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final userProvider = context.read<UserProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PlanAnalysisHeader(),
        const SizedBox(height: 16),
        _RealFinancialHealthCard(),
        const SizedBox(height: 16),
        // Display user budget plan if it exists, otherwise show fallback message
        if (financialProvider.activeUserPlan != null)
          _UserBudgetPlanSummaryCard(plan: financialProvider.activeUserPlan!)
        else
          _NoBudgetPlanCard(),
        const SizedBox(height: 16),
        _PlanProgressCard(),
        const SizedBox(height: 16),
        _PlanVsActualSpendingCard(),
        const SizedBox(height: 16),
        _PersonalizedRecommendationsCard(),
        const SizedBox(height: 16),
        _CreateNewPlanCard(),
      ],
    );
  }
}

class _PlanCreationPrompt extends StatelessWidget {
  const _PlanCreationPrompt();

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
              color: Theme.of(context).colorScheme.primary.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'Create Your Budget Plan',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Take control of your finances by creating a personalized budget plan tailored to your needs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/budget-creation'),
              icon: const Icon(Icons.add),
              label: const Text('Create Plan'),
            ),
          ],
        ),
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
                    color: color.withAlpha(25),
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
  final UserProvider userProvider;

  const _ConversationsView({required this.userProvider});

  @override
  State<_ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends State<_ConversationsView> {
  final TextEditingController _questionController = TextEditingController();
  final SoundService _soundService = SoundService();
  bool _wasTyping = false;

  @override
  void initState() {
    super.initState();
    _questionController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _questionController.removeListener(_onTextChanged);
    _questionController.dispose();
    _soundService.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_questionController.text.isNotEmpty) {
      _soundService.playTypingSound();
    }
  }

  @override
  Widget build(BuildContext context) {
    final financialProvider = context.watch<FinancialProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    if (_wasTyping && !financialProvider.isTyping) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _soundService.playResponseSound();
      });
    }
    _wasTyping = financialProvider.isTyping;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: financialProvider.conversations.length,
            itemBuilder: (context, index) {
              final message = financialProvider.conversations[index];
              return _ConversationBubble(message: message);
            },
          ),
        ),
        if (financialProvider.isTyping)
          const _TypingIndicator(),
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
                  onSubmitted: (_) => _askQuestion(financialProvider, transactionProvider, widget.userProvider),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _askQuestion(financialProvider, transactionProvider, widget.userProvider),
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _askQuestion(FinancialProvider provider, TransactionProvider transactionProvider, UserProvider userProvider) async {
    final question = _questionController.text.trim();
    if (question.isNotEmpty && userProvider.currentUser != null) {
      final pin = await PinPromptDialog.show(
        context,
        title: 'AI Assistant',
        message: 'Enter your M-Pesa PIN to ask the AI assistant.',
      );

      if (pin != null && mounted) {
        provider.askQuestion(question, userProvider.currentUser!.phone, pin);
        _questionController.clear();
      }
    }
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return ScaleTransition(
                scale: Tween(begin: 0.5, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Interval(0.1 * index, 0.5 + 0.1 * index, curve: Curves.easeInOut),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ConversationBubble extends StatelessWidget {
  final ConversationMessage message;

  const _ConversationBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromUser;
    final displayText = isUser ? message.question : (message.answer.isNotEmpty ? message.answer : message.question);

    // Parse JSON responses for AI messages
    String cleanText = displayText;
    if (!isUser) {
      try {
        // Try to parse as JSON first
        final jsonResponse = jsonDecode(displayText);
        if (jsonResponse is Map && jsonResponse.containsKey('response')) {
          cleanText = jsonResponse['response'];
          // Convert \n\n to actual line breaks and handle other escape sequences
          cleanText = cleanText.replaceAll(r'\n', '\n').replaceAll(r'\\n', '\n');
        }
      } catch (e) {
        // If not JSON, use the text as-is
        cleanText = displayText;
      }
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
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
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message content
            Container(
              padding: const EdgeInsets.all(12),
              child: isUser
                  ? Text(
                      cleanText,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : MarkdownBody(
                      data: cleanText,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
            ),
            // Action buttons (only for AI messages)
            if (!isUser) _MessageActions(text: cleanText),
          ],
        ),
      ),
    );
  }
}

class _MessageActions extends StatelessWidget {
  final String text;

  const _MessageActions({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Copy button
          IconButton(
            onPressed: () => ClipboardService.copyToClipboard(context, text),
            icon: Icon(
              Icons.copy,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Copy message',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          // Share button
          IconButton(
            onPressed: () => ShareService.shareMessage(context, text),
            icon: Icon(
              Icons.share,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Share message',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ],
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
    final userProvider = context.read<UserProvider>();

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
                    color: Colors.blue.withAlpha(25),
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
                    color: anomaly.severityColor.withAlpha(25),
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
                    color: suggestion.priorityColor.withAlpha(25),
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

class _UserPlanHeader extends StatelessWidget {
  final UserBudgetPlan plan;

  const _UserPlanHeader({required this.plan});

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
                Icon(Icons.account_balance, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plan.planName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Text(
                    'Active Plan',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (plan.planDescription != null) ...[
              const SizedBox(height: 8),
              Text(
                plan.planDescription!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Created ${plan.createdAt.toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserBudgetOverviewCard extends StatelessWidget {
  final UserBudgetPlan plan;

  const _UserBudgetOverviewCard({required this.plan});

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
                    label: 'Monthly Income',
                    amount: plan.monthlyIncome,
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _BudgetItem(
                    label: 'Total Allocated',
                    amount: plan.totalAllocated,
                    icon: Icons.pie_chart,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _BudgetItem(
                    label: 'Remaining',
                    amount: plan.remainingToAllocate,
                    icon: Icons.savings,
                  ),
                ),
                if (plan.savingsGoal != null) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _BudgetItem(
                      label: 'Savings Goal',
                      amount: plan.savingsGoal!,
                      icon: Icons.flag,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSpendingCategoriesCard extends StatelessWidget {
  final UserBudgetPlan plan;

  const _UserSpendingCategoriesCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final allocatedCategories = plan.allocations.entries
        .where((entry) => entry.value > 0)
        .toList();

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
            ...allocatedCategories.map((entry) {
              final percentage = plan.monthlyIncome > 0
                  ? (entry.value / plan.monthlyIncome * 100)
                  : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(entry.key).withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(entry.key),
                        color: _getCategoryColor(entry.key),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}% of income',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'KES ${entry.value.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food & groceries':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'airtime & data':
        return Colors.purple;
      case 'entertainment':
        return Colors.pink;
      case 'utilities':
        return Colors.teal;
      case 'healthcare':
        return Colors.red;
      case 'education':
        return Colors.indigo;
      case 'savings':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food & groceries':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'airtime & data':
        return Icons.phone_android;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.lightbulb;
      case 'healthcare':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'savings':
        return Icons.savings;
      default:
        return Icons.category;
    }
  }
}

class _PlanActionsCard extends StatelessWidget {
  final UserBudgetPlan plan;

  const _PlanActionsCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/budget-creation',
                      arguments: plan, // Pass the plan for editing
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Plan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPlanOptions(context),
                    icon: const Icon(Icons.more_vert),
                    label: const Text('Options'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPlanOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Plan'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement share functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Duplicate Plan'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement duplicate functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Plan', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    final financialProvider = context.read<FinancialProvider>();

    if (userProvider.currentUser == null) return;

    final pin = await PinPromptDialog.show(
      context,
      title: 'Delete Budget Plan',
      message: 'Enter your M-Pesa PIN to confirm deletion of this budget plan.',
      confirmText: 'Delete',
    );

    if (pin != null) {
      final success = await financialProvider.deleteUserPlan(
        plan.id,
        userProvider.currentUser!.phone,
        pin,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget plan deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete plan: ${financialProvider.error ?? 'Unknown error'}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _AIPlanHeader extends StatelessWidget {
  const _AIPlanHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.smart_toy, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI-Generated Plan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'This plan was created by our AI based on your spending patterns. Create a custom plan for more control.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/budget-creation'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create Custom'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
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
                  color: color.withAlpha(25),
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
                  color: isOverBudget ? Colors.red.withAlpha(25) : Colors.green.withAlpha(25),
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

class _PlanAnalysisHeader extends StatelessWidget {
  const _PlanAnalysisHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan Analysis',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Real-time analysis of your budget performance and personalized insights.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RealFinancialHealthCard extends StatelessWidget {
  const _RealFinancialHealthCard();

  @override
  Widget build(BuildContext context) {
    final financialProvider = context.watch<FinancialProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final userProvider = context.read<UserProvider>();

    final score = _calculateRealFinancialHealthScore(
      userProvider.currentUser,
      financialProvider.activeUserPlan,
      transactionProvider.transactions
    );

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
                    color: color.withAlpha(25),
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

  int _calculateRealFinancialHealthScore(UserModel? user, UserBudgetPlan? plan, List transactions) {
    if (user == null || plan == null) return 0;

    int score = 50; // Base score

    // Calculate plan adherence
    final adherence = _calculatePlanAdherence(plan, transactions);
    score += (adherence * 30).round();

    // Savings progress
    if (plan.savingsGoal != null && plan.savingsGoal! > 0) {
      score += 10;
    }

    // Emergency fund (simplified)
    final monthlyIncome = plan.monthlyIncome;
    if (user.mpesaBalance >= monthlyIncome * 3) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  double _calculatePlanAdherence(UserBudgetPlan plan, List transactions) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));

    final monthlyTransactions = transactions.where((t) =>
      t.timestamp.isAfter(startOfMonth) && t.timestamp.isBefore(endOfMonth) && t.amount > 0
    ).toList();

    double totalSpent = 0;
    Map<String, double> categorySpending = {};

    for (final transaction in monthlyTransactions) {
      totalSpent += transaction.amount;
      final category = _categorizeTransaction(transaction);
      categorySpending[category] = (categorySpending[category] ?? 0) + transaction.amount;
    }

    // Calculate adherence based on category allocations
    double adherenceScore = 0;
    int categoriesWithData = 0;

    for (final allocation in plan.allocations.entries) {
      if (allocation.value > 0) {
        final spent = categorySpending[allocation.key] ?? 0;
        final allocated = allocation.value;
        final adherence = (spent <= allocated) ? 1.0 : (allocated / spent).clamp(0.0, 1.0);
        adherenceScore += adherence;
        categoriesWithData++;
      }
    }

    return categoriesWithData > 0 ? adherenceScore / categoriesWithData : 0.0;
  }

  String _categorizeTransaction(dynamic transaction) {
    // Simple categorization based on recipient
    final recipient = transaction.recipient.toLowerCase();
    if (recipient.contains('food') || recipient.contains('restaurant')) return 'Food & Groceries';
    if (recipient.contains('transport') || recipient.contains('matatu')) return 'Transport';
    if (recipient.contains('airtime') || recipient.contains('safaricom')) return 'Airtime & Data';
    return 'Miscellaneous';
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

class _PlanProgressCard extends StatelessWidget {
  const _PlanProgressCard();

  @override
  Widget build(BuildContext context) {
    final financialProvider = context.watch<FinancialProvider>();
    final plan = financialProvider.activeUserPlan;

    if (plan == null) return const SizedBox.shrink();

    final progress = _calculatePlanProgress(plan);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan Progress', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.8 ? Colors.green : progress > 0.5 ? Colors.orange : Colors.red
              ),
            ),
            const SizedBox(height: 8),
            Text('${(progress * 100).toStringAsFixed(1)}% of monthly plan completed'),
          ],
        ),
      ),
    );
  }

  double _calculatePlanProgress(UserBudgetPlan plan) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth = now.day;

    return dayOfMonth / daysInMonth;
  }
}

class _PlanVsActualSpendingCard extends StatelessWidget {
  const _PlanVsActualSpendingCard();

  @override
  Widget build(BuildContext context) {
    final financialProvider = context.watch<FinancialProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final plan = financialProvider.activeUserPlan;

    if (plan == null) return const SizedBox.shrink();

    final categoryAnalysis = _analyzeCategoryPerformance(plan, transactionProvider.transactions);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budget Performance', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...categoryAnalysis.map((analysis) => _CategoryPerformanceItem(
              category: analysis['category'],
              allocated: analysis['allocated'],
              spent: analysis['spent'],
              status: analysis['status'],
            )),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _analyzeCategoryPerformance(UserBudgetPlan plan, List transactions) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final monthlyTransactions = transactions.where((t) =>
      t.timestamp.isAfter(startOfMonth) && t.amount > 0
    ).toList();

    Map<String, double> categorySpending = {};

    for (final transaction in monthlyTransactions) {
      final category = _categorizeTransaction(transaction);
      categorySpending[category] = (categorySpending[category] ?? 0) + transaction.amount;
    }

    List<Map<String, dynamic>> analysis = [];

    for (final allocation in plan.allocations.entries) {
      if (allocation.value > 0) {
        final spent = categorySpending[allocation.key] ?? 0;
        final status = spent <= allocation.value ? 'On Track' : 'Over Budget';

        analysis.add({
          'category': allocation.key,
          'allocated': allocation.value,
          'spent': spent,
          'status': status,
        });
      }
    }

    return analysis;
  }

  String _categorizeTransaction(dynamic transaction) {
    final recipient = transaction.recipient.toLowerCase();
    if (recipient.contains('food') || recipient.contains('restaurant')) return 'Food & Groceries';
    if (recipient.contains('transport') || recipient.contains('matatu')) return 'Transport';
    if (recipient.contains('airtime') || recipient.contains('safaricom')) return 'Airtime & Data';
    return 'Miscellaneous';
  }
}

class _UserBudgetPlanSummaryCard extends StatelessWidget {
  final UserBudgetPlan plan;

  const _UserBudgetPlanSummaryCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final allocatedCategories = plan.allocations.entries
        .where((entry) => entry.value > 0)
        .take(3) // Show only top 3 categories
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your Budget Plan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plan.planName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _BudgetItem(
                    label: 'Monthly Income',
                    amount: plan.monthlyIncome,
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BudgetItem(
                    label: 'Allocated',
                    amount: plan.totalAllocated,
                    icon: Icons.pie_chart,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (allocatedCategories.isNotEmpty) ...[
              const Text(
                'Top Categories:',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...allocatedCategories.map((entry) {
                final percentage = plan.monthlyIncome > 0
                    ? (entry.value / plan.monthlyIncome * 100)
                    : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        'KES ${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(0)}%)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/financial-planning',
                ),
                icon: const Icon(Icons.visibility),
                label: const Text('View Full Plan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoBudgetPlanCard extends StatelessWidget {
  const _NoBudgetPlanCard();

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
                Icon(Icons.account_balance_wallet_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Budget Plan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'No budget plan created',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create a personalized budget plan to better manage your finances and track your spending goals.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/budget-creation'),
                icon: const Icon(Icons.add),
                label: const Text('Create Budget Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateNewPlanCard extends StatelessWidget {
  const _CreateNewPlanCard();

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
                Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New Plan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Want to create a different budget plan? Start fresh with new goals and allocations.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/budget-creation'),
                icon: const Icon(Icons.add),
                label: const Text('Create New Plan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPerformanceItem extends StatelessWidget {
  final String category;
  final double allocated;
  final double spent;
  final String status;

  const _CategoryPerformanceItem({
    required this.category,
    required this.allocated,
    required this.spent,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isOverBudget = status == 'Over Budget';
    final color = isOverBudget ? Colors.red : Colors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                Text('Allocated: KES ${allocated.toStringAsFixed(0)} | Spent: KES ${spent.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color),
            ),
            child: Text(
              status,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalizedRecommendationsCard extends StatelessWidget {
  const _PersonalizedRecommendationsCard();

  @override
  Widget build(BuildContext context) {
    final financialProvider = context.watch<FinancialProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final plan = financialProvider.activeUserPlan;

    if (plan == null) return const SizedBox.shrink();

    final recommendations = _generatePersonalizedRecommendations(plan, transactionProvider.transactions);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Personalized Insights', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(rec, style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  List<String> _generatePersonalizedRecommendations(UserBudgetPlan plan, List transactions) {
    List<String> recommendations = [];

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final monthlyTransactions = transactions.where((t) =>
      t.timestamp.isAfter(startOfMonth) && t.amount > 0
    ).toList();

    Map<String, double> categorySpending = {};

    for (final transaction in monthlyTransactions) {
      final category = _categorizeTransaction(transaction);
      categorySpending[category] = (categorySpending[category] ?? 0) + transaction.amount;
    }

    // Check for over-budget categories
    for (final allocation in plan.allocations.entries) {
      if (allocation.value > 0) {
        final spent = categorySpending[allocation.key] ?? 0;
        if (spent > allocation.value) {
          final overBy = spent - allocation.value;
          recommendations.add('You\'re KES ${overBy.toStringAsFixed(0)} over budget in ${allocation.key}. Consider reducing spending in this category.');
        }
      }
    }

    // Check savings progress
    if (plan.savingsGoal != null && plan.savingsGoal! > 0) {
      final monthlySavingsTarget = plan.savingsGoal! / (plan.savingsPeriodMonths ?? 12);
      final remaining = plan.monthlyIncome - plan.totalAllocated;
      if (remaining < monthlySavingsTarget) {
        recommendations.add('Your savings target requires KES ${monthlySavingsTarget.toStringAsFixed(0)}/month, but you only have KES ${remaining.toStringAsFixed(0)} left after allocations.');
      }
    }

    // General recommendations if none specific
    if (recommendations.isEmpty) {
      recommendations.add('Great job staying within your budget! Keep monitoring your spending patterns.');
      if (plan.savingsGoal == null) {
        recommendations.add('Consider setting a savings goal to build your emergency fund.');
      }
    }

    return recommendations;
  }

  String _categorizeTransaction(dynamic transaction) {
    final recipient = transaction.recipient.toLowerCase();
    if (recipient.contains('food') || recipient.contains('restaurant')) return 'Food & Groceries';
    if (recipient.contains('transport') || recipient.contains('matatu')) return 'Transport';
    if (recipient.contains('airtime') || recipient.contains('safaricom')) return 'Airtime & Data';
    return 'Miscellaneous';
  }
}
