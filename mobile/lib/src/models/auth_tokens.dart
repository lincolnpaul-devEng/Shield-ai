import 'user.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int? expiresIn;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn,
  });
}

class AuthSession {
  final UserModel user;
  final AuthTokens tokens;

  AuthSession({required this.user, required this.tokens});
}

