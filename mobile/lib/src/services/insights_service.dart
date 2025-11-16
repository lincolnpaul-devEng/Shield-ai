import '../models/transaction.dart';
import '../models/spending_plan.dart';

class FinancialInsights {
  final String title;
  final String description;
  final String category;
  final double? value;
  final String? recommendation;
  final InsightPriority priority;

  const FinancialInsights({
    required this.title,
    required this.description,
    required this.category,
    this.value,
    this.recommendation,
    this.priority = InsightPriority.medium,
  });
}

enum InsightPriority { low, medium, high, critical }

class SpendingPattern {
  final String category;
  final double totalAmount;
  final int transactionCount;
  final double averageAmount;
  final DateTime firstTransaction;
  final DateTime lastTransaction;

  const SpendingPattern({
    required this.category,
    required this.totalAmount,
    required this.transactionCount,
    required this.averageAmount,
    required this.firstTransaction,
    required this.lastTransaction,
  });
}

class InsightsService {
  static const int _analysisDays = 30; // Analyze last 30 days

  /// Generate comprehensive financial insights from transaction history
  Future<List<FinancialInsights>> generateInsights(
    List<TransactionModel> transactions, {
    SpendingPlan? spendingPlan,
  }) async {
    final insights = <FinancialInsights>[];

    if (transactions.isEmpty) {
      insights.add(const FinancialInsights(
        title: 'Welcome to Shield AI!',
        description: 'Start making transactions to receive personalized financial insights.',
        category: 'welcome',
        priority: InsightPriority.low,
      ));
      return insights;
    }

    // Analyze spending patterns
    insights.addAll(_analyzeSpendingPatterns(transactions));

    // Analyze transaction frequency
    insights.addAll(_analyzeTransactionFrequency(transactions));

    // Analyze unusual spending
    insights.addAll(_analyzeUnusualSpending(transactions));

    // Analyze budget compliance (if plan exists)
    if (spendingPlan != null) {
      insights.addAll(_analyzeBudgetCompliance(transactions, spendingPlan));
    }

    // Analyze time-based patterns
    insights.addAll(_analyzeTimePatterns(transactions));

    // Analyze recipient patterns
    insights.addAll(_analyzeRecipientPatterns(transactions));

    // Sort by priority (critical first)
    insights.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    return insights.take(10).toList(); // Return top 10 insights
  }

  /// Analyze spending patterns and categorize transactions
  List<FinancialInsights> _analyzeSpendingPatterns(List<TransactionModel> transactions) {
    final insights = <FinancialInsights>[];
    final patterns = _categorizeTransactions(transactions);

    if (patterns.isEmpty) return insights;

    // Find highest spending category
    final highestCategory = patterns.reduce((a, b) =>
      a.totalAmount > b.totalAmount ? a : b);

    if (highestCategory.totalAmount > 5000) { // Significant amount
      insights.add(FinancialInsights(
        title: 'Highest Spending: ${highestCategory.category}',
        description: 'You spent KSH ${highestCategory.totalAmount.toStringAsFixed(0)} '
            'on ${highestCategory.category.toLowerCase()} in the last $_analysisDays days.',
        category: 'spending_pattern',
        value: highestCategory.totalAmount,
        recommendation: _getCategoryRecommendation(highestCategory.category),
        priority: InsightPriority.medium,
      ));
    }

    // Analyze spending distribution
    final totalSpending = patterns.fold(0.0, (sum, p) => sum + p.totalAmount);
    final topCategories = patterns.take(3);

    if (topCategories.length >= 2) {
      final topTwoTotal = topCategories.take(2).fold(0.0, (sum, p) => sum + p.totalAmount);
      final concentrationRatio = topTwoTotal / totalSpending;

      if (concentrationRatio > 0.7) { // 70%+ in top 2 categories
        insights.add(const FinancialInsights(
          title: 'Spending Concentration',
          description: 'Most of your spending is concentrated in just a few categories. '
              'Consider diversifying your spending patterns.',
          category: 'diversification',
          recommendation: 'Try to balance spending across different categories for better financial health.',
          priority: InsightPriority.medium,
        ));
      }
    }

    return insights;
  }

  /// Analyze transaction frequency patterns
  List<FinancialInsights> _analyzeTransactionFrequency(List<TransactionModel> transactions) {
    final insights = <FinancialInsights>[];
    final recentTransactions = _getRecentTransactions(transactions);

    if (recentTransactions.length < 5) return insights;

    // Calculate daily transaction frequency
    final daysSpan = _analysisDays;
    final dailyAverage = recentTransactions.length / daysSpan;

    if (dailyAverage > 3) {
      insights.add(FinancialInsights(
        title: 'High Transaction Frequency',
        description: 'You make an average of ${dailyAverage.toStringAsFixed(1)} transactions per day.',
        category: 'frequency',
        value: dailyAverage,
        recommendation: 'Consider consolidating smaller transactions to reduce fees.',
        priority: InsightPriority.medium,
      ));
    } else if (dailyAverage < 0.5) {
      insights.add(FinancialInsights(
        title: 'Low Transaction Activity',
        description: 'You make less than 1 transaction every 2 days on average.',
        category: 'frequency',
        value: dailyAverage,
        recommendation: 'Regular small transactions can help establish spending patterns for better fraud detection.',
        priority: InsightPriority.low,
      ));
    }

    return insights;
  }

