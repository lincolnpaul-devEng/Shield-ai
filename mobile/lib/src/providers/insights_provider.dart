import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/spending_plan.dart';
import '../services/insights_service.dart';

class InsightsProvider extends ChangeNotifier {
  final InsightsService _insightsService;

  List<FinancialInsights> _insights = [];
  bool _isLoading = false;
  String? _error;

  InsightsProvider(this._insightsService);

  List<FinancialInsights> get insights => _insights;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Generate insights from transaction data
  Future<void> generateInsights(
    List<TransactionModel> transactions, {
    SpendingPlan? spendingPlan,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _insights = await _insightsService.generateInsights(
        transactions,
        spendingPlan: spendingPlan,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _insights = [];
      if (kDebugMode) {
        print('Insights generation error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh insights with new data
  Future<void> refreshInsights(
    List<TransactionModel> transactions, {
    SpendingPlan? spendingPlan,
  }) async {
    await generateInsights(transactions, spendingPlan: spendingPlan);
  }

  /// Clear all insights
  void clearInsights() {
    _insights = [];
    _error = null;
    notifyListeners();
  }

  /// Get insights by priority
  List<FinancialInsights> getInsightsByPriority(InsightPriority priority) {
    return _insights.where((insight) => insight.priority == priority).toList();
  }

  /// Get insights by category
  List<FinancialInsights> getInsightsByCategory(String category) {
    return _insights.where((insight) => insight.category == category).toList();
  }

  /// Get critical insights only
  List<FinancialInsights> get criticalInsights =>
    getInsightsByPriority(InsightPriority.critical);

  /// Get high priority insights
  List<FinancialInsights> get highPriorityInsights =>
    getInsightsByPriority(InsightPriority.high);

  /// Get medium priority insights
  List<FinancialInsights> get mediumPriorityInsights =>
    getInsightsByPriority(InsightPriority.medium);

  /// Get low priority insights
  List<FinancialInsights> get lowPriorityInsights =>
    getInsightsByPriority(InsightPriority.low);

  /// Check if there are any insights available
  bool get hasInsights => _insights.isNotEmpty;

  /// Get the count of insights by priority
  int getInsightCount(InsightPriority priority) =>
    getInsightsByPriority(priority).length;

  /// Get top insights (first n insights)
  List<FinancialInsights> getTopInsights(int count) =>
    _insights.take(count).toList();
}