// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:shield_ai/main.dart';
import 'package:shield_ai/src/services/api_service.dart';
import 'package:shield_ai/src/services/demo_service.dart';
import 'package:shield_ai/src/services/financial_strategist.dart';
import 'package:shield_ai/src/services/insights_service.dart';
import 'package:shield_ai/src/services/mpesa_sync_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final api = ApiService(baseUrl: 'http://localhost:5000/api');
    final demo = DemoService(api);
    final mpesaSync = MpesaSyncService();
    await mpesaSync.initialize(api);
    final financialStrategist = FinancialStrategist(apiKey: '');
    final insightsService = InsightsService();
    await tester.pumpWidget(ShieldAIApp(
      apiService: api,
      demoService: demo,
      mpesaSyncService: mpesaSync,
      financialStrategist: financialStrategist,
      insightsService: insightsService,
    ));

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that the app builds without errors
    expect(find.byType(ShieldAIApp), findsOneWidget);
  });
}
