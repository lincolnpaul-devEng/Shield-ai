import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/fraud_check_result.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';

class FraudProvider with ChangeNotifier {
  final ApiService _apiService;
  final UserProvider _userProvider;
  FraudCheckResult? _lastResult;
  bool _isChecking = false;

  FraudProvider(this._apiService, this._userProvider);

  FraudCheckResult? get lastResult => _lastResult;
  bool get isChecking => _isChecking;

  Future<FraudCheckResult> checkTransaction(TransactionModel transaction) async {
    final user = _userProvider.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    _isChecking = true;
    notifyListeners();

    try {
      final result = await _apiService.checkFraud(user.phone, transaction);
      _lastResult = result;
      return result;
    } catch (e) {
      throw Exception('Fraud check failed: $e');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }
}
