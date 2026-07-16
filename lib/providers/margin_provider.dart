import 'package:flutter/foundation.dart';
import '../models/margin_score.dart';
import '../models/margin_context.dart';
import '../models/user_input.dart';
import '../models/feedback.dart';
import '../models/user_preferences.dart';
import '../services/margin_service.dart';
import '../services/api_service.dart';
import '../services/feedback_service.dart';
import '../services/wearable_service.dart';
import '../services/preferences_service.dart';

/// Main provider for Margin Score state management
class MarginProvider with ChangeNotifier {
  final ApiService _apiService;
  final FeedbackService _feedbackService;
  final WearableService _wearableService;
  final PreferencesService _preferencesService;

  MarginContext? _context;
  MarginScore? _currentScore;
  UserInput? _wearableData;
  UserPreferences? _userPreferences;
  Map<String, DimensionValue>? _dimensions;
  bool _isLoading = false;
  String? _error;

  MarginProvider({
    required ApiService apiService,
    required FeedbackService feedbackService,
    required WearableService wearableService,
    required PreferencesService preferencesService,
  })  : _apiService = apiService,
        _feedbackService = feedbackService,
        _wearableService = wearableService,
        _preferencesService = preferencesService {
    _initialize();
    _listenToWearableUpdates();
  }

  /// Initialize the provider by fetching context data and loading preferences
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load user preferences first
      _userPreferences = await _preferencesService.loadPreferences();

      // Fetch backend context (has built-in fallback)
      MarginContext backendContext;
      try {
        backendContext = await _apiService.fetchMarginContext();
      } catch (e) {
        debugPrint('API context fetch failed: $e');
        // Create fallback context
        backendContext = _createFallbackContext();
      }

      // Merge context with user preferences (handles null preferences gracefully)
      _context = _mergeContextWithPreferences(backendContext, _userPreferences);

      _loadWearableData();
      _calculateScore();
      _updateDimensions();
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Initialization failed: $e');
      // Set fallback context so dimensions still work
      _context = _createFallbackContext();
      _loadWearableData();
      _calculateScore();
      _updateDimensions();
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a fallback context when API fails
  MarginContext _createFallbackContext() {
    final now = DateTime.now();
    return MarginContext(
      version: '1.0.0-fallback',
      lastUpdated: now.toIso8601String(),
      dayFactors: {
        'Monday': DayFactor(adjustment: -3, reason: 'Week start', description: 'Monday catch-up typically increases cognitive load'),
        'Tuesday': DayFactor(adjustment: 0, reason: 'Baseline', description: 'Standard productivity day'),
        'Wednesday': DayFactor(adjustment: 2, reason: 'Mid-week', description: 'Peak productivity day, slight buffer'),
        'Thursday': DayFactor(adjustment: 0, reason: 'Baseline', description: 'Standard productivity day'),
        'Friday': DayFactor(adjustment: -2, reason: 'Week-end', description: 'End-of-week wrap-up reduces available margin'),
        'Saturday': DayFactor(adjustment: 5, reason: 'Weekend', description: 'Personal time, higher margin availability'),
        'Sunday': DayFactor(adjustment: 3, reason: 'Weekend', description: 'Sunday scaries reduce margin slightly'),
      },
      seasonalFactors: {
        'Q1': SeasonalFactor(adjustment: -2, reason: 'Post-holiday', description: 'January recovery', months: [1, 2, 3]),
        'Q2': SeasonalFactor(adjustment: 2, reason: 'Spring', description: 'Spring momentum', months: [4, 5, 6]),
        'Q3': SeasonalFactor(adjustment: 0, reason: 'Summer', description: 'Summer steady state', months: [7, 8, 9]),
        'Q4': SeasonalFactor(adjustment: -5, reason: 'Year-end', description: 'Budget planning, reviews', months: [10, 11, 12]),
      },
      holidays: [],
      industryBenchmarks: {
        'software_engineer': IndustryBenchmark(
          averageMeetingHours: 6.0,
          averageFocusTime: 5.5,
          averageCommunicationsLoad: 15,
          description: 'Tech industry benchmarks',
        ),
      },
      timezoneFactors: {
        'single_timezone': TimezoneFactor(penalty: 0, description: 'Working in single timezone'),
        'dual_timezone': TimezoneFactor(penalty: -3, description: 'Working across 2 timezones'),
        'multi_timezone': TimezoneFactor(penalty: -7, description: 'Working across 3+ timezones'),
        'global_team': TimezoneFactor(penalty: -10, description: 'Global team'),
      },
      companySizeFactors: {
        'startup': CompanySizeFactor(adjustment: -3, description: 'Startup environment'),
        'small_business': CompanySizeFactor(adjustment: -2, description: 'Small business'),
        'mid_market': CompanySizeFactor(adjustment: 0, description: 'Mid-market company'),
        'enterprise': CompanySizeFactor(adjustment: -2, description: 'Enterprise'),
        'mega_corp': CompanySizeFactor(adjustment: -4, description: 'Large corporation'),
      },
      sleepImpactFactors: const SleepImpactFactor(
        optimal: SleepRange(hours: [7, 8, 9], adjustment: 5, description: 'Optimal'),
        adequate: SleepRange(hours: [6, 10], adjustment: 2, description: 'Adequate'),
        suboptimal: SleepRange(hours: [5, 11], adjustment: -3, description: 'Suboptimal'),
        critical: SleepRange(hours: [0, 1, 2, 3, 4], adjustment: -10, description: 'Critical'),
        oversleep: SleepRange(hours: [12, 13, 14, 15], adjustment: -2, description: 'Oversleep'),
      ),
      userRole: _userPreferences?.userRole ?? 'software_engineer',
      timezoneSpan: _userPreferences?.timezoneSpan ?? 'single_timezone',
      companySize: _userPreferences?.companySize ?? 'mid_market',
      chronotype: _userPreferences?.chronotype,
      workLifePatterns: _createWorkLifePatterns(),
      userMeetingHours: const [6, 6, 6, 6, 6],
    );
  }

