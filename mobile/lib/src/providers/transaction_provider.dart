import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/fraud_check_result.dart';
import '../services/api_service.dart';

class TransactionProvider extends ChangeNotifier {
  final ApiService _api;
  List<TransactionModel> transactions = [];
  bool isLoading = false;
  String? error;

  TransactionProvider(this._api);

  Future<void> loadTransactions(String userId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      transactions = await _api.getUserTransactions(userId);
      error = null;
    } catch (e) {
      error = e.toString();
      if (kDebugMode) {
        print('loadTransactions error: $e');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<FraudCheckResult?> addTransaction(String userId, TransactionModel transaction) async {
    try {
      final fraudResult = await _api.checkFraud(userId, transaction);
      // Refresh transactions after adding
      await loadTransactions(userId);
      return fraudResult;
    } catch (e) {
      error = e.toString();
      if (kDebugMode) {
        print('addTransaction error: $e');
      }
      notifyListeners();
      return null;
    }
  }

  // Keep backward compatibility
  Future<void> fetchTransactions(String userId) async {
    await loadTransactions(userId);
  }
}
