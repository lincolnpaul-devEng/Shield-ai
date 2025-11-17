class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final double? normalSpendingLimit;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.normalSpendingLimit,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        normalSpendingLimit: (json['normal_spending_limit'] as num?)?.toDouble(),
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phone': phone,
        if (normalSpendingLimit != null) 'normal_spending_limit': normalSpendingLimit,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  UserModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    double? normalSpendingLimit,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      normalSpendingLimit: normalSpendingLimit ?? this.normalSpendingLimit,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          phone == other.phone &&
          normalSpendingLimit == other.normalSpendingLimit &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      fullName.hashCode ^
      phone.hashCode ^
      normalSpendingLimit.hashCode ^
      createdAt.hashCode;

  bool isValid() {
    return id.isNotEmpty &&
        fullName.isNotEmpty &&
        phone.isNotEmpty &&
        _isValidPhone(phone);
  }

  bool _isValidPhone(String phone) {
    final kenyanPhoneRegex = RegExp(r'^(\+254|254|0)[17]\d{8}$');
    return kenyanPhoneRegex.hasMatch(phone.replaceAll(' ', ''));
  }

  /// Computed property to get the first name from full name
  String get firstName {
    if (fullName.isEmpty) return 'User';

    // Split by spaces and take the first part
    final nameParts = fullName.trim().split(' ');
    return nameParts.isNotEmpty ? nameParts[0] : 'User';
  }
}
