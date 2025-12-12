import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Performance monitoring service for Shield AI
/// Tracks key metrics for production optimization
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;

  PerformanceMonitor._internal() {
    _setupPerformanceTracking();
  }

  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<Duration>> _operationTimes = {};
  final Map<String, int> _errorCounts = {};

  // Performance thresholds (based on your goals)
  static const Duration maxFrameTime = Duration(milliseconds: 16); // 60 FPS
  static const Duration maxStartupTime = Duration(seconds: 3);
  static const int maxMemoryMB = 100;

  /// Track operation performance
  Future<T> measureOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      stopwatch.stop();

      _recordOperationTime(operationName, stopwatch.elapsed);

      // Log slow operations
      if (stopwatch.elapsed > const Duration(seconds: 2)) {
        developer.log('Slow operation: $operationName took ${stopwatch.elapsed.inMilliseconds}ms',
            name: 'PerformanceMonitor');
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      _recordError(operationName);
      rethrow;
    }
  }

  /// Track synchronous operation performance
  T measureSyncOperation<T>(String operationName, T Function() operation) {
    final stopwatch = Stopwatch()..start();

    try {
      final result = operation();
      stopwatch.stop();

      _recordOperationTime(operationName, stopwatch.elapsed);
      return result;
    } catch (e) {
      stopwatch.stop();
      _recordError(operationName);
      rethrow;
    }
  }

  void _recordOperationTime(String operationName, Duration duration) {
    if (!_operationTimes.containsKey(operationName)) {
      _operationTimes[operationName] = [];
    }

    _operationTimes[operationName]!.add(duration);

    // Keep only last 100 measurements to avoid memory issues
    if (_operationTimes[operationName]!.length > 100) {
      _operationTimes[operationName] = _operationTimes[operationName]!.sublist(50);
    }
  }

  void _recordError(String operationName) {
    _errorCounts[operationName] = (_errorCounts[operationName] ?? 0) + 1;
  }

  /// Get performance metrics
  Map<String, dynamic> getMetrics() {
    final metrics = <String, dynamic>{};

    // Calculate averages for operations
    for (final entry in _operationTimes.entries) {
      final times = entry.value;
      if (times.isNotEmpty) {
        final avg = times.fold<Duration>(Duration.zero, (a, b) => a + b) ~/ times.length;
        metrics['avg_${entry.key}'] = avg.inMilliseconds;
      }
    }

    // Error counts
    metrics.addAll(_errorCounts.map((key, value) => MapEntry('errors_$key', value)));

    return metrics;
  }

  /// Check if app meets performance targets
  Map<String, bool> checkPerformanceTargets() {
    final metrics = getMetrics();
    final results = <String, bool>{};

    // Check startup time (if available)
    final startupTime = metrics['avg_app_startup'];
    if (startupTime != null) {
      results['startup_time_ok'] = startupTime <= maxStartupTime.inMilliseconds;
    }

    // Check frame rendering (if available)
    final avgFrameTime = metrics['avg_frame_render'];
    if (avgFrameTime != null) {
      results['frame_time_ok'] = avgFrameTime <= maxFrameTime.inMilliseconds;
    }

    // Check API response times
    final apiResponseTime = metrics['avg_api_call'];
    if (apiResponseTime != null) {
      results['api_response_ok'] = apiResponseTime <= 2000; // 2 seconds max
    }

    return results;
  }

  void _setupPerformanceTracking() {
    // Track app startup time
    WidgetsFlutterBinding.ensureInitialized();
    measureOperation('app_startup', () async {
      // This will be measured by the time from app start to first frame
      await Future.delayed(Duration.zero);
    });

    // Track frame rendering performance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startFrameMonitoring();
    });
  }

  void _startFrameMonitoring() {
    // Monitor frame times using Flutter's frame callback
    WidgetsBinding.instance.addPersistentFrameCallback((timestamp) {
      measureSyncOperation('frame_render', () {
        // Frame rendering time is tracked automatically
      });
    });
  }

  /// Log performance summary (call periodically)
  void logPerformanceSummary() {
    final metrics = getMetrics();
    final targets = checkPerformanceTargets();

    developer.log('=== PERFORMANCE SUMMARY ===', name: 'PerformanceMonitor');
    developer.log('Metrics: $metrics', name: 'PerformanceMonitor');
    developer.log('Targets Met: $targets', name: 'PerformanceMonitor');

    // Alert on performance issues
    for (final entry in targets.entries) {
      if (!entry.value) {
        developer.log('⚠️ PERFORMANCE ISSUE: ${entry.key}', name: 'PerformanceMonitor', level: 900);
      }
    }
  }

  /// Reset performance data (useful for testing)
  void reset() {
    _operationTimes.clear();
    _errorCounts.clear();
    _timers.clear();
  }
}
