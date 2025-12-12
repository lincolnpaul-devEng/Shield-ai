import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'auth_token_service.dart';
import 'performance_monitor.dart';

import 'api_service.dart';

/// Optimized API service with caching, retry logic, and performance monitoring
/// Wraps the existing ApiService for full compatibility while adding optimizations
class OptimizedApiService {
  final ApiService _baseApiService;
  final PerformanceMonitor _performanceMonitor;
  final SharedPreferences _prefs;
  final AuthTokenService _authTokenService;
  final String baseUrl;

  // Additional caching beyond base ApiService
  final Map<String, CacheEntry> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  OptimizedApiService({
    required this.baseUrl,
    required AuthTokenService authTokenService,
    required SharedPreferences prefs,
    required PerformanceMonitor performanceMonitor,
  })  : _authTokenService = authTokenService,
        _performanceMonitor = performanceMonitor,
        _prefs = prefs,
        _baseApiService = ApiService(baseUrl: baseUrl, tokenService: authTokenService);

  // Optimized method overrides
  Future<Map<String, dynamic>> get(String path) async => getCached(path);
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async => postOptimized(path, body);
  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async => _makeRequestWithRetry('PUT', path, body: body);
  Future<Map<String, dynamic>> delete(String path) async => _makeRequestWithRetry('DELETE', path);

  // Delegate other methods to base service
  Future<FraudCheckResult> checkFraud(String userId, TransactionModel transaction) async {
    return checkFraudCached(userId, transaction);
  }

  Future<List<TransactionModel>> getUserTransactions(String userId) async {
    return getUserTransactionsOptimized(userId);
  }

  Future<AuthSession> loginUser(String phone, String pin) async => _baseApiService.loginUser(phone, pin);
  Future<UserModel> registerUser(UserModel userData, String pin) async => _baseApiService.registerUser(userData, pin);
  Future<Map<String, dynamic>> updateMpesaBalance(String phone, double balance) async => _baseApiService.updateMpesaBalance(phone, balance);
  Future<Map<String, dynamic>> askAI(String userId, String question, {List<Map<String, dynamic>>? conversationHistory}) async =>
    _baseApiService.askAI(userId, question, conversationHistory: conversationHistory);

  /// Cached GET request with performance monitoring
  Future<Map<String, dynamic>> getCached(String path) async {
    return _performanceMonitor.measureOperation('api_get_cached', () async {
      // Check cache first
      final cacheKey = 'GET:$path';
      final cached = _getFromCache(cacheKey);
      if (cached != null) {
        developer.log('Cache hit for $path', name: 'OptimizedApiService');
        return cached;
      }

      // Make request and cache result
      final result = await _makeAuthenticatedRequest('GET', path);
      _setCache(cacheKey, result);
      return result;
    });
  }

  /// Optimized POST with retry logic
  Future<Map<String, dynamic>> postOptimized(String path, Map<String, dynamic> body) async {
    return _performanceMonitor.measureOperation('api_post_optimized', () async {
      return _makeRequestWithRetry('POST', path, body: body);
    });
  }

