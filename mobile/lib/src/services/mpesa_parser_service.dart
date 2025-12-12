import 'package:sms_advanced/sms_advanced.dart';

class MpesaTransactionData {
  final String transactionId;
  final double amount;
  final String recipient;
  final String? phoneNumber;
  final DateTime timestamp;
  final String transactionType;
  final double? balanceAfter;
  final bool isIncoming;
  final String rawMessage;

  MpesaTransactionData({
    required this.transactionId,
    required this.amount,
    required this.recipient,
    this.phoneNumber,
    required this.timestamp,
    required this.transactionType,
    this.balanceAfter,
    required this.isIncoming,
    required this.rawMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'amount': amount,
      'recipient': recipient,
      'phone_number': phoneNumber,
      'timestamp': timestamp.toIso8601String(),
      'transaction_type': transactionType,
      'balance_after': balanceAfter,
      'is_incoming': isIncoming,
      'raw_message': rawMessage,
    };
  }

  factory MpesaTransactionData.fromJson(Map<String, dynamic> json) {
    return MpesaTransactionData(
      transactionId: json['transaction_id'] ?? '',
      amount: json['amount']?.toDouble() ?? 0.0,
      recipient: json['recipient'] ?? '',
      phoneNumber: json['phone_number'],
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      transactionType: json['transaction_type'] ?? '',
      balanceAfter: json['balance_after']?.toDouble(),
      isIncoming: json['is_incoming'] ?? false,
      rawMessage: json['raw_message'] ?? '',
    );
  }
}