  /// Analyze unusual spending patterns
  List<FinancialInsights> _analyzeUnusualSpending(List<TransactionModel> transactions) {
    final insights = <FinancialInsights>[];
    final recentTransactions = _getRecentTransactions(transactions);

    if (recentTransactions.length < 10) return insights;

    // Calculate average transaction amount
    final amounts = recentTransactions.map((t) => t.amount.abs()).toList();
    final averageAmount = amounts.reduce((a, b) => a + b) / amounts.length;

    // Find transactions significantly above average
    final largeTransactions = recentTransactions.where((t) =>
      t.amount.abs() > averageAmount * 2).toList();

    if (largeTransactions.isNotEmpty) {
      final totalLargeAmount = largeTransactions.fold(0.0, (sum, t) => sum + t.amount.abs());
      final percentage = (totalLargeAmount / amounts.fold(0.0, (sum, a) => sum + a)) * 100;

      if (percentage > 30) {
        insights.add(FinancialInsights(
          title: 'Large Transaction Pattern',
          description: '${percentage.toStringAsFixed(0)}% of your spending is in large transactions.',
          category: 'unusual_spending',
          value: percentage,
          recommendation: 'Large transactions may indicate special occasions. Ensure they are legitimate.',
          priority: InsightPriority.high,
        ));
      }
    }

    return insights;
  }

  /// Analyze budget compliance
  List<FinancialInsights> _analyzeBudgetCompliance(
    List<TransactionModel> transactions,
    SpendingPlan spendingPlan,
  ) {
    final insights = <FinancialInsights>[];
    final recentTransactions = _getRecentTransactions(transactions);
    final weeklySpending = _calculateWeeklySpending(recentTransactions);

    if (weeklySpending > spendingPlan.weeklyBudget) {
      final overBudget = weeklySpending - spendingPlan.weeklyBudget;
      final percentage = (overBudget / spendingPlan.weeklyBudget) * 100;

      insights.add(FinancialInsights(
        title: 'Over Weekly Budget',
        description: 'You are KSH ${overBudget.toStringAsFixed(0)} (${percentage.toStringAsFixed(0)}%) over your weekly budget.',
        category: 'budget',
        value: overBudget,
        recommendation: 'Consider reducing discretionary spending or adjusting your budget.',
        priority: InsightPriority.high,
      ));
    } else if (weeklySpending < spendingPlan.weeklyBudget * 0.5) {
      insights.add(FinancialInsights(
        title: 'Under Budget',
        description: 'You are well under your weekly budget. Consider increasing savings or planned spending.',
        category: 'budget',
        recommendation: 'You have room in your budget for additional planned expenses or savings.',
        priority: InsightPriority.low,
      ));
    }

    return insights;
  }

  /// Analyze time-based spending patterns
  List<FinancialInsights> _analyzeTimePatterns(List<TransactionModel> transactions) {
    final insights = <FinancialInsights>[];
    final recentTransactions = _getRecentTransactions(transactions);

    // Group by hour of day
    final hourlySpending = <int, double>{};
    for (final transaction in recentTransactions) {
      final hour = transaction.timestamp.hour;
      hourlySpending[hour] = (hourlySpending[hour] ?? 0) + transaction.amount.abs();
    }

    if (hourlySpending.isNotEmpty) {
      final peakHour = hourlySpending.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      final peakAmount = hourlySpending[peakHour]!;

      if (peakHour >= 22 || peakHour <= 4) { // Late night/early morning
        insights.add(FinancialInsights(
          title: 'Late Night Spending',
          description: 'You spend most during late night hours ($peakHour:00).',
          category: 'time_pattern',
          value: peakAmount,
          recommendation: 'Late night transactions may be more vulnerable to fraud. Stay vigilant.',
          priority: InsightPriority.medium,
        ));
      }
    }

    return insights;
  }

  /// Analyze recipient patterns
  List<FinancialInsights> _analyzeRecipientPatterns(List<TransactionModel> transactions) {
    final insights = <FinancialInsights>[];
    final recentTransactions = _getRecentTransactions(transactions);

    // Count transactions per recipient
    final recipientCounts = <String, int>{};
    for (final transaction in recentTransactions) {
      recipientCounts[transaction.recipient] = (recipientCounts[transaction.recipient] ?? 0) + 1;
    }

    if (recipientCounts.isNotEmpty) {
      final topRecipient = recipientCounts.entries.reduce((a, b) => a.value > b.value ? a : b);

      if (topRecipient.value > recentTransactions.length * 0.3) { // 30%+ to one recipient
        insights.add(FinancialInsights(
          title: 'Frequent Recipient',
          description: '${(topRecipient.value / recentTransactions.length * 100).toStringAsFixed(0)}% of transactions go to ${topRecipient.key}.',
          category: 'recipient_pattern',
          value: topRecipient.value.toDouble(),
          recommendation: 'Diversify your transaction recipients to reduce risk concentration.',
          priority: InsightPriority.medium,
        ));
      }
    }

    return insights;
  }

