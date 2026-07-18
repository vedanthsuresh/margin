import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/sandbox_screen.dart';
import 'services/api_service.dart';
import 'services/feedback_service.dart';
import 'services/wearable_service.dart';
import 'services/calendar_service.dart';
import 'services/preferences_service.dart';
import 'services/ai_response_service.dart';
import 'services/ai_feedback_analysis_service.dart';
import 'services/notification_service.dart';
import 'services/share_intent_service.dart';
import 'providers/margin_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Global key for navigation (used by ShareIntentService)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initialize();

  // Initialize share intent service for point-of-origin interception
  final shareIntentService = ShareIntentService();
  await shareIntentService.initialize();

  // Set up callback for when a share arrives while app is running
  shareIntentService.onShareReceived = (String sharedText) {
    // Navigate to sandbox when share is received
    debugPrint('📱 Share received, navigating to sandbox...');
    navigatorKey.currentState?.pushNamed('/sandbox');
  };

  runApp(const MarginApp());
}

class MarginApp extends StatelessWidget {
  const MarginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Margin',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // For share intent navigation
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
        '/sandbox': (context) => const SandboxScreenWrapper(),
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
    return FutureBuilder<AppEntryPointResult>(
      future: _determineEntryPoint(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final result = snapshot.data;
        if (result == null) {
          // Fallback to onboarding if something went wrong
          return OnboardingScreenWrapper();
        }

        // Check if we have a share intent - if so, go directly to sandbox
        if (result.hasShareIntent) {
          return SandboxScreenWrapper();
        }

        // Normal flow: check onboarding status
        if (result.isOnboarded) {
          return const DashboardScreenWrapper();
        } else {
          return OnboardingScreenWrapper();
        }
      },
    );
  }

  Future<AppEntryPointResult> _determineEntryPoint() async {
    final preferencesService = PreferencesService();
    final isOnboarded = await preferencesService.isOnboarded();
    final shareIntentService = ShareIntentService();
    final hasShareIntent = shareIntentService.hasSharedText();

    return AppEntryPointResult(
      isOnboarded: isOnboarded,
      hasShareIntent: hasShareIntent,
    );
  }
}

/// Result of app entry point determination
class AppEntryPointResult {
  final bool isOnboarded;
  final bool hasShareIntent;

  AppEntryPointResult({
    required this.isOnboarded,
    required this.hasShareIntent,
  });
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
    final aiFeedbackAnalysisService = AIFeedbackAnalysisService();
    final feedbackService = FeedbackService(
      aiAnalysisService: aiFeedbackAnalysisService,
    );
    final wearableService = WearableService();
    final calendarService = CalendarService();
    final preferencesService = PreferencesService();
    final aiService = AIResponseService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MarginProvider>(
          create: (_) => MarginProvider(
            apiService: apiService,
            feedbackService: feedbackService,
            wearableService: wearableService,
            calendarService: calendarService,
            preferencesService: preferencesService,
            aiService: aiService,
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
    final aiFeedbackAnalysisService = AIFeedbackAnalysisService();
    final feedbackService = FeedbackService(
      aiAnalysisService: aiFeedbackAnalysisService,
    );
    final wearableService = WearableService();
    final calendarService = CalendarService();
    final aiService = AIResponseService();

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
            aiService: aiService,
          ),
        ),
      ],
      child: OnboardingScreen(preferencesService: preferencesService),
    );
  }
}

/// Wrapper for sandbox with providers
class SandboxScreenWrapper extends StatelessWidget {
  const SandboxScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final aiFeedbackAnalysisService = AIFeedbackAnalysisService();
    final feedbackService = FeedbackService(
      aiAnalysisService: aiFeedbackAnalysisService,
    );
    final wearableService = WearableService();
    final calendarService = CalendarService();
    final preferencesService = PreferencesService();
    final aiService = AIResponseService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MarginProvider>(
          create: (_) => MarginProvider(
            apiService: apiService,
            feedbackService: feedbackService,
            wearableService: wearableService,
            calendarService: calendarService,
            preferencesService: preferencesService,
            aiService: aiService,
          ),
        ),
      ],
      child: const SandboxScreen(),
    );
  }
}
