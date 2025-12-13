import 'package:flutter/foundation.dart';
import '../models/spending_plan.dart';
import '../models/transaction.dart';
import '../models/financial_enhancements.dart';
import '../models/user_budget_plan.dart';
import '../services/financial_strategist.dart';
import '../services/api_service.dart';

class FinancialProvider extends ChangeNotifier {
  final FinancialStrategist _strategist;
  final ApiService _apiService;

  SpendingPlan? _currentPlan;
  bool _isLoading = false;
  bool _isTyping = false;
  String? _error;
  DateTime? _lastGenerated;

  // Enhanced features state
  final List<ConversationMessage> _conversations = [];
  List<SpendingPrediction> _predictions = [];
  List<SpendingAnomaly> _anomalies = [];
  List<SmartSuggestion> _suggestions = [];
  final List<PlanRefinement> _refinements = [];

  // User budget plans
  List<UserBudgetPlan> _userPlans = [];
  UserBudgetPlan? _activeUserPlan;
  List<BudgetTemplate> _budgetTemplates = [];

  FinancialProvider(this._strategist, this._apiService);

  // Getters
  SpendingPlan? get currentPlan => _currentPlan;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;
  String? get error => _error;
  DateTime? get lastGenerated => _lastGenerated;
  bool get hasPlan => _currentPlan != null;

  // Enhanced features getters
  List<ConversationMessage> get conversations => _conversations;
  List<SpendingPrediction> get predictions => _predictions;
  List<SpendingAnomaly> get anomalies => _anomalies;
  List<SmartSuggestion> get suggestions => _suggestions;
  List<PlanRefinement> get refinements => _refinements;

  // User budget plan getters
  List<UserBudgetPlan> get userPlans => _userPlans;
  UserBudgetPlan? get activeUserPlan => _activeUserPlan;
  List<BudgetTemplate> get budgetTemplates => _budgetTemplates;
  bool get hasUserPlan => _activeUserPlan != null;