  /// Categorize transactions by type
  List<SpendingPattern> _categorizeTransactions(List<TransactionModel> transactions) {
    final categories = <String, List<TransactionModel>>{};
    final patterns = <SpendingPattern>[];

    for (final transaction in transactions) {
      final category = _categorizeTransaction(transaction);
      categories.putIfAbsent(category, () => []).add(transaction);
    }

    for (final entry in categories.entries) {
      final categoryTransactions = entry.value;
      final totalAmount = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount.abs());
      final averageAmount = totalAmount / categoryTransactions.length;

      patterns.add(SpendingPattern(
        category: entry.key,
        totalAmount: totalAmount,
        transactionCount: categoryTransactions.length,
        averageAmount: averageAmount,
        firstTransaction: categoryTransactions.map((t) => t.timestamp).reduce((a, b) => a.isBefore(b) ? a : b),
        lastTransaction: categoryTransactions.map((t) => t.timestamp).reduce((a, b) => a.isAfter(b) ? a : b),
      ));
    }

    return patterns..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
  }

  /// Categorize a single transaction
  String _categorizeTransaction(TransactionModel transaction) {
    final recipient = transaction.recipient.toLowerCase();

    // Food & Dining
    if (recipient.contains('restaurant') || recipient.contains('hotel') ||
        recipient.contains('food') || recipient.contains('cafe') ||
        recipient.contains('lunch') || recipient.contains('dinner')) {
      return 'Food & Dining';
    }

    // Transport
    if (recipient.contains('matatu') || recipient.contains('taxi') ||
        recipient.contains('uber') || recipient.contains('bolt') ||
        recipient.contains('transport') || recipient.contains('bus')) {
      return 'Transport';
    }

    // Airtime & Data
    if (recipient.contains('airtime') || recipient.contains('data') ||
        recipient.contains('safaricom') || recipient.contains('telkom') ||
        recipient.contains('airtel')) {
      return 'Airtime & Data';
    }

    // Shopping
    if (recipient.contains('shop') || recipient.contains('store') ||
        recipient.contains('mall') || recipient.contains('supermarket') ||
        recipient.contains('market')) {
      return 'Shopping';
    }

    // Utilities
    if (recipient.contains('kplc') || recipient.contains('electricity') ||
        recipient.contains('water') || recipient.contains('utility')) {
      return 'Utilities';
    }

    // Entertainment
    if (recipient.contains('movie') || recipient.contains('cinema') ||
        recipient.contains('game') || recipient.contains('entertainment') ||
        recipient.contains('betting') || recipient.contains('lottery')) {
      return 'Entertainment';
    }

    // Healthcare
    if (recipient.contains('hospital') || recipient.contains('clinic') ||
        recipient.contains('pharmacy') || recipient.contains('medical')) {
      return 'Healthcare';
    }

    // Education
    if (recipient.contains('school') || recipient.contains('university') ||
        recipient.contains('college') || recipient.contains('education')) {
      return 'Education';
    }

    return 'Other';
  }

  /// Get recommendation for spending category
  String _getCategoryRecommendation(String category) {
    switch (category) {
      case 'Food & Dining':
        return 'Consider cooking at home more often to save money.';
      case 'Transport':
        return 'Try using public transport or walking for shorter distances.';
      case 'Airtime & Data':
        return 'Consider family bundles or WiFi-only plans.';
      case 'Entertainment':
        return 'Look for free or low-cost entertainment alternatives.';
      case 'Shopping':
        return 'Plan purchases in advance and compare prices.';
      default:
        return 'Track your spending in this category to identify savings opportunities.';
    }
  }

  /// Get recent transactions (last 30 days)
  List<TransactionModel> _getRecentTransactions(List<TransactionModel> transactions) {
    final cutoffDate = DateTime.now().subtract(const Duration(days: _analysisDays));
    return transactions.where((t) => t.timestamp.isAfter(cutoffDate)).toList();
  }

  /// Calculate weekly spending from transactions
  double _calculateWeeklySpending(List<TransactionModel> transactions) {
    final weeklyTransactions = transactions.where((t) {
      final daysSinceTransaction = DateTime.now().difference(t.timestamp).inDays;
      return daysSinceTransaction <= 7;
    }).toList();

    return weeklyTransactions.fold(0.0, (sum, t) => sum + t.amount.abs());
  }

}