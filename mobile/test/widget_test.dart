// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';
import 'package:mobile/src/services/api_service.dart';
import 'package:mobile/src/services/demo_service.dart';
import 'package:mobile/src/services/financial_strategist.dart';
import 'package:mobile/src/services/insights_service.dart';
import 'package:mobile/src/services/mpesa_sync_service.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final api = ApiService(baseUrl: 'http://localhost:5000/api');
    final demo = DemoService(api);
    final mpesaSync = MpesaSyncService();
    await mpesaSync.initialize();
    final financialStrategist = FinancialStrategist(apiKey: '');
    final insightsService = InsightsService();
    await tester.pumpWidget(ShieldAIApp(
      apiService: api,
      demoService: demo,
      mpesaSyncService: mpesaSync,
      financialStrategist: financialStrategist,
      insightsService: insightsService,
    ));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
