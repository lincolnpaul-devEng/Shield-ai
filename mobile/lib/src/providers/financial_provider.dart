import 'package:flutter/foundation.dart';
import '../models/spending_plan.dart';
import '../models/transaction.dart';
import '../models/financial_enhancements.dart';
import '../services/financial_strategist.dart';

class FinancialProvider extends ChangeNotifier {
  final FinancialStrategist _strategist;

  SpendingPlan? _currentPlan;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastGenerated;

  // Enhanced features state
  List<ConversationMessage> _conversations = [];
  List<SpendingPrediction> _predictions = [];
  List<SpendingAnomaly> _anomalies = [];
  List<SmartSuggestion> _suggestions = [];
  List<PlanRefinement> _refinements = [];

  FinancialProvider(this._strategist);

  // Getters
  SpendingPlan? get currentPlan => _currentPlan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastGenerated => _lastGenerated;
  bool get hasPlan => _currentPlan != null;

  // Enhanced features getters
  List<ConversationMessage> get conversations => _conversations;
  List<SpendingPrediction> get predictions => _predictions;
  List<SpendingAnomaly> get anomalies => _anomalies;
  List<SmartSuggestion> get suggestions => _suggestions;
  List<PlanRefinement> get refinements => _refinements;

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

  // Enhanced AI Features

  Future<void> askQuestion(String question, List<TransactionModel> transactions) async {
    if (_currentPlan == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final message = await _strategist.askQuestion(question, _currentPlan!, transactions);
      _conversations.add(message);
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error asking question: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refinePlan(String userFeedback, List<TransactionModel> transactions) async {
    if (_currentPlan == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final refinedPlan = await _strategist.refinePlan(_currentPlan!, userFeedback, transactions);
      _currentPlan = refinedPlan;
      _refinements.add(PlanRefinement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userFeedback: userFeedback,
        adjustments: {},
        timestamp: DateTime.now(),
        applied: true,
      ));
      _lastGenerated = DateTime.now();
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error refining plan: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generatePredictions(List<TransactionModel> transactions, int monthsAhead) async {
    _isLoading = true;
    notifyListeners();

    try {
      _predictions = await _strategist.predictSpending(transactions, monthsAhead);
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error generating predictions: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> detectAnomalies(List<TransactionModel> transactions) async {
    if (_currentPlan == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _anomalies = await _strategist.detectAnomalies(transactions, _currentPlan!);
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error detecting anomalies: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateSmartSuggestions(
    List<TransactionModel> transactions,
    double currentBalance,
  ) async {
    if (_currentPlan == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _suggestions = await _strategist.generateSmartSuggestions(
        transactions,
        _currentPlan!,
        currentBalance,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error generating suggestions: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void markSuggestionImplemented(String suggestionId) {
    final index = _suggestions.indexWhere((s) => s.id == suggestionId);
    if (index != -1) {
      _suggestions[index] = SmartSuggestion(
        id: _suggestions[index].id,
        title: _suggestions[index].title,
        description: _suggestions[index].description,
        category: _suggestions[index].category,
        potentialSavings: _suggestions[index].potentialSavings,
        priority: _suggestions[index].priority,
        suggestedDate: _suggestions[index].suggestedDate,
        isImplemented: true,
      );
      notifyListeners();
    }
  }

  void clearConversations() {
    _conversations.clear();
    notifyListeners();
  }

  void clearAnomalies() {
    _anomalies.clear();
    notifyListeners();
  }
}