  /// Core request method with authentication and error handling
  Future<Map<String, dynamic>> _makeAuthenticatedRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    // Get current access token
    final accessToken = await _authTokenService.getAccessToken();
    if (accessToken == null) {
      throw Exception('No authentication token available');
    }

    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
    };

    final request = http.Request(method, uri)
      ..headers.addAll(headers);

    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamedResponse = await http.Client().send(request);
    return _handleResponse(streamedResponse, uri);
  }

  /// Request with intelligent retry logic
  Future<Map<String, dynamic>> _makeRequestWithRetry(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    int attempts = 0;
    Exception? lastError;

    while (attempts < _maxRetries) {
      try {
        return await _makeAuthenticatedRequest(method, path,
            body: body, queryParams: queryParams);
      } catch (e) {
        lastError = e as Exception;
        attempts++;

        // Don't retry on authentication errors
        if (e.toString().contains('401') || e.toString().contains('403')) {
          rethrow;
        }

        // Exponential backoff
        if (attempts < _maxRetries) {
          await Future.delayed(_retryDelay * attempts);
        }
      }
    }

    throw lastError ?? Exception('Request failed after $_maxRetries attempts');
  }

  Future<Map<String, dynamic>> _handleResponse(http.StreamedResponse response, Uri uri) async {
    final body = await response.stream.bytesToString();

    // Handle token refresh on 401
    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        // Retry the original request once with new token
        return _makeAuthenticatedRequest(response.request!.method, uri.path);
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body.isEmpty) return {};
      return jsonDecode(body) as Map<String, dynamic>;
    }

    // Enhanced error handling
    if (response.statusCode == 429) {
      throw Exception('Rate limit exceeded. Please try again later.');
    } else if (response.statusCode >= 500) {
      throw Exception('Server error. Please try again later.');
    }

    throw Exception('API Error ${response.statusCode}: $body');
  }

  /// Attempt to refresh access token
  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _authTokenService.getRefreshToken();
      if (refreshToken == null) return false;

      final refreshUri = Uri.parse('$baseUrl/auth/refresh');
      final response = await http.post(
        refreshUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access_token'];
        final expiresIn = data['expires_in'] ?? 3600;

        await _authTokenService.saveTokens(
          accessToken: newAccessToken,
          refreshToken: refreshToken, // Keep same refresh token
          expiresInSeconds: expiresIn,
        );
        return true;
      }
    } catch (e) {
      developer.log('Token refresh failed: $e', name: 'OptimizedApiService');
    }
    return false;
  }

  // Cache management
  Map<String, dynamic>? _getFromCache(String key) {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      return entry.data;
    } else if (entry != null) {
      _cache.remove(key); // Remove expired entry
    }
    return null;
  }

  void _setCache(String key, Map<String, dynamic> data) {
    _cache[key] = CacheEntry(data: data, timestamp: DateTime.now());
  }

  /// Clear cache (useful for logout or data refresh)
  void clearCache() {
    _cache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cache_size': _cache.length,
      'cache_keys': _cache.keys.toList(),
    };
  }

  // Shield AI specific optimized methods

  /// Check fraud with caching (fraud results don't change often)
  Future<FraudCheckResult> checkFraudCached(String userId, TransactionModel transaction) async {
    final cacheKey = 'fraud_check_${transaction.id ?? transaction.timestamp.millisecondsSinceEpoch}';

    // Check cache first (fraud checks are expensive)
    final cached = _getFromCache(cacheKey);
    if (cached != null) {
      return FraudCheckResult.fromJson(cached);
    }

    // Make the request
    final requestData = {
      'user_id': userId,
      'transaction': {
        'amount': transaction.amount,
        'recipient': transaction.recipient,
        'timestamp': transaction.timestamp.toIso8601String(),
        if (transaction.location != null) 'location': transaction.location,
      }
    };

    final response = await postOptimized('/check-fraud', requestData);
    final result = FraudCheckResult.fromJson(response);

    // Cache fraud results for 1 hour (they don't change)
    _setCache(cacheKey, response);
    final cacheEntry = _cache[cacheKey]!;
    cacheEntry.expiry = DateTime.now().add(Duration(hours: 1));

    return result;
  }

  /// Get transactions with smart caching
  Future<List<TransactionModel>> getUserTransactionsOptimized(String userId) async {
    final cacheKey = 'transactions_$userId';

    // Check cache (transactions change, but we can cache for short time)
    final cached = _getFromCache(cacheKey);
    if (cached != null && cached['transactions'] != null) {
      final transactions = (cached['transactions'] as List)
          .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return transactions;
    }

    // Make request
    final response = await getCached('/users/$userId/transactions');
    final transactions = (response['transactions'] as List)
        .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
        .toList();

    // Cache for 2 minutes (balance updates frequently)
    _setCache(cacheKey, response);
    final cacheEntry = _cache[cacheKey]!;
    cacheEntry.expiry = DateTime.now().add(Duration(minutes: 2));

    return transactions;
  }
}

/// Cache entry with expiry
class CacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  Duration? customExpiry;
  DateTime? expiry;

  CacheEntry({
    required this.data,
    required this.timestamp,
    this.customExpiry,
  }) {
    expiry = timestamp.add(customExpiry ?? OptimizedApiService._cacheDuration);
  }

  bool get isExpired => DateTime.now().isAfter(expiry!);
}
