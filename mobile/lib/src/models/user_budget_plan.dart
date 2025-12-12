class UserBudgetPlan {
  final String id;
  final String userId;
  final String planName;
  final String? planDescription;
  final double monthlyIncome;
  final double? savingsGoal;
  final int? savingsPeriodMonths;
  final Map<String, double> allocations;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserBudgetPlan({
    required this.id,
    required this.userId,
    required this.planName,
    this.planDescription,
    required this.monthlyIncome,
    this.savingsGoal,
    this.savingsPeriodMonths,
    required this.allocations,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserBudgetPlan.fromJson(Map<String, dynamic> json) {
    return UserBudgetPlan(
      id: json['id'] ?? '',
      userId: json['user_id']?.toString() ?? '', // Convert to string since backend returns integer
      planName: json['plan_name'] ?? '',
      planDescription: json['plan_description'],
      monthlyIncome: (json['monthly_income'] as num?)?.toDouble() ?? 0.0,
      savingsGoal: json['savings_goal'] != null ? (json['savings_goal'] as num).toDouble() : null,
      savingsPeriodMonths: json['savings_period_months'],
      allocations: json['allocations'] != null
          ? Map<String, double>.from(
              (json['allocations'] as Map).map((key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0.0))
            )
          : {},
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_name': planName,
      'plan_description': planDescription,
      'monthly_income': monthlyIncome,
      'savings_goal': savingsGoal,
      'savings_period_months': savingsPeriodMonths,
      'allocations': allocations,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Calculate total allocated amount
  double get totalAllocated => allocations.values.fold(0, (sum, amount) => sum + amount);

  // Check if allocations exceed income
  bool get isOverAllocated => totalAllocated > monthlyIncome;

  // Get remaining amount to allocate
  double get remainingToAllocate => monthlyIncome - totalAllocated;

  // Calculate savings rate
  double get savingsRate => savingsGoal != null ? (savingsGoal! / monthlyIncome) * 100 : 0;

  // Create a copy with updated fields
  UserBudgetPlan copyWith({
    String? id,
    String? userId,
    String? planName,
    String? planDescription,
    double? monthlyIncome,
    double? savingsGoal,
    int? savingsPeriodMonths,
    Map<String, double>? allocations,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserBudgetPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planName: planName ?? this.planName,
      planDescription: planDescription ?? this.planDescription,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      savingsGoal: savingsGoal ?? this.savingsGoal,
      savingsPeriodMonths: savingsPeriodMonths ?? this.savingsPeriodMonths,
      allocations: allocations ?? Map.from(this.allocations),
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BudgetTemplate {
  final String id;
  final String name;
  final String description;
  final Map<String, double> allocations; // Category -> percentage

  BudgetTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.allocations,
  });

  factory BudgetTemplate.fromJson(Map<String, dynamic> json) {
    return BudgetTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      allocations: Map<String, double>.from(
        json['allocations'].map((key, value) => MapEntry(key, (value as num).toDouble()))
      ),
    );
  }

  // Convert percentages to actual amounts based on income
  Map<String, double> getAllocationsForIncome(double income) {
    return allocations.map((category, percentage) =>
      MapEntry(category, income * (percentage / 100))
    );
  }
}