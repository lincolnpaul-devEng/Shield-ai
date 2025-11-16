class FraudCheckResult {
  final bool isFraud;
  final double confidence;
  final String reason;
  final bool actionRequired;

  FraudCheckResult({
    required this.isFraud,
    required this.confidence,
    required this.reason,
    required this.actionRequired,
  });

  factory FraudCheckResult.fromJson(Map<String, dynamic> json) => FraudCheckResult(
        isFraud: json['is_fraud'] as bool? ?? false,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
        reason: json['reason'] as String? ?? '',
        actionRequired: json['action_required'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'is_fraud': isFraud,
        'confidence': confidence,
        'reason': reason,
        'action_required': actionRequired,
      };

  FraudCheckResult copyWith({
    bool? isFraud,
    double? confidence,
    String? reason,
    bool? actionRequired,
  }) {
    return FraudCheckResult(
      isFraud: isFraud ?? this.isFraud,
      confidence: confidence ?? this.confidence,
      reason: reason ?? this.reason,
      actionRequired: actionRequired ?? this.actionRequired,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FraudCheckResult &&
          runtimeType == other.runtimeType &&
          isFraud == other.isFraud &&
          confidence == other.confidence &&
          reason == other.reason &&
          actionRequired == other.actionRequired;

  @override
  int get hashCode =>
      isFraud.hashCode ^
      confidence.hashCode ^
      reason.hashCode ^
      actionRequired.hashCode;

  bool isValid() {
    return confidence >= 0.0 &&
           confidence <= 1.0 &&
           reason.isNotEmpty;
  }

  bool requiresImmediateAction() {
    return actionRequired && confidence > 0.7;
  }

  String getRiskLevel() {
    if (confidence >= 0.8) return 'High Risk';
    if (confidence >= 0.6) return 'Medium Risk';
    if (confidence >= 0.4) return 'Low Risk';
    return 'Very Low Risk';
  }
}