  /// Merge backend context with user preferences
  MarginContext _mergeContextWithPreferences(
    MarginContext backendContext,
    UserPreferences? preferences,
  ) {
    return MarginContext(
      version: backendContext.version,
      lastUpdated: backendContext.lastUpdated,
      dayFactors: backendContext.dayFactors,
      seasonalFactors: backendContext.seasonalFactors,
      holidays: backendContext.holidays,
      industryBenchmarks: backendContext.industryBenchmarks,
      timezoneFactors: backendContext.timezoneFactors,
      companySizeFactors: backendContext.companySizeFactors,
      sleepImpactFactors: backendContext.sleepImpactFactors,
      userRole: preferences?.userRole ?? backendContext.userRole ?? 'software_engineer',
      timezoneSpan: preferences?.timezoneSpan ?? backendContext.timezoneSpan ?? 'single_timezone',
      companySize: preferences?.companySize ?? backendContext.companySize ?? 'mid_market',
      chronotype: preferences?.chronotype ?? backendContext.chronotype,
      workLifePatterns: _createWorkLifePatterns(),
      userMeetingHours: const [6, 6, 6, 6, 6],
    );
  }

  /// Create work-life patterns from calendar or manual input
  WorkLifePatterns? _createWorkLifePatterns() {
    if (_userPreferences?.calendarConnected == true) {
      // Use demo patterns for calendar-connected users
      return WorkLifePatterns.demo();
    } else if (_userPreferences != null &&
        (_userPreferences!.worksLateHours != null ||
         _userPreferences!.worksWeekends != null)) {
      // Use manual preferences
      return WorkLifePatterns.fromManualPreferences(
        worksLateHours: _userPreferences!.worksLateHours ?? false,
        worksWeekends: _userPreferences!.worksWeekends ?? false,
      );
    }
    return null;
  }

  /// Load data from wearable service
  void _loadWearableData() {
    _wearableData = _wearableService.getMockData();
  }

  /// Listen to live updates from wearable
  void _listenToWearableUpdates() {
    _wearableService.dataStream.listen((data) {
      _wearableData = data;
      _calculateScore();
      _updateDimensions();
      notifyListeners();
    });
  }

  /// Calculate the current Margin Score
  void _calculateScore() {
    if (_context == null || _wearableData == null) return;

    final service = MarginService(_context!);
    _currentScore = service.calculateScore(_wearableData!);
  }

  /// Update dimensions display
  void _updateDimensions() {
    if (_context == null) return;

    final service = MarginService(_context!);
    _dimensions = service.getCurrentDimensions(_wearableData);
  }

  /// Refresh all data
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      _context = await _apiService.fetchMarginContext();
      // Re-merge with preferences
      if (_context != null) {
        _context = _mergeContextWithPreferences(_context!, _userPreferences);
      }
      _wearableService.simulateNewData();
      _calculateScore();
      _updateDimensions();
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submit feedback on a dimension
  void submitFeedback(DimensionFeedback feedback) {
    if (_context == null) return;

    final applied = _feedbackService.submitFeedback(feedback);

    // Apply the feedback to the context
    final service = MarginService(_context!);
    _context = service.applyFeedback(applied);

    // Recalculate score with new context
    _calculateScore();
    _updateDimensions();

    notifyListeners();
  }

  /// Update wearable data (DEV ONLY - for testing)
  /// This allows developers to manually adjust the wearable data for testing
  void updateWearableData(UserInput newData) {
    try {
      _wearableData = newData;
      if (_context != null) {
        _calculateScore();
        _updateDimensions();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating wearable data: $e');
      // Still notify to update UI even if calculation fails
      notifyListeners();
    }
  }

  // Getters
  MarginScore? get currentScore => _currentScore;
  UserInput? get wearableData => _wearableData;
  Map<String, DimensionValue>? get dimensions => _dimensions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  MarginContext? get context => _context;
}