  /// Generate a new spending plan based on transaction history
  Future<void> generateSpendingPlan(
    List<TransactionModel> transactions,
    double currentBalance,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement spending plan generation through backend API
      // For now, create a basic plan
      _currentPlan = SpendingPlan(
        weeklyBudget: 2500,
        monthlyBudget: 10000,
        categories: [
          SpendingCategory(
            name: 'Food & Groceries',
            allocated: 1500,
            recommended: 1200,
            category: 'essential',
            description: 'Daily meals and household groceries',
          ),
          SpendingCategory(
            name: 'Transport',
            allocated: 800,
            recommended: 600,
            category: 'essential',
            description: 'Local transport and fares',
          ),
          SpendingCategory(
            name: 'Airtime & Data',
            allocated: 500,
            recommended: 400,
            category: 'essential',
            description: 'Mobile phone and internet costs',
          ),
          SpendingCategory(
            name: 'Entertainment',
            allocated: 700,
            recommended: 300,
            category: 'discretionary',
            description: 'Movies, games, and leisure activities',
          ),
          SpendingCategory(
            name: 'Savings',
            allocated: 1000,
            recommended: 1500,
            category: 'savings',
            description: 'Emergency fund and future goals',
          ),
        ],
        wasteAlerts: ['Unable to analyze spending patterns'],
        savingsTips: [
          'Track your expenses daily',
          'Set savings goals',
          'Reduce impulse purchases',
        ],
        fraudRisks: ['Monitor for unusual spending patterns'],
        financialHealthScore: 75,
        recommendations: [
          'Build emergency fund to cover 3 months of expenses',
          'Reduce discretionary spending by 30%',
          'Increase savings rate to 20% of income',
        ],
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

  Future<void> askQuestion(String question, String userId) async {
    // Add user message immediately
    final userMessage = ConversationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: question,
      answer: '',
      timestamp: DateTime.now(),
      isFromUser: true,
    );
    _conversations.add(userMessage);
    _isTyping = true;
    notifyListeners();

    try {
      final aiMessage = await _strategist.askQuestion(question, userId);
      _conversations.add(aiMessage);
      _error = null;
    } catch (e) {
      // Add error message as AI response
      final errorMessage = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        question: question,
        answer: 'I apologize, but I\'m unable to answer your question right now. Please try again later.',
        timestamp: DateTime.now(),
        isFromUser: false,
      );
      _conversations.add(errorMessage);
      _error = e.toString();
      if (kDebugMode) {
        print('Error asking question: $e');
      }
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> refinePlan(String userFeedback, List<TransactionModel> transactions) async {
    if (_currentPlan == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement plan refinement through backend API
      // For now, just record the refinement request
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
      // TODO: Implement predictions through backend API
      _predictions = [];
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
      // TODO: Implement anomaly detection through backend API
      _anomalies = [];
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
      // TODO: Implement smart suggestions through backend API
      _suggestions = [];
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

  // User Budget Plan Methods

  Future<void> loadUserPlans(String userId, String pin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/users/$userId/budget-plans?pin=$pin');
      final plansData = response['plans'] as List;
      _userPlans = plansData.map((plan) => UserBudgetPlan.fromJson(plan)).toList();

      // Find active plan
      _activeUserPlan = _userPlans.where((plan) => plan.isActive).firstOrNull;

      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading user plans: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUserPlan(UserBudgetPlan plan, String userId, String pin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final planData = plan.toJson();
      planData['pin'] = pin;

      final response = await _apiService.post('/users/$userId/budget-plans', planData);
      final createdPlan = UserBudgetPlan.fromJson(response);

      _userPlans.add(createdPlan);
      if (createdPlan.isActive) {
        _activeUserPlan = createdPlan;
      }

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error creating user plan: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserPlan(UserBudgetPlan plan, String userId, String pin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final planData = plan.toJson();
      planData['pin'] = pin;

      final response = await _apiService.put('/users/$userId/budget-plans/${plan.id}', planData);
      final updatedPlan = UserBudgetPlan.fromJson(response);

      final index = _userPlans.indexWhere((p) => p.id == plan.id);
      if (index != -1) {
        _userPlans[index] = updatedPlan;
        if (updatedPlan.isActive) {
          _activeUserPlan = updatedPlan;
        } else if (_activeUserPlan?.id == plan.id) {
          _activeUserPlan = null;
        }
      }

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error updating user plan: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteUserPlan(String planId, String userId, String pin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('/users/$userId/budget-plans/$planId?pin=$pin');

      _userPlans.removeWhere((plan) => plan.id == planId);
      if (_activeUserPlan?.id == planId) {
        _activeUserPlan = null;
      }

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error deleting user plan: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBudgetTemplates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/budget-templates');
      final templatesData = response['templates'] as List;
      _budgetTemplates = templatesData.map((template) => BudgetTemplate.fromJson(template)).toList();

      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading budget templates: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setActivePlan(String planId) {
    final plan = _userPlans.where((p) => p.id == planId).firstOrNull;
    if (plan != null) {
      _activeUserPlan = plan;
      notifyListeners();
    }
  }

  void clearUserPlans() {
    _userPlans.clear();
    _activeUserPlan = null;
    _budgetTemplates.clear();
    notifyListeners();
  }

  // SMS-based Transaction Analysis Methods

  Future<void> analyzeSmsTransactions(
    List<Map<String, dynamic>> smsTransactions,
    String userId,
    String pin,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final requestData = {
        'pin': pin,
        'sms_transactions': smsTransactions,
      };

      final response = await _apiService.post('/users/$userId/analyze-sms-transactions', requestData);

      // Update local state with results
      final anomaliesData = response['anomalies'] as List<dynamic>? ?? [];
      final predictionsData = response['predictions'] as List<dynamic>? ?? [];
      final suggestionsData = response['suggestions'] as List<dynamic>? ?? [];

      _anomalies = anomaliesData.map((a) => SpendingAnomaly.fromJson(a)).toList();
      _predictions = predictionsData.map((p) => SpendingPrediction.fromJson(p)).toList();
      _suggestions = suggestionsData.map((s) => SmartSuggestion.fromJson(s)).toList();

      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error analyzing SMS transactions: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> detectSmsAnomalies(
    List<Map<String, dynamic>> smsTransactions,
    String userId,
    String pin,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final requestData = {
        'pin': pin,
        'sms_transactions': smsTransactions,
      };

      final response = await _apiService.post('/users/$userId/sms-anomalies', requestData);

      final anomaliesData = response['anomalies'] as List<dynamic>? ?? [];
      _anomalies = anomaliesData.map((a) => SpendingAnomaly.fromJson(a)).toList();

      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error detecting SMS anomalies: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateSmsPredictions(
    List<Map<String, dynamic>> smsTransactions,
    String userId,
    String pin, {
    int monthsAhead = 3,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final requestData = {
        'pin': pin,
        'sms_transactions': smsTransactions,
        'months_ahead': monthsAhead,
      };

      final response = await _apiService.post('/users/$userId/sms-predictions', requestData);

      final predictionsData = response['predictions'] as List<dynamic>? ?? [];
      _predictions = predictionsData.map((p) => SpendingPrediction.fromJson(p)).toList();

      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error generating SMS predictions: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateSmsSuggestions(
    List<Map<String, dynamic>> smsTransactions,
    String userId,
    String pin,
    double currentBalance,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final requestData = {
        'pin': pin,
        'sms_transactions': smsTransactions,
        'current_balance': currentBalance,
      };

      final response = await _apiService.post('/users/$userId/sms-suggestions', requestData);

      final suggestionsData = response['suggestions'] as List<dynamic>? ?? [];
      _suggestions = suggestionsData.map((s) => SmartSuggestion.fromJson(s)).toList();

      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error generating SMS suggestions: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to convert SMS transactions to TransactionModel format
  List<Map<String, dynamic>> convertSmsToTransactionFormat(List<Map<String, dynamic>> smsTransactions) {
    return smsTransactions.map((sms) {
      return {
        'amount': sms['amount'],
        'recipient': sms['recipient'],
        'timestamp': sms['timestamp'],
        'balance_after': sms['balance_after'],
        'transaction_type': sms['transaction_type'],
        'is_incoming': sms['is_incoming'],
      };
    }).toList();
  }
}
