import 'package:flutter/foundation.dart';
import '../services/demo_service.dart';

class DemoProvider with ChangeNotifier {
  final DemoService _demoService;

  bool _isDeveloperMode = false;
  bool _isRunningDemo = false;
  Map<String, dynamic>? _demoStatus;
  List<Map<String, dynamic>> _demoFlowResults = [];
  String? _error;

  DemoProvider(this._demoService);

  // Getters
  bool get isDeveloperMode => _isDeveloperMode;
  bool get isRunningDemo => _isRunningDemo;
  Map<String, dynamic>? get demoStatus => _demoStatus;
  List<Map<String, dynamic>> get demoFlowResults => _demoFlowResults;
  String? get error => _error;

  // Toggle developer mode
  void toggleDeveloperMode() {
    _isDeveloperMode = !_isDeveloperMode;
    notifyListeners();
  }

  // Reset demo data
  Future<void> resetDemoData() async {
    _error = null;
    try {
      final result = await _demoService.resetDemoData();
      await _refreshDemoStatus();
      if (kDebugMode) {
        print('Demo data reset: $result');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Reset demo data error: $e');
      }
    }
    notifyListeners();
  }

  // Run a complete demo flow
  Future<void> runDemoFlow(String scenarioKey) async {
    if (_isRunningDemo) return;

    _isRunningDemo = true;
    _error = null;
    _demoFlowResults = [];
    notifyListeners();

    try {
      _demoFlowResults = await _demoService.runDemoFlow(scenarioKey);
      await _refreshDemoStatus();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Run demo flow error: $e');
      }
    } finally {
      _isRunningDemo = false;
      notifyListeners();
    }
  }

  // Inject fraud scenario
  Future<void> injectFraudScenario(String scenario, {String userKey = 'student_mary'}) async {
    _error = null;
    try {
      final result = await _demoService.injectFraudScenario(scenario, userKey: userKey);
      await _refreshDemoStatus();
      if (kDebugMode) {
        print('Fraud injected: $result');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Inject fraud error: $e');
      }
    }
    notifyListeners();
  }

  // Refresh demo status
  Future<void> refreshDemoStatus() async {
    await _refreshDemoStatus();
  }

  Future<void> _refreshDemoStatus() async {
    try {
      _demoStatus = await _demoService.getDemoStatus();
    } catch (e) {
      if (kDebugMode) {
        print('Refresh demo status error: $e');
      }
      _demoStatus = null;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear demo flow results
  void clearDemoFlowResults() {
    _demoFlowResults = [];
    notifyListeners();
  }
}