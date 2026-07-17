import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:margin/screens/dashboard_screen.dart';
import 'package:margin/providers/margin_provider.dart';
import 'package:margin/services/api_service.dart';
import 'package:margin/services/feedback_service.dart';
import 'package:margin/services/wearable_service.dart';
import 'package:margin/services/calendar_service.dart';
import 'package:margin/services/preferences_service.dart';
import 'package:margin/services/ai_response_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Margin app smoke test', (WidgetTester tester) async {
    // Build the dashboard screen directly with providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MarginProvider>(
            create: (_) => MarginProvider(
              apiService: ApiService(),
              feedbackService: FeedbackService(),
              wearableService: WearableService(),
              calendarService: CalendarService(),
              preferencesService: PreferencesService(),
              aiService: AIResponseService(apiKey: ''),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DashboardScreen(),
          ),
        ),
      ),
    );

    // Wait for initial render
    await tester.pump();

    // Verify that the app has rendered (either loading state or content)
    // The test passes if the widget tree builds without errors
    expect(find.byType(Scaffold), findsWidgets);
  });
}
