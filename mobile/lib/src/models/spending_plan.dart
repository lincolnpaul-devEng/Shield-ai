class SpendingPlan {
  final int weeklyBudget;
  final int monthlyBudget;
  final List<SpendingCategory> categories;
  final List<String> wasteAlerts;
  final List<String> savingsTips;
  final List<String> fraudRisks;
  final int financialHealthScore;
  final List<String> recommendations;

  SpendingPlan({
    required this.weeklyBudget,
    required this.monthlyBudget,
    required this.categories,
    required this.wasteAlerts,
    required this.savingsTips,
    required this.fraudRisks,
    required this.financialHealthScore,
    required this.recommendations,
  });

  factory SpendingPlan.fromJson(Map<String, dynamic> json) {
    return SpendingPlan(
      weeklyBudget: json['weekly_budget'] as int? ?? 0,
      monthlyBudget: json['monthly_budget'] as int? ?? 0,
      categories: (json['categories'] as List<dynamic>?)
          ?.map((item) => SpendingCategory.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      wasteAlerts: (json['waste_alerts'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList() ?? [],
      savingsTips: (json['savings_tips'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList() ?? [],
      fraudRisks: (json['fraud_risks'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList() ?? [],
      financialHealthScore: json['financial_health_score'] as int? ?? 50,
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekly_budget': weeklyBudget,
      'monthly_budget': monthlyBudget,
      'categories': categories.map((cat) => cat.toJson()).toList(),
      'waste_alerts': wasteAlerts,
      'savings_tips': savingsTips,
      'fraud_risks': fraudRisks,
      'financial_health_score': financialHealthScore,
      'recommendations': recommendations,
    };
  }

  // Helper methods
  double getTotalAllocated() {
    return categories.fold(0.0, (sum, cat) => sum + cat.allocated);
  }

  double getTotalRecommended() {
    return categories.fold(0.0, (sum, cat) => sum + cat.recommended);
  }

  List<SpendingCategory> getEssentialCategories() {
    return categories.where((cat) => cat.category == 'essential').toList();
  }

  List<SpendingCategory> getDiscretionaryCategories() {
    return categories.where((cat) => cat.category == 'discretionary').toList();
  }

  List<SpendingCategory> getSavingsCategories() {
    return categories.where((cat) => cat.category == 'savings').toList();
  }

  double getEssentialTotal() {
    return getEssentialCategories().fold(0.0, (sum, cat) => sum + cat.allocated);
  }

  double getDiscretionaryTotal() {
    return getDiscretionaryCategories().fold(0.0, (sum, cat) => sum + cat.allocated);
  }

  double getSavingsTotal() {
    return getSavingsCategories().fold(0.0, (sum, cat) => sum + cat.allocated);
  }
}

class SpendingCategory {
  final String name;
  final int allocated;
  final int recommended;
  final String category; // 'essential', 'discretionary', 'savings'
  final String description;

  SpendingCategory({
    required this.name,
    required this.allocated,
    required this.recommended,
    required this.category,
    required this.description,
  });

  factory SpendingCategory.fromJson(Map<String, dynamic> json) {
    return SpendingCategory(
      name: json['name'] as String? ?? '',
      allocated: json['allocated'] as int? ?? 0,
      recommended: json['recommended'] as int? ?? 0,
      category: json['category'] as String? ?? 'discretionary',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'allocated': allocated,
      'recommended': recommended,
      'category': category,
      'description': description,
    };
  }

  bool get isOverBudget => allocated > recommended;
  bool get isUnderBudget => allocated < recommended;
  int get difference => allocated - recommended;

  String get statusText {
    if (isOverBudget) {
      return 'KSH ${difference.abs()} over budget';
    } else if (isUnderBudget) {
      return 'KSH ${difference.abs()} under budget';
    } else {
      return 'On budget';
    }
  }

  String get recommendationText {
    if (isOverBudget) {
      return 'Consider reducing spending in this category';
    } else if (isUnderBudget) {
      return 'You have room to spend more if needed';
    } else {
      return 'Good balance maintained';
    }
  }
}