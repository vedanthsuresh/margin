import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/api_service.dart';
import 'services/feedback_service.dart';
import 'services/wearable_service.dart';
import 'services/calendar_service.dart';
import 'services/preferences_service.dart';
import 'providers/margin_provider.dart';

void main() {
  runApp(const MarginApp());
}

class MarginApp extends StatelessWidget {
  const MarginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Margin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'System',
      ),
      home: const AppEntryPoint(),
      routes: {
        '/dashboard': (context) => const DashboardScreenWrapper(),
      },
    );
  }
}

/// Initializes app and routes to onboarding or dashboard
class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkOnboardingStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (snapshot.data == true) {
          // Onboarding completed - go to dashboard
          return const DashboardScreenWrapper();
        } else {
          // Needs onboarding
          return OnboardingScreenWrapper();
        }
      },
    );
  }

  Future<bool> _checkOnboardingStatus() async {
    final preferencesService = PreferencesService();
    return await preferencesService.isOnboarded();
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Wrapper that provides necessary services to DashboardScreen
class DashboardScreenWrapper extends StatelessWidget {
  const DashboardScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final feedbackService = FeedbackService();
    final wearableService = WearableService();
    final calendarService = CalendarService();
    final preferencesService = PreferencesService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MarginProvider>(
          create: (_) => MarginProvider(
            apiService: apiService,
            feedbackService: feedbackService,
            wearableService: wearableService,
            calendarService: calendarService,
            preferencesService: preferencesService,
          ),
        ),
      ],
      child: const DashboardScreen(),
    );
  }
}

/// Wrapper for onboarding with providers
class OnboardingScreenWrapper extends StatelessWidget {
  const OnboardingScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final preferencesService = PreferencesService();
    final apiService = ApiService();
    final feedbackService = FeedbackService();
    final wearableService = WearableService();
    final calendarService = CalendarService();

    return MultiProvider(
      providers: [
        Provider<PreferencesService>.value(value: preferencesService),
        ChangeNotifierProvider<MarginProvider>(
          create: (_) => MarginProvider(
            apiService: apiService,
            feedbackService: feedbackService,
            wearableService: wearableService,
            calendarService: calendarService,
            preferencesService: preferencesService,
          ),
        ),
      ],
      child: OnboardingScreen(preferencesService: preferencesService),
    );
  }
}
