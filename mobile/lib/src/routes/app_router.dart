import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/permissions_screen.dart';
import '../screens/main_navigation.dart';
import '../screens/demo_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/budget_creation_screen.dart';
import '../screens/send_money_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/financial_planning_screen.dart';
import '../screens/terms_of_service_screen.dart';
import '../screens/privacy_policy_screen.dart';

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
      case '/budget-creation':
        return MaterialPageRoute(builder: (_) => const BudgetCreationScreen());
      case '/send-money':
        return MaterialPageRoute(builder: (_) => const SendMoneyScreen());
      case '/transactions':
        return MaterialPageRoute(builder: (_) => const TransactionsScreen());
      case '/financial-planning':
        return MaterialPageRoute(builder: (_) => const FinancialPlanningScreen());
      case '/terms-of-service':
        return MaterialPageRoute(builder: (_) => const TermsOfServiceScreen());
      case '/privacy-policy':
        return MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen());
      case '/main':
        final args = settings.arguments as int?;
        return MaterialPageRoute(builder: (_) => MainNavigation(initialIndex: args ?? 0));
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
