import 'package:flutter/foundation.dart';
import 'api_service.dart';

class DemoService {
  final ApiService _api;

  DemoService(this._api);

  /// Reset all demo data
  Future<Map<String, dynamic>> resetDemoData() async {
    try {
      final response = await _api.post('/demo/reset', {});
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('resetDemoData error: $e');
      }
      rethrow;
    }
  }

  /// Inject a fraudulent transaction for a specific scenario
  Future<Map<String, dynamic>> injectFraudScenario(String scenario, {String userKey = 'student_mary'}) async {
    try {
      final response = await _api.post('/demo/inject-fraud', {
        'scenario': scenario,
        'user_key': userKey,
      });
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('injectFraudScenario error: $e');
      }
      rethrow;
    }
  }

  /// Get demo status and statistics
  Future<Map<String, dynamic>> getDemoStatus() async {
    try {
      final response = await _api.get('/demo/status');
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('getDemoStatus error: $e');
      }
      rethrow;
    }
  }

  /// Get available demo scenarios
  Future<Map<String, dynamic>> getAvailableScenarios() async {
    try {
      final response = await _api.get('/demo/scenarios');
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('getAvailableScenarios error: $e');
      }
      rethrow;
    }
  }

  /// Predefined demo scenarios
  static const Map<String, Map<String, dynamic>> scenarios = {
    'student_large_amount_3am': {
      'title': 'Student Large Amount at 3 AM',
      'description': 'Student suddenly sends 45,000 KSH at 3 AM',
      'userKey': 'student_mary',
      'expectedFraud': true,
    },
    'business_rapid_transfers': {
      'title': 'Business Rapid Transfers',
      'description': 'Business account multiple rapid transfers',
      'userKey': 'business_david',
      'expectedFraud': true,
    },
    'new_recipient_large_amount': {
      'title': 'New Recipient Large Amount',
      'description': 'New recipient with large amount',
      'userKey': 'business_david',
      'expectedFraud': true,
    },
  };

  /// Demo user configurations
  static const Map<String, Map<String, dynamic>> demoUsers = {
    'student_mary': {
      'name': 'Student Mary',
      'phone': '+254712345678',
      'normalLimit': 2000.0,
      'description': 'Daily transactions < 2,000 KSH',
    },
    'business_david': {
      'name': 'Business David',
      'phone': '+254798765432',
      'normalLimit': 50000.0,
      'description': 'Transactions 5,000-50,000 KSH',
    },
    'mama_mboga_sarah': {
      'name': 'Mama Mboga Sarah',
      'phone': '+254711223344',
      'normalLimit': 5000.0,
      'description': 'Small frequent transactions',
    },
  };

  /// Run a complete demo flow with timing
  Future<List<Map<String, dynamic>>> runDemoFlow(String scenarioKey) async {
    final results = <Map<String, dynamic>>[];

    try {
      // Reset demo data first
      results.add({
        'step': 'reset',
        'status': 'running',
        'message': 'Resetting demo data...',
      });

      await resetDemoData();
      results.last['status'] = 'completed';

      // Wait a bit for backend to process
      await Future.delayed(const Duration(seconds: 1));

      // Inject fraud scenario
      results.add({
        'step': 'inject_fraud',
        'status': 'running',
        'message': 'Injecting fraudulent transaction...',
      });

      final injectResult = await injectFraudScenario(scenarioKey);
      results.last['status'] = 'completed';
      results.last['data'] = injectResult;

      // Wait for transaction to be processed
      await Future.delayed(const Duration(seconds: 2));

      // Get final status
      results.add({
        'step': 'status_check',
        'status': 'running',
        'message': 'Checking demo status...',
      });

      final status = await getDemoStatus();
      results.last['status'] = 'completed';
      results.last['data'] = status;

      return results;

    } catch (e) {
      // Mark any running steps as failed
      for (final result in results) {
        if (result['status'] == 'running') {
          result['status'] = 'failed';
          result['error'] = e.toString();
        }
      }
      rethrow;
    }
  }
}