import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wearable_data.dart';

/// Service for wearable device data
/// In production, this would connect to Apple HealthKit, Google Fit, etc.
class WearableService {
  // Mock data stream - simulates live updates from wearables
  final _controller = StreamController<WearableData>.broadcast();
  static const String _sleepKey = 'user_sleep_hours';
  static const String _energyKey = 'user_energy_level';

  Stream<WearableData> get dataStream => _controller.stream;

  WearableData _currentData = WearableData(sleep: 7.0, energy: 7.0);

  WearableData get currentData => _currentData;

  WearableService() {
    debugPrint('🏭 WearableService constructed with defaults: sleep=$_currentData.sleep, energy=$_currentData.energy');
  }

  /// Initialize and load persisted data
  Future<void> initialize() async {
    debugPrint('📱 WearableService.initialize() - Loading persisted data...');
    final prefs = await SharedPreferences.getInstance();
    final sleep = prefs.getDouble(_sleepKey);
    final energy = prefs.getDouble(_energyKey);

    debugPrint('   Saved sleep: $sleep');
    debugPrint('   Saved energy: $energy');

    if (sleep != null || energy != null) {
      _currentData = WearableData(
        sleep: sleep ?? _getDefaultSleep(),
        energy: energy ?? _getDefaultEnergy(),
      );
      debugPrint('   ✓ Loaded from storage: sleep=$_currentData.sleep, energy=$_currentData.energy');
      _controller.add(_currentData);
    } else {
      // First launch - use defaults
      _currentData = _getDefaultData();
      debugPrint('   First launch, using defaults: sleep=$_currentData.sleep, energy=$_currentData.energy');
      await saveData(_currentData);
      _controller.add(_currentData);
    }
  }

  /// Get default sleep value based on time of day
  double _getDefaultSleep() {
    return 7.0;
  }

  /// Get default energy value based on time of day
  double _getDefaultEnergy() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 10) return 7.0;
    if (hour >= 10 && hour < 14) return 8.0;
    if (hour >= 14 && hour < 17) return 6.0;
    if (hour >= 17 && hour < 20) return 5.0;
    return 4.0;
  }

  /// Get default data for first launch
  WearableData _getDefaultData() {
    return WearableData(
      sleep: _getDefaultSleep(),
      energy: _getDefaultEnergy(),
    );
  }

  /// Get current mock wearable data (legacy - for compatibility)
  WearableData getMockData() {
    return _currentData;
  }

  /// Update data and persist to storage
  Future<void> updateData(WearableData newData) async {
    debugPrint('💾 WearableService.updateData() - Saving new values...');
    _currentData = newData;
    await saveData(newData);
    debugPrint('   ✓ Saved: sleep=${newData.sleep}, energy=${newData.energy}');
    _controller.add(_currentData);
  }

  /// Save data to SharedPreferences
  Future<void> saveData(WearableData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_sleepKey, data.sleep);
    await prefs.setDouble(_energyKey, data.energy);
    debugPrint('   SharedPreferences written');
  }

  /// Simulate new data coming from wearable
  void simulateNewData() {
    _currentData = _getDefaultData();
    saveData(_currentData);
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
