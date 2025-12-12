import 'package:flutter/foundation.dart';
import '../services/sms_reader_service.dart';
import '../models/transaction.dart';

class SmsProvider extends ChangeNotifier {
  final SmsReaderService _smsService = SmsReaderService();
  bool isMonitoring = false;
  List<Map<String, dynamic>> parsedSmsTransactions = [];
  double? latestBalance;
  String? error;

  SmsProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _smsService.initialize();
      // Start monitoring if permissions are granted
      final hasPermissions = await _smsService.hasSmsPermissions();
      if (hasPermissions) {
        await startSmsMonitoring();
      }
    } catch (e) {
      error = e.toString();
      if (kDebugMode) {
        print('SMS Provider initialization error: $e');
      }
    }
  }

  Future<bool> requestSmsPermissions() async {
    try {
      final granted = await _smsService.requestSmsPermissions();
      if (granted) {
        await startSmsMonitoring();
      }
      return granted;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  Future<void> startSmsMonitoring() async {
    if (isMonitoring) return;

    try {
      await _smsService.startBackgroundMonitoring();
      isMonitoring = true;
      error = null;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      if (kDebugMode) {
        print('Failed to start SMS monitoring: $e');
      }
    }
  }

  Future<void> stopSmsMonitoring() async {
    try {
      await _smsService.stopBackgroundMonitoring();
      isMonitoring = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
    }
  }

  Future<List<Map<String, dynamic>>> getParsedSmsTransactions({int days = 30}) async {
    try {
      final messages = await _smsService.getRecentMpesaTransactions(days: days);
      // Note: For SMS provider, we work with TransactionModel objects directly
      // The SMS parsing is handled in the service layer
      parsedSmsTransactions = messages.map((t) => {
        'id': t.id?.toString() ?? '',
        'amount': t.amount,
        'recipient': t.recipient,
        'phone_number': '',
        'timestamp': t.timestamp.toIso8601String(),
        'type': t.amount > 0 ? 'received' : 'sent',
        'balance_after': null, // Would need SMS parsing for this
        'raw_message': '',
        'is_incoming': t.amount > 0,
      }).toList();
      notifyListeners();
      return parsedSmsTransactions;
    } catch (e) {
      error = e.toString();
      return [];
    }
  }

  Future<double?> extractLatestBalance() async {
    try {
      final transactions = await getParsedSmsTransactions(days: 1);
      // Find the most recent transaction with balance info
      for (final tx in transactions) {
        final balance = tx['balance_after'] as double?;
        if (balance != null) {
          latestBalance = balance;
          notifyListeners();
          return balance;
        }
      }
      return null;
    } catch (e) {
      error = e.toString();
      return null;
    }
  }

  Future<List<TransactionModel>> getSmsTransactionsAsModels({int days = 30}) async {
    try {
      return await _smsService.getRecentMpesaTransactions(days: days);
    } catch (e) {
      error = e.toString();
      return [];
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}