import 'package:flutter/foundation.dart';
import '../models/spending_plan.dart';
import '../models/transaction.dart';
import '../services/financial_strategist.dart';

class FinancialProvider extends ChangeNotifier {
  final FinancialStrategist _strategist;

  SpendingPlan? _currentPlan;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastGenerated;

  FinancialProvider(this._strategist);

  // Getters
  SpendingPlan? get currentPlan => _currentPlan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastGenerated => _lastGenerated;
  bool get hasPlan => _currentPlan != null;

  /// Generate a new spending plan based on transaction history
  Future<void> generateSpendingPlan(
    List<TransactionModel> transactions,
    double currentBalance,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentPlan = await _strategist.generateSpendingPlan(
        transactions,
        currentBalance,
      );
      _lastGenerated = DateTime.now();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _currentPlan = null;
      if (kDebugMode) {
        print('Error generating spending plan: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh the current spending plan
  Future<void> refreshPlan(
    List<TransactionModel> transactions,
    double currentBalance,
  ) async {
    await generateSpendingPlan(transactions, currentBalance);
  }

  /// Clear the current plan
  void clearPlan() {
    _currentPlan = null;
    _error = null;
    _lastGenerated = null;
    notifyListeners();
  }

  /// Check if plan needs refreshing (older than 7 days)
  bool get shouldRefresh {
    if (_lastGenerated == null) return true;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _lastGenerated!.isBefore(sevenDaysAgo);
  }

  // Helper methods for UI
  double get weeklyBudget => _currentPlan?.weeklyBudget.toDouble() ?? 0.0;
  double get monthlyBudget => _currentPlan?.monthlyBudget.toDouble() ?? 0.0;

  List<SpendingCategory> get essentialCategories =>
      _currentPlan?.getEssentialCategories() ?? [];

  List<SpendingCategory> get discretionaryCategories =>
      _currentPlan?.getDiscretionaryCategories() ?? [];

  List<SpendingCategory> get savingsCategories =>
      _currentPlan?.getSavingsCategories() ?? [];

  int get financialHealthScore => _currentPlan?.financialHealthScore ?? 50;

  List<String> get recommendations => _currentPlan?.recommendations ?? [];
  List<String> get wasteAlerts => _currentPlan?.wasteAlerts ?? [];
  List<String> get savingsTips => _currentPlan?.savingsTips ?? [];
  List<String> get fraudRisks => _currentPlan?.fraudRisks ?? [];

  String get healthScoreDescription {
    final score = financialHealthScore;
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Improvement';
  }

  String get healthScoreAdvice {
    final score = financialHealthScore;
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