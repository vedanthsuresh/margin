import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences.dart';

/// Service for storing and retrieving user preferences locally
class PreferencesService {
  static const String _preferencesKey = 'user_preferences';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _dimensionOverridesKey = 'dimension_overrides';
  static const String _frictionLockQuarantineKey = 'friction_lock_quarantine';
  static const int _quarantineDurationMinutes = 15; // Production: 15 minutes

  /// Save user preferences to local storage
  Future<void> savePreferences(UserPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(preferences.toJson());
    await prefs.setString(_preferencesKey, jsonString);
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  /// Load user preferences from local storage
  Future<UserPreferences?> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_preferencesKey);

    if (jsonString == null) return null;

    try {
      final Map<String, dynamic> data = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserPreferences.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Save dimension overrides to local storage
  Future<void> saveDimensionOverrides(Map<String, double> overrides) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(overrides);
    await prefs.setString(_dimensionOverridesKey, jsonString);
    debugPrint('💾 Saved dimension overrides: $overrides');
  }

  /// Load dimension overrides from local storage
  Future<Map<String, double>> loadDimensionOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_dimensionOverridesKey);

    if (jsonString == null) return {};

    try {
      final Map<String, dynamic> data = jsonDecode(jsonString) as Map<String, dynamic>;
      final overrides = data.map<String, double>((key, value) =>
        MapEntry(key, (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0));
      debugPrint('📥 Loaded dimension overrides: $overrides');
      return overrides;
    } catch (e) {
      debugPrint('⚠️ Failed to load dimension overrides: $e');
      return {};
    }
  }

  /// Clear dimension overrides (for testing or reset)
  Future<void> clearDimensionOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dimensionOverridesKey);
    debugPrint('🗑️ Cleared dimension overrides');
  }

  /// Check if onboarding has been completed
  Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  /// Clear all preferences (for testing or reset)
  Future<void> clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_preferencesKey);
    await prefs.remove(_onboardingCompletedKey);
  }

  /// Save quarantine timestamp (when friction lock was triggered)
  Future<void> saveQuarantineTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_frictionLockQuarantineKey, DateTime.now().millisecondsSinceEpoch);
    debugPrint('💾 Saved quarantine timestamp');
  }

  /// Get remaining quarantine time in milliseconds (0 if expired/not set)
  Future<int> getQuarantineRemainingMillis() async {
    final prefs = await SharedPreferences.getInstance();
    final startTimeMillis = prefs.getInt(_frictionLockQuarantineKey);
    if (startTimeMillis == null) return 0;

    final elapsed = DateTime.now().millisecondsSinceEpoch - startTimeMillis;
    final quarantineDuration = Duration(minutes: _quarantineDurationMinutes).inMilliseconds;

    // Clear if expired
    if (elapsed >= quarantineDuration) {
      await prefs.remove(_frictionLockQuarantineKey);
      debugPrint('🕐 Quarantine expired, cleared');
      return 0;
    }

    final remaining = quarantineDuration - elapsed;
    debugPrint('🕐 Quarantine active: ${(Duration(milliseconds: remaining).inSeconds)}s remaining');
    return remaining;
  }

  /// Check if quarantine is active
  Future<bool> isQuarantineActive() async {
    return await getQuarantineRemainingMillis() > 0;
  }

  /// Clear quarantine timestamp (for testing)
  Future<void> clearQuarantineTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_frictionLockQuarantineKey);
    debugPrint('🗑️ Cleared quarantine timestamp');
  }
}
