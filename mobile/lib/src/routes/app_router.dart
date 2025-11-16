import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/permissions_screen.dart';
import '../screens/main_navigation.dart';
import '../screens/demo_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';

class AppRouter {
  static const initialRoute = '/splash';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/splash':
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const MainNavigation());
      case '/onboarding':
        return MaterialPageRoute(builder: (_) => OnboardingScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/permissions':
        return MaterialPageRoute(builder: (_) => const PermissionsScreen());
      case '/main':
        return MaterialPageRoute(builder: (_) => const MainNavigation());
      case '/demo':
        return MaterialPageRoute(builder: (_) => const DemoScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
