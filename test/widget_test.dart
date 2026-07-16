import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:margin/screens/dashboard_screen.dart';
import 'package:margin/providers/margin_provider.dart';
import 'package:margin/services/api_service.dart';
import 'package:margin/services/feedback_service.dart';
import 'package:margin/services/wearable_service.dart';
import 'package:margin/services/preferences_service.dart';
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
              preferencesService: PreferencesService(),
            ),
          ),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    // Wait for loading state to complete
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify that the app title is shown
    expect(find.text('Margin'), findsOneWidget);

    // Verify dashboard content is rendered
    expect(find.text('Score Breakdown'), findsOneWidget);

    // Verify wearable data display is present
    expect(find.text('Wearable Data'), findsOneWidget);

    // Verify metrics are shown
    expect(find.text('Last night'), findsOneWidget);  // Sleep description
    expect(find.text('Current level'), findsOneWidget);  // Energy description
    expect(find.text('Today'), findsOneWidget);  // Meetings description
  });
}