class MpesaParserService {
  /// Parse a single M-Pesa SMS message into transaction data
  MpesaTransactionData? parseMpesaMessage(SmsMessage message) {
    final body = message.body ?? '';
    final timestamp = message.date ?? DateTime.now();

    // Common M-Pesa transaction patterns
    final patterns = {
      // Sent money: "ABC123 Confirmed. Ksh500.00 sent to JOHN DOE 0722000000 on 1/1/24 at 12:00 PM. New M-Pesa balance is Ksh1,500.00"
      'sent': RegExp(
        r'([A-Z0-9]+)\s+Confirmed\.\s*Ksh([\d,]+\.?\d*)\s+sent\s+to\s+(.+?)\s+(\d{10,12})\s+on\s+(.+?)\s+at\s+(.+?)\.\s*(?:New\s+M-Pesa\s+balance\s+is\s+Ksh([\d,]+\.?\d*))?',
        caseSensitive: false,
      ),

      // Received money: "ABC123 Confirmed. You have received Ksh500.00 from JOHN DOE 0722000000 on 1/1/24 at 12:00 PM. New M-Pesa balance is Ksh2,000.00"
      'received': RegExp(
        r'([A-Z0-9]+)\s+Confirmed\.\s*You\s+have\s+received\s+Ksh([\d,]+\.?\d*)\s+from\s+(.+?)\s+(\d{10,12})\s+on\s+(.+?)\s+at\s+(.+?)\.\s*(?:New\s+M-Pesa\s+balance\s+is\s+Ksh([\d,]+\.?\d*))?',
        caseSensitive: false,
      ),

      // Paid bill: "ABC123 Confirmed. Ksh500.00 paid to KPLC on 1/1/24 at 12:00 PM. New M-Pesa balance is Ksh1,000.00"
      'paid': RegExp(
        r'([A-Z0-9]+)\s+Confirmed\.\s*Ksh([\d,]+\.?\d*)\s+paid\s+to\s+(.+?)\s+on\s+(.+?)\s+at\s+(.+?)\.\s*(?:New\s+M-Pesa\s+balance\s+is\s+Ksh([\d,]+\.?\d*))?',
        caseSensitive: false,
      ),

      // Airtime purchase: "ABC123 Confirmed. You bought Ksh100.00 of airtime on 1/1/24 at 12:00 PM. New M-Pesa balance is Ksh900.00"
      'airtime': RegExp(
        r'([A-Z0-9]+)\s+Confirmed\.\s*You\s+bought\s+Ksh([\d,]+\.?\d*)\s+of\s+airtime\s+on\s+(.+?)\s+at\s+(.+?)\.\s*(?:New\s+M-Pesa\s+balance\s+is\s+Ksh([\d,]+\.?\d*))?',
        caseSensitive: false,
      ),

      // Withdrawals: "ABC123 Confirmed. Ksh500.00 withdrawn from Agent 12345 on 1/1/24 at 12:00 PM. New M-Pesa balance is Ksh500.00"
      'withdrawn': RegExp(
        r'([A-Z0-9]+)\s+Confirmed\.\s*Ksh([\d,]+\.?\d*)\s+withdrawn\s+from\s+(.+?)\s+on\s+(.+?)\s+at\s+(.+?)\.\s*(?:New\s+M-Pesa\s+balance\s+is\s+Ksh([\d,]+\.?\d*))?',
        caseSensitive: false,
      ),

      // Deposit/Top up: "ABC123 Confirmed. You have deposited Ksh1,000.00 to M-Pesa on 1/1/24 at 12:00 PM. New M-Pesa balance is Ksh2,000.00"
      'deposit': RegExp(
        r'([A-Z0-9]+)\s+Confirmed\.\s*You\s+have\s+deposited\s+Ksh([\d,]+\.?\d*)\s+to\s+M-Pesa\s+on\s+(.+?)\s+at\s+(.+?)\.\s*(?:New\s+M-Pesa\s+balance\s+is\s+Ksh([\d,]+\.?\d*))?',
        caseSensitive: false,
      ),

      // Business payment: "ABC123 Confirmed. Ksh250.00 paid to XYZ SHOP on 1/1/24 at 12:00 PM. New M-Pesa balance is Ksh750.00"
      'business': RegExp(
        r'([A-Z0-9]+)\s+Confirmed\.\s*Ksh([\d,]+\.?\d*)\s+paid\s+to\s+(.+?)\s+on\s+(.+?)\s+at\s+(.+?)\.\s*(?:New\s+M-Pesa\s+balance\s+is\s+Ksh([\d,]+\.?\d*))?',
        caseSensitive: false,
      ),
    };

    for (final entry in patterns.entries) {
      final type = entry.key;
      final pattern = entry.value;
      final match = pattern.firstMatch(body);

      if (match != null) {
        final transactionId = match.group(1);
        final amountStr = match.group(2)?.replaceAll(',', '');
        final amount = double.tryParse(amountStr ?? '0') ?? 0.0;

        String recipient = '';
        String? phoneNumber;
        double? balance;

        switch (type) {
          case 'sent':
            recipient = match.group(3) ?? '';
            phoneNumber = match.group(4);
            balance = double.tryParse(match.group(7)?.replaceAll(',', '') ?? '0');
            break;
          case 'received':
            recipient = match.group(3) ?? '';
            phoneNumber = match.group(4);
            balance = double.tryParse(match.group(7)?.replaceAll(',', '') ?? '0');
            break;
          case 'paid':
          case 'business':
            recipient = match.group(3) ?? '';
            balance = double.tryParse(match.group(6)?.replaceAll(',', '') ?? '0');
            break;
          case 'airtime':
            recipient = 'Airtime Purchase';
            balance = double.tryParse(match.group(5)?.replaceAll(',', '') ?? '0');
            break;
          case 'withdrawn':
            recipient = match.group(3) ?? '';
            balance = double.tryParse(match.group(6)?.replaceAll(',', '') ?? '0');
            break;
          case 'deposit':
            recipient = 'M-Pesa Deposit';
            balance = double.tryParse(match.group(5)?.replaceAll(',', '') ?? '0');
            break;
        }

        // Determine transaction type and amount sign
        bool isIncoming = false;
        double signedAmount = amount;

        if (type == 'received' || type == 'deposit') {
          isIncoming = true;
          signedAmount = amount; // Positive for incoming
        } else {
          signedAmount = -amount; // Negative for outgoing
        }

        return MpesaTransactionData(
          transactionId: transactionId ?? '',
          amount: signedAmount,
          recipient: recipient,
          phoneNumber: phoneNumber,
          timestamp: timestamp,
          transactionType: type,
          balanceAfter: balance,
          isIncoming: isIncoming,
          rawMessage: body,
        );
      }
    }

    return null; // Not a recognized M-Pesa transaction
  }

  /// Parse multiple M-Pesa SMS messages
  List<MpesaTransactionData> parseMpesaMessages(List<SmsMessage> messages) {
    final transactions = <MpesaTransactionData>[];

    for (final message in messages) {
      final parsedTransaction = parseMpesaMessage(message);
      if (parsedTransaction != null) {
        transactions.add(parsedTransaction);
      }
    }

    return transactions;
  }

