import 'dart:async';
import '../models/wearable_data.dart';

/// Service for wearable device data
/// In production, this would connect to Apple HealthKit, Google Fit, etc.
class WearableService {
  // Mock data stream - simulates live updates from wearables
  final _controller = StreamController<WearableData>.broadcast();

  Stream<WearableData> get dataStream => _controller.stream;

  WearableData _currentData = _getMockData();

  WearableData get currentData => _currentData;

  /// Get current mock wearable data
  WearableData getMockData() {
    _currentData = _getMockData();
    _controller.add(_currentData);
    return _currentData;
  }

  /// Generate mock data simulating wearable readings
  static WearableData _getMockData() {
    final now = DateTime.now();
    final hour = now.hour;

    // Simulate realistic patterns based on time of day
    double sleep;
    double energy;

    // Sleep: assumes user slept last night
    sleep = 7.0 + (now.weekday == 1 ? -1.0 : 0.0); // Less sleep on Mondays

    // Energy: varies by time of day
    if (hour >= 6 && hour < 10) {
      energy = 7.0; // Morning
    } else if (hour >= 10 && hour < 14) {
      energy = 8.0; // Late morning peak
    } else if (hour >= 14 && hour < 17) {
      energy = 6.0; // Afternoon dip
    } else if (hour >= 17 && hour < 20) {
      energy = 5.0; // Evening fatigue
    } else {
      energy = 4.0; // Night
    }

    // Add some randomization for realism
    sleep += (now.millisecond % 10 - 5) / 10;
    energy += (now.millisecond % 10 - 5) / 10;

    // Clamp values
    sleep = sleep.clamp(0.0, 12.0);
    energy = energy.clamp(1.0, 10.0);

    return WearableData(
      sleep: sleep,
      energy: energy,
    );
  }

  /// Simulate new data coming from wearable
  void simulateNewData() {
    _currentData = _getMockData();
    _controller.add(_currentData);
  }

  /// Start periodic updates (simulating live wearable sync)
  Timer startPeriodicUpdates(Duration duration) {
    return Timer.periodic(duration, (_) => simulateNewData());
  }

  void dispose() {
    _controller.close();
  }
}
