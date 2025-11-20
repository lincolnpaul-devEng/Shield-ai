import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import '../models/spending_plan.dart';
import '../models/financial_enhancements.dart';

class FinancialStrategist {
  final String apiKey;
  final String baseUrl;
  final String model;

  FinancialStrategist({
    required this.apiKey,
    this.baseUrl = 'https://openrouter.ai/api/v1/chat/completions',
    this.model = 'openai/gpt-4o-mini',
  });

  Future<SpendingPlan> generateSpendingPlan(
    List<TransactionModel> history,
    double currentBalance,
  ) async {
    final prompt = _buildFinancialPlanningPrompt(history, currentBalance);

    try {
      final response = await _callOpenRouter(prompt);
      return _parseSpendingPlanResponse(response);
    } catch (e) {
      // Return a basic fallback plan
      return _createFallbackPlan(history, currentBalance);
    }
  }

  String _buildFinancialPlanningPrompt(
    List<TransactionModel> history,
    double currentBalance,
  ) {
    final monthlyIncome = _calculateMonthlyIncome(history);
    final essentialSpending = _calculateEssentialSpending(history);
    final discretionarySpending = _calculateDiscretionarySpending(history);
    final savingsRate = _calculateSavingsRate(history, monthlyIncome);

    return """
As a financial advisor specializing in Kenyan M-Pesa users, analyze this spending history and create a smart spending plan that helps users manage their money better while protecting against fraud.

CURRENT BALANCE: KSH ${currentBalance.toStringAsFixed(0)}
MONTHLY INCOME ESTIMATE: KSH ${monthlyIncome.toStringAsFixed(0)}
ESSENTIAL SPENDING (30 days): KSH ${essentialSpending.toStringAsFixed(0)}
DISCRETIONARY SPENDING (30 days): KSH ${discretionarySpending.toStringAsFixed(0)}
CURRENT SAVINGS RATE: ${(savingsRate * 100).toStringAsFixed(1)}%

SPENDING HISTORY (Last 30 days):
${_formatTransactionHistory(history)}

KENYAN FINANCIAL CONTEXT:
- Average monthly income: KSH 15,000-50,000 for working professionals
- Essential expenses: Rent (30-40%), Food (15-20%), Transport (10-15%)
- Emergency fund target: 3-6 months of expenses
- Common fraud risks: Over-spending on entertainment, betting, impulse purchases

Create a personalized spending plan that:
1. Ensures essential bills are covered (rent, utilities, food, transport)
2. Allocates reasonable amounts for necessary expenses (airtime, data)
3. Suggests limits for discretionary spending (entertainment, dining out)
4. Recommends a realistic savings amount
5. Identifies potential wasteful spending patterns
6. Flags potential fraud risks in spending patterns

Respond ONLY with valid JSON in this exact format:
{
  "weekly_budget": 2500,
  "monthly_budget": 10000,
  "categories": [
    {
      "name": "Food & Groceries",
      "allocated": 1500,
      "recommended": 1200,
      "category": "essential",
      "description": "Daily meals and household groceries"
    },
    {
      "name": "Transport",
      "allocated": 800,
      "recommended": 600,
      "category": "essential",
      "description": "Matatu fare and local transport"
    },
    {
      "name": "Airtime & Data",
      "allocated": 500,
      "recommended": 400,
      "category": "essential",
      "description": "Mobile phone and internet costs"
    },
    {
      "name": "Entertainment",
      "allocated": 700,
      "recommended": 300,
      "category": "discretionary",
      "description": "Movies, games, and leisure activities"
    },
    {
      "name": "Savings",
      "allocated": 1000,
      "recommended": 1500,
      "category": "savings",
      "description": "Emergency fund and future goals"
    }
  ],
  "waste_alerts": [
    "High spending on betting and lottery",
    "Frequent dining out expenses",
    "Multiple small entertainment purchases"
  ],
  "savings_tips": [
    "Reduce airtime by using WiFi calling apps",
    "Cook at home 3 more times per week",
    "Use public transport instead of ride-hailing"
  ],
  "fraud_risks": [
    "Multiple small transactions to unknown numbers",
    "Unusual spending patterns compared to normal behavior"
  ],
  "financial_health_score": 65,
  "recommendations": [
    "Build emergency fund to cover 3 months of expenses",
    "Reduce discretionary spending by 30%",
    "Increase savings rate to 20% of income"
  ]
}
""";
  }

