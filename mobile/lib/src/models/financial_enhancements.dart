import 'package:flutter/material.dart';

class ConversationMessage {
  final String id;
  final String question;
  final String answer;
  final DateTime timestamp;
  final bool isFromUser;

  ConversationMessage({
    required this.id,
    required this.question,
    required this.answer,
    required this.timestamp,
    required this.isFromUser,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      isFromUser: json['is_from_user'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'timestamp': timestamp.toIso8601String(),
      'is_from_user': isFromUser,
    };
  }
}

class SpendingPrediction {
  final String category;
  final double predictedAmount;
  final double confidence;
  final String reasoning;
  final DateTime periodStart;
  final DateTime periodEnd;

  SpendingPrediction({
    required this.category,
    required this.predictedAmount,
    required this.confidence,
    required this.reasoning,
    required this.periodStart,
    required this.periodEnd,
  });

  factory SpendingPrediction.fromJson(Map<String, dynamic> json) {
    return SpendingPrediction(
      category: json['category'] as String? ?? '',
      predictedAmount: (json['predicted_amount'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      reasoning: json['reasoning'] as String? ?? '',
      periodStart: DateTime.parse(json['period_start'] as String? ?? DateTime.now().toIso8601String()),
      periodEnd: DateTime.parse(json['period_end'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'predicted_amount': predictedAmount,
      'confidence': confidence,
      'reasoning': reasoning,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
    };
  }
}

class SpendingAnomaly {
  final String id;
  final String description;
  final double amount;
  final String category;
  final DateTime timestamp;
  final double severity; // 0.0 to 1.0
  final String recommendation;

  SpendingAnomaly({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.timestamp,
    required this.severity,
    required this.recommendation,
  });

  factory SpendingAnomaly.fromJson(Map<String, dynamic> json) {
    return SpendingAnomaly(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      severity: (json['severity'] as num?)?.toDouble() ?? 0.0,
      recommendation: json['recommendation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity,
      'recommendation': recommendation,
    };
  }

  Color get severityColor {
    if (severity >= 0.7) return Colors.red;
    if (severity >= 0.4) return Colors.orange;
    return Colors.yellow;
  }

  String get severityText {
    if (severity >= 0.7) return 'High Risk';
    if (severity >= 0.4) return 'Medium Risk';
    return 'Low Risk';
  }
}

class SmartSuggestion {
  final String id;
  final String title;
  final String description;
  final String category;
  final double potentialSavings;
  final int priority; // 1-5, 5 being highest
  final DateTime suggestedDate;
  final bool isImplemented;

  SmartSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.potentialSavings,
    required this.priority,
    required this.suggestedDate,
    this.isImplemented = false,
  });

  factory SmartSuggestion.fromJson(Map<String, dynamic> json) {
    return SmartSuggestion(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      potentialSavings: (json['potential_savings'] as num?)?.toDouble() ?? 0.0,
      priority: json['priority'] as int? ?? 1,
      suggestedDate: DateTime.parse(json['suggested_date'] as String? ?? DateTime.now().toIso8601String()),
      isImplemented: json['is_implemented'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'potential_savings': potentialSavings,
      'priority': priority,
      'suggested_date': suggestedDate.toIso8601String(),
      'is_implemented': isImplemented,
    };
  }

  Color get priorityColor {
    switch (priority) {
      case 5:
        return Colors.red;
      case 4:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 2:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String get priorityText {
    switch (priority) {
      case 5:
        return 'Critical';
      case 4:
        return 'High';
      case 3:
        return 'Medium';
      case 2:
        return 'Low';
      default:
        return 'Optional';
    }
  }
}

class PlanRefinement {
  final String id;
  final String userFeedback;
  final Map<String, dynamic> adjustments;
  final DateTime timestamp;
  final bool applied;

  PlanRefinement({
    required this.id,
    required this.userFeedback,
    required this.adjustments,
    required this.timestamp,
    this.applied = false,
  });

  factory PlanRefinement.fromJson(Map<String, dynamic> json) {
    return PlanRefinement(
      id: json['id'] as String? ?? '',
      userFeedback: json['user_feedback'] as String? ?? '',
      adjustments: json['adjustments'] as Map<String, dynamic>? ?? {},
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      applied: json['applied'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_feedback': userFeedback,
      'adjustments': adjustments,
      'timestamp': timestamp.toIso8601String(),
      'applied': applied,
    };
  }
}