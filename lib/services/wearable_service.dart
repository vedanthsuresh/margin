import 'dart:async';
import '../models/user_input.dart';

/// Mock service for wearable device data
/// In production, this would connect to Apple HealthKit, Google Fit, etc.
class WearableService {
  // Mock data stream - simulates live updates from wearables
  final _controller = StreamController<UserInput>.broadcast();

  Stream<UserInput> get dataStream => _controller.stream;

  UserInput _currentData = _getMockData();

  UserInput get currentData => _currentData;

  /// Get current mock wearable data
  UserInput getMockData() {
    _currentData = _getMockData();
    _controller.add(_currentData);
    return _currentData;
  }

  /// Generate mock data simulating wearable readings
  static UserInput _getMockData() {
    final now = DateTime.now();
    final hour = now.hour;

    // Simulate realistic patterns based on time of day
    double sleep;
    double energy;
    double meetingLoad;

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

    // Meeting load: based on day of week
    switch (now.weekday) {
      case 1: // Monday
        meetingLoad = 8.0;
        break;
      case 2: // Tuesday
        meetingLoad = 7.0;
        break;
      case 3: // Wednesday
        meetingLoad = 6.0;
        break;
      case 4: // Thursday
        meetingLoad = 7.0;
        break;
      case 5: // Friday
        meetingLoad = 5.0;
        break;
      default: // Weekend
        meetingLoad = 2.0;
    }

    // Add some randomization for realism
    sleep += (now.millisecond % 10 - 5) / 10;
    energy += (now.millisecond % 10 - 5) / 10;
    meetingLoad += (now.millisecond % 10 - 5) / 10;

    // Clamp values
    sleep = sleep.clamp(0.0, 12.0);
    energy = energy.clamp(1.0, 10.0);
    meetingLoad = meetingLoad.clamp(0.0, 16.0);

    return UserInput(
      sleep: sleep,
      energy: energy,
      meetingLoad: meetingLoad,
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
