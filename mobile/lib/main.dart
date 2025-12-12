import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/theme/app_theme.dart';
import 'src/providers/theme_provider.dart';
import 'src/routes/app_router.dart';
import 'src/services/api_service.dart';
import 'src/services/auth_token_service.dart';
import 'src/services/performance_monitor.dart';
import 'src/services/demo_service.dart';
import 'src/services/financial_strategist.dart';
import 'src/services/insights_service.dart';
import 'src/services/mpesa_sync_service.dart';
import 'src/services/notification_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'src/providers/demo_provider.dart';
import 'src/providers/financial_provider.dart';
import 'src/providers/fraud_provider.dart';
import 'src/providers/insights_provider.dart';
import 'src/providers/sms_provider.dart';
import 'src/providers/transaction_provider.dart';
import 'src/providers/user_provider.dart';
import 'src/config/performance_config.dart';
import 'src/config/device_config.dart';
import 'src/widgets/debug_overlay.dart';

Future<void> main() async {
  final startupStopwatch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  final performanceMonitor = PerformanceMonitor();

  await performanceMonitor.measureOperation(
    'notification_init',
    () => NotificationService.initialize(),
  );

  await performanceMonitor.measureOperation(
    'orientation_setup',
    () => SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
  );

  String getBaseUrl() {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (Platform.isAndroid) return 'http://10.0.2.2:5000/api';
    return 'http://localhost:5000/api';
  }

  final sharedPrefs = await performanceMonitor.measureOperation(
    'shared_prefs_init',
    () => SharedPreferences.getInstance(),
  );

  final tokenService = AuthTokenService();
  await performanceMonitor.measureOperation(
    'token_service_init',
    () => tokenService.init(),
  );

  final apiService = ApiService(baseUrl: getBaseUrl(), tokenService: tokenService);

  final demoService = DemoService(apiService);
  final mpesaSyncService = MpesaSyncService();

  await performanceMonitor.measureOperation(
    'mpesa_sync_init',
    () => mpesaSyncService.initialize(apiService),
  );

  final financialStrategist = FinancialStrategist(apiService);
  final insightsService = InsightsService();

  startupStopwatch.stop();
  performanceMonitor.measureSyncOperation('app_startup_complete', () {
    final startupTime = startupStopwatch.elapsed;
    if (startupTime > PerformanceConfig.targetStartupTime) {
      performanceMonitor.logPerformanceSummary();
    }
  });

  performanceMonitor.logPerformanceSummary();
  Timer.periodic(PerformanceConfig.performanceLogInterval, (_) {
    performanceMonitor.logPerformanceSummary();
  });

  runApp(
    ShieldAIApp(
      sharedPreferences: sharedPrefs,
      apiService: apiService,
      demoService: demoService,
      mpesaSyncService: mpesaSyncService,
      financialStrategist: financialStrategist,
      insightsService: insightsService,
    ),
  );
}

class ShieldAIApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;
  final ApiService apiService;
  final DemoService demoService;
  final MpesaSyncService mpesaSyncService;
  final FinancialStrategist financialStrategist;
  final InsightsService insightsService;

  const ShieldAIApp({
    super.key,
    required this.sharedPreferences,
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
        ChangeNotifierProvider(create: (_) => UserProvider(apiService)),
        ChangeNotifierProvider(create: (_) => TransactionProvider(apiService)),
        ChangeNotifierProxyProvider<UserProvider, FraudProvider>(
          create: (_) => FraudProvider(apiService, UserProvider(apiService)),
          update: (_, userProvider, __) => FraudProvider(apiService, userProvider),
        ),
        ChangeNotifierProvider(create: (_) => FinancialProvider(financialStrategist, apiService)),
        ChangeNotifierProvider(create: (_) => InsightsProvider(insightsService)),
        ChangeNotifierProvider(create: (_) => DemoProvider(demoService)),
        ChangeNotifierProvider(create: (_) => SmsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(sharedPreferences)),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = context.watch<ThemeProvider>();

          return DebugOverlay(
            child: MaterialApp(
              title: 'M-Pesa Max - Fraud Protection',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.isDarkMode
                  ? ThemeMode.dark
                  : ThemeMode.light,
              initialRoute: AppRouter.initialRoute,
              onGenerateRoute: AppRouter.onGenerateRoute,
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                final deviceType = DeviceConfig.getDeviceType(context);

                final textScale = switch (deviceType) {
                  DeviceType.smallPhone => 0.9,
                  DeviceType.normalPhone => 1.0,
                  DeviceType.largePhone => 1.05,
                  DeviceType.smallTablet => 1.1,
                  DeviceType.largeTablet => 1.15,
                };

                return MediaQuery(
                  data: mediaQuery.copyWith(
                    textScaler: TextScaler.linear(textScale),
                    devicePixelRatio: mediaQuery.devicePixelRatio.clamp(1.0, 4.0),
                    size: Size(
                      mediaQuery.size.width.clamp(320, 1200),
                      mediaQuery.size.height,
                    ),
                  ),
                  child: Builder(
                    builder: (context) => Theme(
                      data: Theme.of(context).copyWith(
                        textTheme: DeviceConfig.getOptimalTextTheme(context),
                        appBarTheme: DeviceConfig.getOptimalAppBarTheme(context),
                        iconTheme: DeviceConfig.getOptimalIconTheme(context),
                        buttonTheme: DeviceConfig.getOptimalButtonTheme(context),
                      ),
                      child: SafeArea(
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
                );
              },
              locale: const Locale('en', 'KE'),
              supportedLocales: const [
                Locale('en', 'KE'),
                Locale('sw', 'KE'),
              ],
            ),
          );
        },
      ),
    );
  }
}