  Future<String> _callOpenRouter(String prompt) async {
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'HTTP-Referer': 'https://shieldai.ke',
      'X-Title': 'Shield AI Financial Planning',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final payload = {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': 'You are a financial advisor specializing in Kenyan mobile money users. Always respond with valid JSON only.',
        },
        {
          'role': 'user',
          'content': prompt,
        },
      ],
      'temperature': 0.3,
      'max_tokens': 2000,
    };

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenRouter API error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    final content = _extractContentFromResponse(data);

    return content;
  }

  String _extractContentFromResponse(Map<String, dynamic> response) {
    try {
      final choices = response['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'];
        if (message != null && message['content'] != null) {
          return message['content'] as String;
        }
      }
    } catch (e) {
      // Error extracting content from response
    }

    throw Exception('Invalid response format from OpenRouter');
  }

  SpendingPlan _parseSpendingPlanResponse(String response) {
    try {
      // Try to extract JSON from the response (in case there's extra text)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final data = jsonDecode(jsonStr);
        return SpendingPlan.fromJson(data);
      }
    } catch (e) {
      // Error parsing spending plan JSON
    }

    // Fallback to basic plan
    throw Exception('Could not parse spending plan response');
  }

  SpendingPlan _createFallbackPlan(
    List<TransactionModel> history,
    double currentBalance,
  ) {
    final monthlyIncome = _calculateMonthlyIncome(history);
    final weeklyBudget = (monthlyIncome / 4.3).round(); // Approximate weekly

    return SpendingPlan(
      weeklyBudget: weeklyBudget,
      monthlyBudget: (weeklyBudget * 4.3).round(),
      categories: [
        SpendingCategory(
          name: 'Food & Groceries',
          allocated: (weeklyBudget * 0.3).round(),
          recommended: (weeklyBudget * 0.25).round(),
          category: 'essential',
          description: 'Daily meals and household groceries',
        ),
        SpendingCategory(
          name: 'Transport',
          allocated: (weeklyBudget * 0.2).round(),
          recommended: (weeklyBudget * 0.15).round(),
          category: 'essential',
          description: 'Local transport and fares',
        ),
        SpendingCategory(
          name: 'Airtime & Data',
          allocated: (weeklyBudget * 0.15).round(),
          recommended: (weeklyBudget * 0.12).round(),
          category: 'essential',
          description: 'Mobile phone and internet costs',
        ),
        SpendingCategory(
          name: 'Entertainment',
          allocated: (weeklyBudget * 0.2).round(),
          recommended: (weeklyBudget * 0.1).round(),
          category: 'discretionary',
          description: 'Leisure and entertainment',
        ),
        SpendingCategory(
          name: 'Savings',
          allocated: (weeklyBudget * 0.15).round(),
          recommended: (weeklyBudget * 0.25).round(),
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
      financialHealthScore: 50,
      recommendations: [
        'Start tracking your daily expenses',
        'Build an emergency fund',
        'Create a monthly budget',
      ],
    );
  }

  String _formatTransactionHistory(List<TransactionModel> history) {
    final recentTransactions = history
        .where((t) => t.timestamp.isAfter(
              DateTime.now().subtract(const Duration(days: 30)),
            ))
        .take(20) // Limit to last 20 transactions
        .map((t) => '${t.timestamp.toString().split(' ')[0]}: KSH ${t.amount.abs().toStringAsFixed(0)} to ${t.recipient} (${t.amount > 0 ? 'sent' : 'received'})')
        .join('\n');

    return recentTransactions.isEmpty ? 'No recent transactions' : recentTransactions;
  }

  double _calculateMonthlyIncome(List<TransactionModel> history) {
    // Estimate monthly income based on incoming transactions
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final incomingTransactions = history
        .where((t) => t.timestamp.isAfter(thirtyDaysAgo) && t.amount < 0) // Negative amount = incoming
        .map((t) => t.amount.abs());

    if (incomingTransactions.isEmpty) return 15000; // Default assumption

    final totalIncoming = incomingTransactions.reduce((a, b) => a + b);
    return totalIncoming * 2; // Assume this represents half of monthly income
  }

  double _calculateEssentialSpending(List<TransactionModel> history) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final essentialKeywords = ['food', 'grocer', 'rent', 'utilit', 'water', 'electr', 'transport', 'matatu'];

    return history
        .where((t) => t.timestamp.isAfter(thirtyDaysAgo) && t.amount > 0) // Outgoing transactions
        .where((t) => essentialKeywords.any((keyword) =>
            t.recipient.toLowerCase().contains(keyword)))
        .map((t) => t.amount)
        .fold(0.0, (sum, amount) => sum + amount);
  }

  double _calculateDiscretionarySpending(List<TransactionModel> history) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final discretionaryKeywords = ['entertain', 'betting', 'lunch', 'restaurant', 'movie', 'game'];

    return history
        .where((t) => t.timestamp.isAfter(thirtyDaysAgo) && t.amount > 0)
        .where((t) => discretionaryKeywords.any((keyword) =>
            t.recipient.toLowerCase().contains(keyword)))
        .map((t) => t.amount)
        .fold(0.0, (sum, amount) => sum + amount);
  }

  double _calculateSavingsRate(List<TransactionModel> history, double monthlyIncome) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final outgoingTotal = history
        .where((t) => t.timestamp.isAfter(thirtyDaysAgo) && t.amount > 0)
        .map((t) => t.amount)
        .fold(0.0, (sum, amount) => sum + amount);

    final incomingTotal = history
        .where((t) => t.timestamp.isAfter(thirtyDaysAgo) && t.amount < 0)
        .map((t) => t.amount.abs())
        .fold(0.0, (sum, amount) => sum + amount);

    if (monthlyIncome <= 0) return 0.0;

    final netSavings = incomingTotal - outgoingTotal;
    return netSavings / monthlyIncome;
  }

  // Enhanced AI Features

  Future<ConversationMessage> askQuestion(
    String question,
    SpendingPlan currentPlan,
    List<TransactionModel> history,
  ) async {
    final prompt = _buildConversationPrompt(question, currentPlan, history);

    try {
      final response = await _callOpenRouter(prompt);
      final answer = _extractContentFromResponse(jsonDecode('{"choices": [{"message": {"content": "$response"}}]}'));

      return ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        question: question,
        answer: answer,
        timestamp: DateTime.now(),
        isFromUser: true,
      );
    } catch (e) {
      return ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        question: question,
        answer: 'I apologize, but I\'m unable to answer your question right now. Please try again later.',
        timestamp: DateTime.now(),
        isFromUser: true,
      );
    }
  }

  Future<SpendingPlan> refinePlan(
    SpendingPlan currentPlan,
    String userFeedback,
    List<TransactionModel> history,
  ) async {
    final prompt = _buildRefinementPrompt(currentPlan, userFeedback, history);

    try {
      final response = await _callOpenRouter(prompt);
      final refinedPlan = _parseSpendingPlanResponse(response);
      return refinedPlan;
    } catch (e) {
      return currentPlan; // Return original plan if refinement fails
    }
  }

  Future<List<SpendingPrediction>> predictSpending(
    List<TransactionModel> history,
    int monthsAhead,
  ) async {
    final prompt = _buildPredictionPrompt(history, monthsAhead);

    try {
      final response = await _callOpenRouter(prompt);
      return _parsePredictionsResponse(response);
    } catch (e) {
      return _createFallbackPredictions(history, monthsAhead);
    }
  }

  Future<List<SpendingAnomaly>> detectAnomalies(
    List<TransactionModel> history,
    SpendingPlan currentPlan,
  ) async {
    final prompt = _buildAnomalyPrompt(history, currentPlan);

    try {
      final response = await _callOpenRouter(prompt);
      return _parseAnomaliesResponse(response);
    } catch (e) {
      return _createFallbackAnomalies(history, currentPlan);
    }
  }

  Future<List<SmartSuggestion>> generateSmartSuggestions(
    List<TransactionModel> history,
    SpendingPlan currentPlan,
    double currentBalance,
  ) async {
    final prompt = _buildSuggestionsPrompt(history, currentPlan, currentBalance);

    try {
      final response = await _callOpenRouter(prompt);
      return _parseSuggestionsResponse(response);
    } catch (e) {
      return _createFallbackSuggestions(history, currentPlan);
    }
  }

  String _buildConversationPrompt(
    String question,
    SpendingPlan plan,
    List<TransactionModel> history,
  ) {
    return """
You are a financial advisor specializing in Kenyan M-Pesa users. Answer the user's question about their financial plan clearly and helpfully.

USER'S QUESTION: $question

CURRENT FINANCIAL PLAN:
- Weekly Budget: KSH ${plan.weeklyBudget}
- Monthly Budget: KSH ${plan.monthlyBudget}
- Financial Health Score: ${plan.financialHealthScore}/100

SPENDING CATEGORIES:
${plan.categories.map((cat) => '- ${cat.name}: Allocated KSH ${cat.allocated}, Recommended KSH ${cat.recommended}').join('\n')}

RECENT TRANSACTIONS (Last 10):
${history.take(10).map((t) => '${t.timestamp.toString().split(' ')[0]}: KSH ${t.amount.abs().toStringAsFixed(0)} to ${t.recipient}').join('\n')}

Provide a helpful, concise answer focusing on Kenyan financial context and M-Pesa usage patterns.
""";
  }

  String _buildRefinementPrompt(
    SpendingPlan currentPlan,
    String userFeedback,
    List<TransactionModel> history,
  ) {
    return """
As a financial advisor, refine this spending plan based on user feedback.

CURRENT PLAN:
- Weekly Budget: KSH ${currentPlan.weeklyBudget}
- Monthly Budget: KSH ${currentPlan.monthlyBudget}
- Categories: ${currentPlan.categories.map((c) => '${c.name}: ${c.allocated}').join(', ')}

USER FEEDBACK: $userFeedback

RECENT SPENDING HISTORY:
${history.take(20).map((t) => '${t.timestamp.toString().split(' ')[0]}: ${t.amount > 0 ? 'OUT' : 'IN'} KSH ${t.amount.abs().toStringAsFixed(0)} - ${t.recipient}').join('\n')}

Create an improved spending plan that addresses the user's feedback while maintaining financial prudence. Respond with valid JSON only.
""";
  }

  String _buildPredictionPrompt(List<TransactionModel> history, int monthsAhead) {
    return """
Analyze this spending history and predict future spending patterns for the next $monthsAhead months.

SPENDING HISTORY (Last 60 days):
${history.where((t) => t.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 60)))).map((t) => '${t.timestamp.toString().split(' ')[0]}: ${t.amount > 0 ? 'OUT' : 'IN'} KSH ${t.amount.abs().toStringAsFixed(0)} - ${t.recipient}').join('\n')}

Predict spending for these categories: Food, Transport, Airtime, Entertainment, Utilities, Savings.

Respond with valid JSON array of predictions only.
""";
  }

  String _buildAnomalyPrompt(List<TransactionModel> history, SpendingPlan plan) {
    return """
Detect unusual spending patterns in this transaction history that may indicate fraud or problematic behavior.

CURRENT PLAN LIMITS:
${plan.categories.map((c) => '${c.name}: Max KSH ${c.allocated}').join('\n')}

TRANSACTION HISTORY (Last 30 days):
${history.where((t) => t.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 30)))).map((t) => '${t.timestamp.toString().split(' ')[0]}: KSH ${t.amount.abs().toStringAsFixed(0)} to ${t.recipient}').join('\n')}

Look for:
- Amounts much higher than usual
- Unusual recipients or patterns
- Spending outside normal time patterns
- Potential fraudulent activities

Respond with valid JSON array of detected anomalies only.
""";
  }

  String _buildSuggestionsPrompt(
    List<TransactionModel> history,
    SpendingPlan plan,
    double currentBalance,
  ) {
    return """
Generate smart, context-aware financial suggestions for this Kenyan M-Pesa user.

CURRENT BALANCE: KSH ${currentBalance.toStringAsFixed(0)}
CURRENT PLAN: Weekly KSH ${plan.weeklyBudget}, Monthly KSH ${plan.monthlyBudget}

SPENDING HISTORY (Last 30 days):
${history.where((t) => t.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 30)))).map((t) => '${t.timestamp.toString().split(' ')[0]}: KSH ${t.amount.abs().toStringAsFixed(0)} to ${t.recipient}').join('\n')}

Consider Kenyan context:
- School fees season (January, May, September)
- Holiday spending patterns
- Airtime and data needs
- Transportation costs
- Emergency fund importance

Generate 3-5 actionable suggestions with potential savings amounts.

Respond with valid JSON array only.
""";
  }

  List<SpendingPrediction> _parsePredictionsResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final data = jsonDecode(jsonStr) as List;
        return data.map((item) => SpendingPrediction.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Error parsing predictions
    }
    return [];
  }

  List<SpendingAnomaly> _parseAnomaliesResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final data = jsonDecode(jsonStr) as List;
        return data.map((item) => SpendingAnomaly.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Error parsing anomalies
    }
    return [];
  }

  List<SmartSuggestion> _parseSuggestionsResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final data = jsonDecode(jsonStr) as List;
        return data.map((item) => SmartSuggestion.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Error parsing suggestions
    }
    return [];
  }

  List<SpendingPrediction> _createFallbackPredictions(List<TransactionModel> history, int monthsAhead) {
    // Simple fallback based on recent averages
    final categories = ['Food', 'Transport', 'Airtime', 'Entertainment', 'Savings'];
    final now = DateTime.now();

    return categories.map((category) {
      final avgSpending = _calculateCategoryAverage(history, category);
      return SpendingPrediction(
        category: category,
        predictedAmount: avgSpending * monthsAhead,
        confidence: 0.6,
        reasoning: 'Based on recent spending patterns',
        periodStart: now,
        periodEnd: now.add(Duration(days: monthsAhead * 30)),
      );
    }).toList();
  }

  List<SpendingAnomaly> _createFallbackAnomalies(List<TransactionModel> history, SpendingPlan plan) {
    // Simple anomaly detection based on thresholds
    final anomalies = <SpendingAnomaly>[];
    final recentTransactions = history.where(
      (t) => t.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 7)))
    );

    for (final transaction in recentTransactions) {
      if (transaction.amount > 5000) { // High amount threshold
        anomalies.add(SpendingAnomaly(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          description: 'Unusually high transaction amount',
          amount: transaction.amount,
          category: 'General',
          timestamp: transaction.timestamp,
          severity: 0.8,
          recommendation: 'Verify this transaction and consider setting spending limits',
        ));
      }
    }

    return anomalies.take(3).toList(); // Limit to 3 anomalies
  }

  List<SmartSuggestion> _createFallbackSuggestions(List<TransactionModel> history, SpendingPlan plan) {
    return [
      SmartSuggestion(
        id: '1',
        title: 'Build Emergency Fund',
        description: 'Start saving for unexpected expenses',
        category: 'Savings',
        potentialSavings: 1000,
        priority: 5,
        suggestedDate: DateTime.now(),
      ),
      SmartSuggestion(
        id: '2',
        title: 'Reduce Airtime Costs',
        description: 'Use WiFi calling apps to save on airtime',
        category: 'Communication',
        potentialSavings: 500,
        priority: 3,
        suggestedDate: DateTime.now(),
      ),
      SmartSuggestion(
        id: '3',
        title: 'Plan Weekly Meals',
        description: 'Meal planning can reduce food expenses by 20%',
        category: 'Food',
        potentialSavings: 800,
        priority: 4,
        suggestedDate: DateTime.now(),
      ),
    ];
  }

  double _calculateCategoryAverage(List<TransactionModel> history, String category) {
    final categoryTransactions = history.where((t) =>
      t.recipient.toLowerCase().contains(category.toLowerCase()) && t.amount > 0
    );

    if (categoryTransactions.isEmpty) return 0.0;

    final total = categoryTransactions.map((t) => t.amount).reduce((a, b) => a + b);
    return total / categoryTransactions.length;
  }
}