  /// Categorize transaction based on recipient and type
  String categorizeTransaction(MpesaTransactionData transaction) {
    final recipient = transaction.recipient.toLowerCase();
    final type = transaction.transactionType;

    // Direct categorization based on transaction type
    switch (type) {
      case 'airtime':
        return 'Airtime & Data';
      case 'deposit':
        return 'Deposits';
      case 'withdrawn':
        return 'Withdrawals';
    }

    // Categorization based on recipient patterns
    if (recipient.contains('kplc') || recipient.contains('electricity')) {
      return 'Utilities';
    } else if (recipient.contains('nairobi water') || recipient.contains('water')) {
      return 'Utilities';
    } else if (recipient.contains('kengen') || recipient.contains('power')) {
      return 'Utilities';
    } else if (recipient.contains('food') || recipient.contains('restaurant') || recipient.contains('hotel')) {
      return 'Food & Groceries';
    } else if (recipient.contains('supermarket') || recipient.contains('shop') || recipient.contains('store')) {
      return 'Food & Groceries';
    } else if (recipient.contains('matatu') || recipient.contains('transport') || recipient.contains('bus')) {
      return 'Transport';
    } else if (recipient.contains('uber') || recipient.contains('bolt') || recipient.contains('taxi')) {
      return 'Transport';
    } else if (recipient.contains('safaricom') || recipient.contains('airtel') || recipient.contains('telkom')) {
      return 'Airtime & Data';
    } else if (recipient.contains('hospital') || recipient.contains('clinic') || recipient.contains('medical')) {
      return 'Healthcare';
    } else if (recipient.contains('school') || recipient.contains('university') || recipient.contains('education')) {
      return 'Education';
    } else if (recipient.contains('cinema') || recipient.contains('movie') || recipient.contains('entertainment')) {
      return 'Entertainment';
    } else if (recipient.contains('agent') || recipient.contains('atm')) {
      return 'Withdrawals';
    } else {
      return 'Miscellaneous';
    }
  }

  /// Get spending insights from parsed transactions
  Map<String, dynamic> getSpendingInsights(List<MpesaTransactionData> transactions) {
    final Map<String, dynamic> insights = {
      'total_transactions': transactions.length,
      'total_spent': 0.0,
      'total_received': 0.0,
      'net_flow': 0.0,
      'categories': <String, double>{},
      'top_recipients': <String, double>{},
      'transaction_types': <String, int>{},
      'daily_spending': <String, double>{},
      'weekly_spending': <String, double>{},
      'monthly_spending': <String, double>{},
    };

    final categories = insights['categories'] as Map<String, double>;
    final topRecipients = insights['top_recipients'] as Map<String, double>;
    final transactionTypes = insights['transaction_types'] as Map<String, int>;
    final dailySpending = insights['daily_spending'] as Map<String, double>;
    final weeklySpending = insights['weekly_spending'] as Map<String, double>;
    final monthlySpending = insights['monthly_spending'] as Map<String, double>;

    for (final transaction in transactions) {
      final amount = transaction.amount;
      final category = categorizeTransaction(transaction);
      final recipient = transaction.recipient;
      final type = transaction.transactionType;

      // Update totals
      if (amount > 0) {
        insights['total_received'] = (insights['total_received'] as double) + amount;
      } else {
        insights['total_spent'] = (insights['total_spent'] as double) + amount.abs();
      }

      // Update categories
      categories[category] = (categories[category] ?? 0.0) + amount.abs();

      // Update top recipients
      topRecipients[recipient] = (topRecipients[recipient] ?? 0.0) + amount.abs();

      // Update transaction types
      transactionTypes[type] = (transactionTypes[type] ?? 0) + 1;

      // Update time-based spending
      final date = transaction.timestamp;
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final weekKey = '${date.year}-W${((date.day - 1) ~/ 7) + 1}';
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      dailySpending[dateKey] = (dailySpending[dateKey] ?? 0.0) + amount.abs();
      weeklySpending[weekKey] = (weeklySpending[weekKey] ?? 0.0) + amount.abs();
      monthlySpending[monthKey] = (monthlySpending[monthKey] ?? 0.0) + amount.abs();
    }

    // Calculate net flow
    insights['net_flow'] = (insights['total_received'] as double) - (insights['total_spent'] as double);

    // Sort top recipients
    final sortedRecipients = Map.fromEntries(
      topRecipients.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
    );
    insights['top_recipients'] = sortedRecipients;

    return insights;
  }

  /// Validate if a message is from M-Pesa
  bool isMpesaMessage(SmsMessage message) {
    final sender = message.address?.toUpperCase() ?? '';
    return sender.contains('MPESA') ||
           sender.contains('SAFARICOM') ||
           sender.contains('254722') ||
           sender.contains('254733');
  }
}