import 'package:shared_preferences/shared_preferences.dart';

/// Simple secure-ish token storage using SharedPreferences.
/// In production, prefer platform secure storage for access/refresh tokens.
class AuthTokenService {
  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _accessExpiryKey = 'auth_access_expiry';

  late final SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    int? expiresInSeconds,
  }) async {
    _ensureInit();
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
    if (expiresInSeconds != null) {
      final expiry =
          DateTime.now().add(Duration(seconds: expiresInSeconds)).toIso8601String();
      await _prefs.setString(_accessExpiryKey, expiry);
    }
  }

  Future<String?> getAccessToken() async {
    _ensureInit();
    return _prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    _ensureInit();
    return _prefs.getString(_refreshTokenKey);
  }

  Future<bool> isAccessTokenExpired() async {
    _ensureInit();
    final expiry = _prefs.getString(_accessExpiryKey);
    if (expiry == null) return false;
    return DateTime.tryParse(expiry)?.isBefore(DateTime.now()) ?? false;
  }

  Future<void> clear() async {
    _ensureInit();
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_accessExpiryKey);
  }

  void _ensureInit() {
    if (!_initialized) {
      throw StateError('AuthTokenService not initialized. Call init() first.');
    }
  }
}

