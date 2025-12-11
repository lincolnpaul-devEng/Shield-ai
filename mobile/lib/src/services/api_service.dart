import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/models.dart';

typedef RequestInterceptor = Future<http.BaseRequest> Function(http.BaseRequest request);
typedef ResponseInterceptor = Future<void> Function(http.StreamedResponse response);

enum HttpMethod { get, post, put, patch, delete }

class ApiService {
  final String baseUrl;
  final List<RequestInterceptor> _requestInterceptors = [];
  final List<ResponseInterceptor> _responseInterceptors = [];
  final http.Client _client;
  final Duration _timeout;
  final int _maxRetries;

  ApiService({
    required this.baseUrl,
    http.Client? client,
    Duration? timeout,
    int? maxRetries,
  }) : _client = client ?? http.Client(),
       _timeout = timeout ?? const Duration(seconds: 30),
       _maxRetries = maxRetries ?? 3 {

    // Default interceptor for JSON
    addRequestInterceptor((req) async {
      req.headers['Content-Type'] = 'application/json';
      req.headers['Accept'] = 'application/json';
      return req;
    });

    // Logging interceptor
    addRequestInterceptor((req) async {
      developer.log('API Request: ${req.method} ${req.url}', name: 'ApiService');
      if (req.method == 'POST' && req is http.Request) {
        developer.log('Request body: ${req.body}', name: 'ApiService');
      }
      return req;
    });

    addResponseInterceptor((res) async {
      developer.log('API Response: ${res.statusCode} for ${res.request?.method} ${res.request?.url}',
          name: 'ApiService');
      // You can implement auth refresh, rate limit handling here
      return;
    });
  }

  void addRequestInterceptor(RequestInterceptor interceptor) => _requestInterceptors.add(interceptor);
  void addResponseInterceptor(ResponseInterceptor interceptor) => _responseInterceptors.add(interceptor);

