import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences.dart';

/// Service for storing and retrieving user preferences locally
class PreferencesService {
  static const String _preferencesKey = 'user_preferences';
  static const String _onboardingCompletedKey = 'onboarding_completed';

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
}
