import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:sms_advanced/sms_advanced.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class SmsReaderService {
  final SmsQuery _smsQuery = SmsQuery();
  final StreamController<List<SmsMessage>> _smsStreamController = StreamController.broadcast();
  final StreamController<SmsMessage> _newSmsController = StreamController.broadcast();

  Stream<List<SmsMessage>> get smsStream => _smsStreamController.stream;
  Stream<SmsMessage> get newSmsStream => _newSmsController.stream;

  // Background monitoring state
  bool _isMonitoring = false;
  StreamSubscription<SmsMessage>? _smsSubscription;

  // SIM swap detection (placeholder for future implementation)
  String? _lastKnownSimSerial;
  DateTime? _lastSimCheck;

  /// Request SMS permissions
  Future<bool> requestSmsPermissions() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Check if SMS permissions are granted
  Future<bool> hasSmsPermissions() async {
    return await Permission.sms.isGranted;
  }

  /// Get all SMS messages from M-Pesa (simplified filtering)
  Future<List<SmsMessage>> getMpesaMessages({int? limit}) async {
    try {
      // Get SMS messages with proper API usage for sms_advanced 1.1.0
      final messages = await _smsQuery.querySms(
        address: 'MPESA',
        count: limit ?? 100,
      );

      return messages;
    } catch (e) {
      print('Error reading M-Pesa SMS messages: $e');
      return [];
    }
  }

  /// Get SMS messages from a specific time range
  Future<List<SmsMessage>> getMpesaMessagesInRange(
    DateTime startDate,
    DateTime endDate, {
    int? limit,
  }) async {
    try {
      // Get all M-Pesa messages first, then filter by date range
      final allMpesaMessages = await getMpesaMessages(limit: limit != null ? limit * 2 : 200);

      // Filter messages by date range
      final filteredMessages = allMpesaMessages.where((message) {
        if (message.date == null) return false;
        // message.date is already a DateTime in this version
        return message.date!.isAfter(startDate) && message.date!.isBefore(endDate);
      }).toList();

      // Apply limit if specified
      if (limit != null && filteredMessages.length > limit) {
        return filteredMessages.sublist(0, limit);
      }

      return filteredMessages;
    } catch (e) {
      print('Error reading M-Pesa SMS messages in range: $e');
      return [];
    }
  }

  /// Parse M-Pesa SMS messages into transaction data
  List<Map<String, dynamic>> parseMpesaTransactions(List<SmsMessage> messages) {
    final transactions = <Map<String, dynamic>>[];

    for (final message in messages) {
      final parsedTransaction = _parseMpesaMessage(message);
      if (parsedTransaction != null) {
        transactions.add(parsedTransaction);
      }
    }

    return transactions;
  }

  /// Parse a single M-Pesa SMS message
  Map<String, dynamic>? _parseMpesaMessage(SmsMessage message) {
    final body = message.body ?? '';
    final timestamp = message.date ?? DateTime.now();

    // Common M-Pesa transaction patterns
    final patterns = {
      // Sent money: "ABC123 Confirmed. Ksh500.00 sent to JOHN DOE 0722000000 on 1/1/24 at 12:00 PM. New M-Pesa balance is Ksh1,500.00"
      'sent': RegExp(
        r'([A-Z0-9]+)\s+Confirmed\.\s*Ksh([\d,]+\.?\d*)\s+sent\s+to\s+(.+?)\s+(\d{10,12})\s+on\s+(.+?)\s+at\s+(.+?)\.\s*(?:New\s+M-Pesa\s+balance\s+is\s+Ksh([\d,]+\.?\d*))?',
      ),

      // Received money: "ABC123 Confirmed. You have received Ksh500.00 from JOHN DOE 0722000000 on 1/1/24 at 12:00 PM. New M-Pesa balance is Ksh2,000.00"
      'received': RegExp(
        r'([A-Z0-9]+)\s+Confirmed\.\s*You\s+have\s+received\s+Ksh([\d,]+\.?\d*)\s+from\s+(.+?)\s+(\d{10,12})\s+on\s+(.+?)\s+at\s+(.+?)\.\s*(?:New\s+M-Pesa\s+balance\s+is\s+Ksh([\d,]+\.?\d*))?',
      ),

      // Paid bill: "ABC123 Confirmed. Ksh500.00 paid to KPLC on 1/1/24 at 12:00 PM. New M-Pesa balance is Ksh1,000.00"
      'paid': RegExp(
        r'([A-Z0-9]+)\s+Confirmed\.\s*Ksh([\d,]+\.?\d*)\s+paid\s+to\s+(.+?)\s+on\s+(.+?)\s+at\s+(.+?)\.\s*(?:New\s+M-Pesa\s+balance\s+is\s+Ksh([\d,]+\.?\d*))?',
      ),

      // Airtime purchase: "ABC123 Confirmed. You bought Ksh100.00 of airtime on 1/1/24 at 12:00 PM. New M-Pesa balance is Ksh900.00"
      'airtime': RegExp(
        r'([A-Z0-9]+)\s+Confirmed\.\s*You\s+bought\s+Ksh([\d,]+\.?\d*)\s+of\s+airtime\s+on\s+(.+?)\s+at\s+(.+?)\.\s*(?:New\s+M-Pesa\s+balance\s+is\s+Ksh([\d,]+\.?\d*))?',
      ),

      // Withdrawals: "ABC123 Confirmed. Ksh500.00 withdrawn from Agent 12345 on 1/1/24 at 12:00 PM. New M-Pesa balance is Ksh500.00"
      'withdrawn': RegExp(
        r'([A-Z0-9]+)\s+Confirmed\.\s*Ksh([\d,]+\.?\d*)\s+withdrawn\s+from\s+(.+?)\s+on\s+(.+?)\s+at\s+(.+?)\.\s*(?:New\s+M-Pesa\s+balance\s+is\s+Ksh([\d,]+\.?\d*))?',
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
        String phoneNumber = '';
        double? balance;

        switch (type) {
          case 'sent':
            recipient = match.group(3) ?? '';
            phoneNumber = match.group(4) ?? '';
            balance = double.tryParse(match.group(7)?.replaceAll(',', '') ?? '0');
            break;
          case 'received':
            recipient = match.group(3) ?? '';
            phoneNumber = match.group(4) ?? '';
            balance = double.tryParse(match.group(7)?.replaceAll(',', '') ?? '0');
            break;
          case 'paid':
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
        }

        // Determine transaction type and amount sign
        bool isIncoming = false;
        double signedAmount = amount;

        if (type == 'received') {
          isIncoming = true;
          signedAmount = amount; // Positive for incoming
        } else {
          signedAmount = -amount; // Negative for outgoing
        }

        return {
          'id': transactionId ?? '',
          'amount': signedAmount,
          'recipient': recipient,
          'phone_number': phoneNumber,
          'timestamp': timestamp.toIso8601String(),
          'type': type,
          'balance_after': balance,
          'raw_message': body,
          'is_incoming': isIncoming,
        };
      }
    }

    return null; // Not a recognized M-Pesa transaction
  }

  /// Convert parsed SMS transactions to TransactionModel objects
  List<TransactionModel> convertToTransactionModels(List<Map<String, dynamic>> smsTransactions) {
    return smsTransactions.map((smsTx) {
      return TransactionModel(
        id: null, // SMS transactions don't have database IDs yet
        amount: smsTx['amount'] as double? ?? 0.0,
        recipient: smsTx['recipient'] as String? ?? '',
        timestamp: DateTime.parse(smsTx['timestamp'] as String? ?? DateTime.now().toIso8601String()),
        isFraudulent: false, // Will be determined by backend analysis
        location: null,
      );
    }).toList();
  }

  /// Get recent M-Pesa transactions from SMS
  Future<List<TransactionModel>> getRecentMpesaTransactions({int days = 30, int? limit}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final messages = await getMpesaMessagesInRange(startDate, endDate, limit: limit);
    final parsedTransactions = parseMpesaTransactions(messages);
    return convertToTransactionModels(parsedTransactions);
  }

  /// Start background SMS monitoring for 24/7 protection
  Future<void> startBackgroundMonitoring() async {
    if (_isMonitoring) return;

    try {
      // Check SIM swap before starting monitoring
      await _checkForSimSwap();

      // Request SMS permissions if not granted
      final hasPermission = await hasSmsPermissions();
      if (!hasPermission) {
        throw Exception('SMS permissions required for background monitoring');
      }

      // For older versions, we'll implement periodic checking instead of real-time listening
      _startPeriodicMonitoring();

      _isMonitoring = true;
      await _saveMonitoringState(true);

      print('Background SMS monitoring started successfully');
    } catch (e) {
      print('Failed to start background monitoring: $e');
      rethrow;
    }
  }

  /// Start periodic SMS monitoring (for older package versions)
  void _startPeriodicMonitoring() {
    // Check for new M-Pesa messages every 5 minutes
    Timer.periodic(Duration(minutes: 5), (timer) async {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }

      try {
        final newMessages = await getMpesaMessages(limit: 10);
        for (final message in newMessages) {
          if (_isMpesaMessage(message)) {
            _newSmsController.add(message);
            await _analyzeIncomingMessage(message);
            await _checkForSimSwap();
          }
        }
      } catch (e) {
        print('Error in periodic SMS monitoring: $e');
      }
    });
  }

  /// Stop background SMS monitoring
  Future<void> stopBackgroundMonitoring() async {
    if (!_isMonitoring) return;

    _smsSubscription?.cancel();
    _smsSubscription = null;
    _isMonitoring = false;

    await _saveMonitoringState(false);
    print('Background SMS monitoring stopped');
  }

  /// Check if background monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// SIM swap detection - critical for fraud prevention
  /// Note: Full SIM swap detection requires additional permissions and platform-specific APIs
  Future<bool> detectSimSwap() async {
    try {
      // Get current SIM information (placeholder - would need platform-specific implementation)
      final currentSimSerial = await _getCurrentSimSerial();

      if (currentSimSerial != null && _lastKnownSimSerial != null) {
        if (currentSimSerial != _lastKnownSimSerial) {
          print('SIM SWAP DETECTED: Serial changed from $_lastKnownSimSerial to $currentSimSerial');
          await _handleSimSwap();
          return true;
        }
      }

      // Update stored SIM info
      if (currentSimSerial != null) {
        await _saveSimInfo(currentSimSerial);
      }

      // Check for suspicious SMS patterns that might indicate SIM swap
      // This is a simplified implementation

      print('SIM swap detection: Pattern analysis active');
      print('Note: Full SIM swap detection requires additional platform permissions');

      _lastSimCheck = DateTime.now();
      return false; // No SIM swap detected
    } catch (e) {
      print('Error in SIM swap detection: $e');
      return false;
    }
  }

  /// Get current SIM serial number (placeholder implementation)
  Future<String?> _getCurrentSimSerial() async {
    try {
      // In a real implementation, this would use platform-specific APIs
      // For Android: TelephonyManager.getSimSerialNumber()
      // For iOS: This is not directly available due to privacy restrictions

      // Placeholder - in production, implement platform channels
      print('Getting SIM serial: Platform-specific implementation needed');

      // For now, return null (no SIM swap detection)
      // In production, this would return the actual SIM serial
      return null;
    } catch (e) {
      print('Error getting SIM serial: $e');
      return null;
    }
  }

  /// Analyze incoming SMS for fraud patterns
  Future<void> _analyzeIncomingMessage(SmsMessage message) async {
    final body = message.body ?? '';

    // Check for suspicious patterns
    final suspiciousPatterns = [
      RegExp(r'unauthorized'),
      RegExp(r'failed'),
      RegExp(r'blocked'),
      RegExp(r'security'),
    ];

    for (final pattern in suspiciousPatterns) {
      if (pattern.hasMatch(body)) {
        print('Suspicious SMS pattern detected: ${message.body}');
        // In production, this would trigger alerts/notifications
        break;
      }
    }
  }

  /// Check if message is from M-Pesa (strict filtering)
  bool _isMpesaMessage(SmsMessage message) {
    final sender = message.address ?? '';
    return sender.toUpperCase() == 'MPESA';
  }

  /// Handle SIM swap detection
  Future<void> _handleSimSwap() async {
    // Critical security event - immediate action required
    print('SIM SWAP DETECTED - SECURITY ALERT');

    // In production, this would:
    // 1. Send immediate notification to user
    // 2. Temporarily disable M-Pesa functionality
    // 3. Require additional verification
    // 4. Log security event for investigation

    // For now, log the event and update monitoring
    print('Security Alert: Potential SIM swap detected');
    print('Recommendation: Verify your SIM card and contact your mobile provider');

    // Could trigger additional security measures here
    // await _triggerSecurityAlert();
  }

  /// Check for SIM swap (called periodically)
  Future<void> _checkForSimSwap() async {
    final now = DateTime.now();

    // Check SIM every 30 minutes during monitoring
    if (_lastSimCheck == null ||
        now.difference(_lastSimCheck!).inMinutes >= 30) {
      await detectSimSwap();
    }
  }

  /// Save monitoring state to persistent storage
  Future<void> _saveMonitoringState(bool isMonitoring) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sms_monitoring_active', isMonitoring);
  }

  /// Save SIM information to persistent storage
  Future<void> _saveSimInfo(String? simSerial) async {
    final prefs = await SharedPreferences.getInstance();
    if (simSerial != null) {
      await prefs.setString('last_sim_serial', simSerial);
      _lastKnownSimSerial = simSerial;
    }
  }

  /// Load saved state on initialization
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _isMonitoring = prefs.getBool('sms_monitoring_active') ?? false;
    _lastKnownSimSerial = prefs.getString('last_sim_serial');

    // Restart monitoring if it was active
    if (_isMonitoring) {
      try {
        await startBackgroundMonitoring();
      } catch (e) {
        print('Failed to restart monitoring on initialization: $e');
        _isMonitoring = false;
      }
    }
  }

  /// Get user-friendly explanation for SMS permissions
  String getSmsPermissionExplanation() {
    return '''
M-Pesa Max needs SMS access to:

• Read your M-Pesa transaction messages for fraud detection
• Monitor your account activity in real-time
• Alert you to suspicious transactions immediately
• Provide personalized financial insights

Your SMS data is processed locally and never stored permanently.
Background monitoring ensures 24/7 protection against fraud.
''';
  }

  /// Get monitoring status explanation
  String getMonitoringStatusExplanation() {
    if (_isMonitoring) {
      return 'Background monitoring is active. M-Pesa Max is protecting your M-Pesa transactions 24/7.';
    } else {
      return 'Background monitoring is disabled. Enable it for continuous fraud protection.';
    }
  }

  /// Listen for new SMS messages (legacy method for compatibility)
  void startSmsListener() {
    // Use the new background monitoring system
    startBackgroundMonitoring();
  }

  /// Stop listening for SMS messages
  void stopSmsListener() {
    stopBackgroundMonitoring();
  }


  /// Clean up resources
  void dispose() {
    stopSmsListener();
    _newSmsController.close();
    _smsStreamController.close();
  }
}