  Future<Map<String, dynamic>> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.Request('GET', uri);
    final streamed = await _send(request);
    return _decode(streamed);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.Request('POST', uri);
    request.body = jsonEncode(body);
    final streamed = await _send(request);
    return _decode(streamed);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.Request('PUT', uri);
    request.body = jsonEncode(body);
    final streamed = await _send(request);
    return _decode(streamed);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.Request('DELETE', uri);
    final streamed = await _send(request);
    return _decode(streamed);
  }

  Future<http.StreamedResponse> _send(http.BaseRequest originalRequest, {int? retryCount}) async {
    final attempts = retryCount ?? _maxRetries;

    for (int attempt = 0; attempt < attempts; attempt++) {
      try {
        // Create a fresh copy of the request for each attempt
        final request = _cloneRequest(originalRequest);

        // Apply request interceptors to the fresh request
        var processedRequest = request;
        for (final i in _requestInterceptors) {
          processedRequest = await i(processedRequest);
        }

        // Send request with timeout
        final streamed = await _client.send(processedRequest).timeout(_timeout);

        // Apply response interceptors
        for (final i in _responseInterceptors) {
          await i(streamed);
        }

        return streamed;
      } catch (e) {
        final isLastAttempt = attempt == attempts - 1;
        developer.log('API attempt ${attempt + 1} failed: $e', name: 'ApiService', error: e);

        if (isLastAttempt) {
          rethrow;
        }

        // Wait before retry (exponential backoff)
        await Future.delayed(Duration(seconds: 1 << attempt));
      }
    }

    throw Exception('All retry attempts failed');
  }

  /// Clone a request to create a fresh copy for retry attempts
  http.BaseRequest _cloneRequest(http.BaseRequest original) {
    if (original is http.Request) {
      final cloned = http.Request(original.method, original.url);
      cloned.headers.addAll(original.headers);
      if (original.body.isNotEmpty) {
        cloned.body = original.body;
      }
      return cloned;
    } else if (original is http.MultipartRequest) {
      final cloned = http.MultipartRequest(original.method, original.url);
      cloned.headers.addAll(original.headers);
      cloned.fields.addAll(original.fields);
      cloned.files.addAll(original.files);
      return cloned;
    } else {
      // For other request types, create a basic request
      final cloned = http.Request(original.method, original.url);
      cloned.headers.addAll(original.headers);
      return cloned;
    }
  }

  Future<Map<String, dynamic>> _decode(http.StreamedResponse response) async {
    final body = await response.stream.bytesToString();
    developer.log('Response body: $body', name: 'ApiService');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body.isEmpty) return <String, dynamic>{};
      try {
        return jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        developer.log('Failed to parse JSON response: $e', name: 'ApiService', error: e);
        throw ApiException(response.statusCode, 'Invalid JSON response: $body');
      }
    }

    // Handle specific error cases
    if (response.statusCode == 429) {
      throw ApiException(response.statusCode, 'Rate limit exceeded. Please try again later.');
    } else if (response.statusCode >= 500) {
      throw ApiException(response.statusCode, 'Server error. Please try again later.');
    } else if (response.statusCode == 401) {
      throw ApiException(response.statusCode, 'Authentication failed.');
    } else if (response.statusCode == 403) {
      throw ApiException(response.statusCode, 'Access forbidden.');
    }

    // Try to extract error message from response
    try {
      final errorData = jsonDecode(body) as Map<String, dynamic>;
      final errorMessage = errorData['message'] ?? errorData['error'] ?? body;
      throw ApiException(response.statusCode, errorMessage);
    } catch (_) {
      throw ApiException(response.statusCode, body.isEmpty ? 'Unknown error' : body);
    }
  }

  void dispose() {
    _client.close();
  }

  // Shield AI specific methods

  /// Check if a transaction is fraudulent
  Future<FraudCheckResult> checkFraud(String userId, TransactionModel transaction) async {
    try {
      final requestData = {
        'user_id': userId,
        'transaction': {
          'amount': transaction.amount,
          'recipient': transaction.recipient,
          'timestamp': transaction.timestamp.toIso8601String(),
          if (transaction.location != null) 'location': transaction.location,
        }
      };

      final response = await post('/check-fraud', requestData);
      return FraudCheckResult.fromJson(response);
    } catch (e) {
      developer.log('checkFraud failed: $e', name: 'ApiService', error: e);
      // Return safe fallback result
      return FraudCheckResult(
        isFraud: false,
        confidence: 0.0,
        reason: 'Unable to check fraud status: ${e.toString()}',
        actionRequired: false,
      );
    }
  }

  /// Get user's transaction history
  Future<List<TransactionModel>> getUserTransactions(String userId) async {
    try {
      final response = await get('/users/$userId/transactions');
      final transactionsData = response['transactions'] as List<dynamic>;
      return transactionsData
          .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('getUserTransactions failed: $e', name: 'ApiService', error: e);
      // Return empty list as fallback
      return [];
    }
  }

  /// Login a user
  Future<UserModel> loginUser(String phone, String pin) async {
    try {
      final requestData = {
        'phone': phone,
        'pin': pin,
      };

      final response = await post('/login', requestData);
      return UserModel.fromJson(response);
    } catch (e) {
      developer.log('loginUser failed: $e', name: 'ApiService', error: e);
      rethrow;
    }
  }

  /// Register a new user
  Future<UserModel> registerUser(UserModel userData, String pin) async {
    try {
      final requestData = userData.toJson();
      // Add the PIN to the request
      requestData['pin'] = pin;

      // Remove fields that shouldn't be sent in registration
      requestData.remove('id');
      requestData.remove('created_at');

      final response = await post('/users', requestData);
      return UserModel.fromJson(response);
    } catch (e) {
      developer.log('registerUser failed: $e', name: 'ApiService', error: e);
      // Re-throw the exception to be handled by the provider
      rethrow;
    }
  }

  /// Update user's M-Pesa balance
  Future<Map<String, dynamic>> updateMpesaBalance(String phone, double balance, String pin) async {
    try {
      final requestData = {
        'balance': balance,
        'pin': pin,
      };

      final response = await post('/users/$phone/balance', requestData);
      return response;
    } catch (e) {
      developer.log('updateMpesaBalance failed: $e', name: 'ApiService', error: e);
      rethrow;
    }
  }

  /// Ask AI a question about financial planning
  /// Ask AI a question about financial planning (M-Pesa Max)
Future<Map<String, dynamic>> askAI(String userId, String question, {List<Map<String, dynamic>>? conversationHistory}) async {
  try {
    final Map<String, dynamic> requestData = {
      'user_id': userId,
      'query': question,  // M-Pesa Max uses 'query' instead of 'question'
    };

    // Add conversation history if provided
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      requestData['conversation_history'] = conversationHistory;
    }

    final response = await post('/mpesa-max', requestData);  // Use M-Pesa Max endpoint
    return response;
  } catch (e) {
    developer.log('askAI failed: $e', name: 'ApiService', error: e);
    rethrow;
  }
}
}

class ApiException implements Exception {
  final int statusCode;
  final String responseBody;
  ApiException(this.statusCode, this.responseBody);
  @override
  String toString() => 'ApiException($statusCode): $responseBody';
}
