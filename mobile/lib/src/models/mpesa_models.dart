/// M-Pesa specific models for STK Push integration
library;

/// Result of STK Push initiation
class StkPushResult {
  final bool success;
  final int? transactionId;
  final String? merchantRequestId;
  final String? checkoutRequestId;
  final String? responseCode;
  final String? responseDescription;
  final String? customerMessage;

  StkPushResult({
    required this.success,
    this.transactionId,
    this.merchantRequestId,
    this.checkoutRequestId,
    this.responseCode,
    this.responseDescription,
    this.customerMessage,
  });

  factory StkPushResult.fromJson(Map<String, dynamic> json) {
    return StkPushResult(
      success: json['success'] as bool? ?? false,
      transactionId: json['transaction_id'] as int?,
      merchantRequestId: json['merchant_request_id'] as String?,
      checkoutRequestId: json['checkout_request_id'] as String?,
      responseCode: json['response_code'] as String?,
      responseDescription: json['response_description'] as String?,
      customerMessage: json['customer_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'transaction_id': transactionId,
      'merchant_request_id': merchantRequestId,
      'checkout_request_id': checkoutRequestId,
      'response_code': responseCode,
      'response_description': responseDescription,
      'customer_message': customerMessage,
    };
  }
}

/// M-Pesa transaction status from backend
class MpesaTransactionStatus {
  final int id;
  final int userId;
  final String? merchantRequestId;
  final String? checkoutRequestId;
  final String? mpesaReceiptNumber;
  final double amount;
  final String phoneNumber;
  final String accountReference;
  final String? transactionDesc;
  final int? resultCode;
  final String? resultDesc;
  final String status; // pending, completed, failed, cancelled
  final DateTime createdAt;
  final DateTime updatedAt;

  MpesaTransactionStatus({
    required this.id,
    required this.userId,
    this.merchantRequestId,
    this.checkoutRequestId,
    this.mpesaReceiptNumber,
    required this.amount,
    required this.phoneNumber,
    required this.accountReference,
    this.transactionDesc,
    this.resultCode,
    this.resultDesc,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MpesaTransactionStatus.fromJson(Map<String, dynamic> json) {
    return MpesaTransactionStatus(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      merchantRequestId: json['merchant_request_id'] as String?,
      checkoutRequestId: json['checkout_request_id'] as String?,
      mpesaReceiptNumber: json['mpesa_receipt_number'] as String?,
      amount: (json['amount'] as num).toDouble(),
      phoneNumber: json['phone_number'] as String,
      accountReference: json['account_reference'] as String,
      transactionDesc: json['transaction_desc'] as String?,
      resultCode: json['result_code'] as int?,
      resultDesc: json['result_desc'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'merchant_request_id': merchantRequestId,
      'checkout_request_id': checkoutRequestId,
      'mpesa_receipt_number': mpesaReceiptNumber,
      'amount': amount,
      'phone_number': phoneNumber,
      'account_reference': accountReference,
      'transaction_desc': transactionDesc,
      'result_code': resultCode,
      'result_desc': resultDesc,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if transaction is completed successfully
  bool get isCompleted => status == 'completed';

  /// Check if transaction failed
  bool get isFailed => status == 'failed';

  /// Check if transaction is still pending
  bool get isPending => status == 'pending';

  /// Check if transaction was cancelled
  bool get isCancelled => status == 'cancelled';
}