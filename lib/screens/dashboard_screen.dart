import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/margin_provider.dart';
import '../services/api_service.dart';
import '../services/feedback_service.dart';
import '../services/wearable_service.dart';
import '../services/preferences_service.dart';
import '../widgets/margin_score_display.dart';
import '../widgets/dimensions_list.dart';
import '../widgets/wearable_data_display.dart';
import '../widgets/settings_dialog.dart';

/// Main Dashboard Screen for Margin Score
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Margin'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MarginProvider>().refresh();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              SettingsDialog.show(context);
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Consumer<MarginProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null && provider.currentScore == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading data',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Margin Score Display
                const MarginScoreDisplay(),

                const SizedBox(height: 24),

                // Wearable Data Display (read-only)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: WearableDataDisplay(
                    data: provider.wearableData,
                  ),
                ),

                const SizedBox(height: 32),

                // Dimensions Section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Score Breakdown',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Dimensions List
                const DimensionsList(),

                const SizedBox(height: 32),

                // Footer info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Data from wearable devices • Last synced: ${_formatTime(DateTime.now())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
    final preferencesService = Provider.of<PreferencesService>(context);

    return ChangeNotifierProvider(
      create: (_) => MarginProvider(
        apiService: apiService,
        feedbackService: feedbackService,
        wearableService: wearableService,
        preferencesService: preferencesService,
      ),
      child: const DashboardScreen(),
    );
  }
}
