class TransactionModel {
  final int? id;
  final double amount;
  final String recipient;
  final DateTime timestamp;
  final bool isFraudulent;
  final String? location;

  TransactionModel({
    this.id,
    required this.amount,
    required this.recipient,
    required this.timestamp,
    required this.isFraudulent,
    this.location,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['id'] as int?,
        amount: (json['amount'] as num).toDouble(),
        recipient: json['recipient'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isFraudulent: json['is_fraudulent'] as bool? ?? false,
        location: json['location'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'amount': amount,
        'recipient': recipient,
        'timestamp': timestamp.toIso8601String(),
        'is_fraudulent': isFraudulent,
        if (location != null) 'location': location,
      };

  TransactionModel copyWith({
    int? id,
    double? amount,
    String? recipient,
    DateTime? timestamp,
    bool? isFraudulent,
    String? location,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      recipient: recipient ?? this.recipient,
      timestamp: timestamp ?? this.timestamp,
      isFraudulent: isFraudulent ?? this.isFraudulent,
      location: location ?? this.location,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          amount == other.amount &&
          recipient == other.recipient &&
          timestamp == other.timestamp &&
          isFraudulent == other.isFraudulent &&
          location == other.location;

  @override
  int get hashCode =>
      id.hashCode ^
      amount.hashCode ^
      recipient.hashCode ^
      timestamp.hashCode ^
      isFraudulent.hashCode ^
      location.hashCode;

  bool isValid() {
    return amount > 0 &&
           recipient.isNotEmpty &&
           _isValidPhone(recipient) &&
           timestamp.isBefore(DateTime.now().add(const Duration(minutes: 1))); // Allow slight future timestamps
  }

  bool _isValidPhone(String phone) {
    // Kenyan phone number validation
    final kenyanPhoneRegex = RegExp(r'^(\+254|254|0)[17]\d{8}$');
    return kenyanPhoneRegex.hasMatch(phone.replaceAll(' ', ''));
  }

  bool isHighAmount() {
    // Consider amounts > 20,000 KSH as high for individuals
    return amount > 20000;
  }

  bool isUnusualTime() {
    // Consider transactions between 12 AM and 5 AM as unusual
    final hour = timestamp.hour;
    return hour >= 0 && hour <= 5;
  }
}
