import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'src/providers/demo_provider.dart';
import 'src/providers/financial_provider.dart';
import 'src/providers/fraud_provider.dart';
import 'src/providers/insights_provider.dart';
import 'src/providers/transaction_provider.dart';
import 'src/providers/user_provider.dart';
import 'src/routes/app_router.dart';
import 'src/services/api_service.dart';
import 'src/services/demo_service.dart';
import 'src/services/financial_strategist.dart';
import 'src/services/insights_service.dart';
import 'src/services/mpesa_sync_service.dart';
import 'src/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await NotificationService.initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Dependency injection setup
  final apiService = ApiService(baseUrl: const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api',
  ));

  final demoService = DemoService(apiService);

  // Initialize M-Pesa sync service
  final mpesaSyncService = MpesaSyncService();
  await mpesaSyncService.initialize();

  // Initialize financial strategist
  final financialStrategist = FinancialStrategist(
    apiKey: const String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: ''),
  );

  // Initialize insights service
  final insightsService = InsightsService();

  runApp(ShieldAIApp(
    apiService: apiService,
    demoService: demoService,
    mpesaSyncService: mpesaSyncService,
    financialStrategist: financialStrategist,
    insightsService: insightsService,
  ));
}

class ShieldAIApp extends StatelessWidget {
  final ApiService apiService;
  final DemoService demoService;
  final MpesaSyncService mpesaSyncService;
  final FinancialStrategist financialStrategist;
  final InsightsService insightsService;

  const ShieldAIApp({
    super.key,
    required this.apiService,
    required this.demoService,
    required this.mpesaSyncService,
    required this.financialStrategist,
    required this.insightsService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider(create: (_) => UserProvider(apiService)),
        ChangeNotifierProvider(create: (_) => TransactionProvider(apiService)),

        // Fraud provider depends on user provider
        ChangeNotifierProxyProvider<UserProvider, FraudProvider>(
          create: (_) => FraudProvider(apiService, UserProvider(apiService)),
          update: (_, userProvider, _) => FraudProvider(apiService, userProvider),
        ),

        // Financial planning provider
        ChangeNotifierProvider(create: (_) => FinancialProvider(financialStrategist)),

        // Insights provider
        ChangeNotifierProvider(create: (_) => InsightsProvider(insightsService)),

        // Demo provider for development
        ChangeNotifierProvider(create: (_) => DemoProvider(demoService)),
      ],
      child: MaterialApp(
        title: 'Shield AI - Fraud Protection',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.system,
        initialRoute: AppRouter.initialRoute,
        onGenerateRoute: AppRouter.onGenerateRoute,

        // Global error handling
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },

        // Localization (can be expanded later)
        locale: const Locale('en', 'KE'),
        supportedLocales: const [
          Locale('en', 'KE'),
          Locale('sw', 'KE'), // Swahili support for future
        ],
      ),
    );
  }

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.light,
      primary: const Color(0xFF007B3E), // Kenyan green
      secondary: const Color(0xFFFF6B35), // Orange accent
      error: const Color(0xFFD32F2F),
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Enhanced button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Enhanced input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Enhanced snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.dark,
      primary: const Color(0xFF4CAF50),
      secondary: const Color(0xFFFF8A65),
      error: const Color(0xFFEF5350),
      surface: const Color(0xFF1E1E1E),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onError: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // Similar customizations for dark theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        centerTitle: true,
      ),


      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
