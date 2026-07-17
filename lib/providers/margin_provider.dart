import 'package:flutter/foundation.dart';
import '../models/margin_score.dart';
import '../models/margin_context.dart';
import '../models/user_input.dart';
import '../models/feedback.dart';
import '../models/user_preferences.dart';
import '../models/wearable_data.dart';
import '../models/calendar_data.dart';
import '../models/boundary_responses.dart';
import '../services/margin_service.dart';
import '../services/api_service.dart';
import '../services/feedback_service.dart';
import '../services/wearable_service.dart';
import '../services/calendar_service.dart';
import '../services/preferences_service.dart';
import '../services/ai_response_service.dart';

/// Main provider for Margin Score state management
class MarginProvider with ChangeNotifier {
  final ApiService _apiService;
  final FeedbackService _feedbackService;
  final WearableService _wearableService;
  final CalendarService _calendarService;
  final PreferencesService _preferencesService;
  final AIResponseService _aiService;

  MarginContext? _context;
  MarginScore? _currentScore;
  WearableData? _wearableData;
  CalendarData? _calendarData;
  UserPreferences? _userPreferences;
  Map<String, DimensionValue>? _dimensions;
  bool _isLoading = false;
  String? _error;

  // Debug counter to track wearable data updates
  int _wearableDataUpdateCount = 0;

  MarginProvider({
    required ApiService apiService,
    required FeedbackService feedbackService,
    required WearableService wearableService,
    required CalendarService calendarService,
    required PreferencesService preferencesService,
    required AIResponseService aiService,
  })  : _apiService = apiService,
        _feedbackService = feedbackService,
        _wearableService = wearableService,
        _calendarService = calendarService,
        _preferencesService = preferencesService,
        _aiService = aiService {
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

      // Load dimension overrides from storage
      final overrides = await _preferencesService.loadDimensionOverrides();
      if (overrides.isNotEmpty && _context != null) {
        _context = _context!.copyWith(dimensionOverrides: overrides);
        debugPrint('📥 Loaded dimension overrides from storage: $overrides');
      }

      await _loadCalendarData();
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
      await _loadCalendarData();
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
      userRole: _userPreferences?.aiClassifiedRole ?? _userPreferences?.userRole ?? 'software_engineer',
      timezoneSpan: _userPreferences?.timezoneSpan ?? 'single_timezone',
      companySize: _userPreferences?.aiClassifiedCompanySize ?? _userPreferences?.companySize ?? 'mid_market',
      chronotype: _userPreferences?.chronotype,
      aiClassifiedCompanySizeAdjustment: _userPreferences?.aiClassifiedCompanySizeAdjustment,
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
      userRole: preferences?.aiClassifiedRole ?? preferences?.userRole ?? backendContext.userRole ?? 'software_engineer',
      timezoneSpan: preferences?.timezoneSpan ?? backendContext.timezoneSpan ?? 'single_timezone',
      companySize: preferences?.aiClassifiedCompanySize ?? preferences?.companySize ?? backendContext.companySize ?? 'mid_market',
      chronotype: preferences?.chronotype ?? backendContext.chronotype,
      aiClassifiedCompanySizeAdjustment: preferences?.aiClassifiedCompanySizeAdjustment,
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

  /// Load data from wearable service (async to load persisted values)
  Future<void> _loadWearableData() async {
    debugPrint('📲 MarginProvider._loadWearableData() - Loading wearable data...');
    await _wearableService.initialize();
    _wearableData = _wearableService.currentData;
    debugPrint('   ✅ Loaded: sleep=${_wearableData?.sleep}, energy=${_wearableData?.energy}');
    debugPrint('   Stack trace: ${StackTrace.current}');
  }

  /// Load data from calendar service
  Future<void> _loadCalendarData() async {
    _calendarData = await _calendarService.getTodayMeetingLoad();
  }

  /// Listen to live updates from wearable
  void _listenToWearableUpdates() {
    _wearableService.dataStream.listen((data) {
      _wearableDataUpdateCount++;
      debugPrint('🔄 Stream update #$_wearableDataUpdateCount: sleep=${data.sleep}, energy=${data.energy}');
      _wearableData = data;
      _calculateScore();
      _updateDimensions();
      notifyListeners();
    });
  }

  /// Calculate the current Margin Score
  void _calculateScore() {
    debugPrint('📊 _calculateScore() called');
    debugPrint('   _context: ${_context != null}');
    debugPrint('   _wearableData: ${_wearableData != null} (sleep=${_wearableData?.sleep}, energy=${_wearableData?.energy})');
    debugPrint('   _calendarData: ${_calendarData != null}');

    if (_context == null || _wearableData == null || _calendarData == null) {
      debugPrint('   ⚠️ Skipping calculation - missing data');
      return;
    }

    // Compose UserInput from separate data sources
    final userInput = UserInput(
      wearableData: _wearableData!,
      calendarData: _calendarData!,
    );

    final service = MarginService(_context!);
    _currentScore = service.calculateScore(userInput);
    debugPrint('   ✅ Score calculated: ${_currentScore?.finalScore} (${_currentScore?.capacityLevel})');
  }

  /// Update dimensions display
  void _updateDimensions() {
    if (_context == null || _wearableData == null || _calendarData == null) return;

    // Compose UserInput for dimensions service
    final userInput = UserInput(
      wearableData: _wearableData!,
      calendarData: _calendarData!,
    );

    final service = MarginService(_context!);
    _dimensions = service.getCurrentDimensions(userInput);
  }

  /// Refresh all data
  Future<void> refresh() async {
    debugPrint('🔄 Refresh called - reloading context with persisted overrides');
    _isLoading = true;
    notifyListeners();

    try {
      _context = await _apiService.fetchMarginContext();
      // Re-merge with preferences
      if (_context != null) {
        _context = _mergeContextWithPreferences(_context!, _userPreferences);
      }
      // Re-load dimension overrides from storage
      final overrides = await _preferencesService.loadDimensionOverrides();
      if (overrides.isNotEmpty && _context != null) {
        _context = _context!.copyWith(dimensionOverrides: overrides);
        debugPrint('📥 Reloaded dimension overrides from storage: $overrides');
      }
      await _loadCalendarData();
      // DON'T call simulateNewData() - it overrides user-set values!
      // _wearableService.simulateNewData();
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

  /// Submit feedback on a dimension (async with AI analysis)
  Future<void> submitFeedback(DimensionFeedback feedback) async {
    debugPrint('📥 MarginProvider.submitFeedback called');
    if (_context == null) {
      debugPrint('⚠️ Context is null, skipping feedback');
      return;
    }

    debugPrint('⏳ Calling FeedbackService.submitFeedback...');
    final applied = await _feedbackService.submitFeedback(
      feedback,
      context: _context,
    );
    debugPrint('✅ FeedbackService returned: ${applied.reason}');

    // Apply the feedback to the context
    final service = MarginService(_context!);
    _context = service.applyFeedback(applied);

    debugPrint('   🔍 After applyFeedback - dimensionOverrides: ${_context!.dimensionOverrides}');

    // Save dimension overrides to storage
    if (_context!.dimensionOverrides != null && _context!.dimensionOverrides!.isNotEmpty) {
      debugPrint('   💾 Saving dimensionOverrides to storage...');
      await _preferencesService.saveDimensionOverrides(_context!.dimensionOverrides!);
      debugPrint('   ✅ DimensionOverrides saved successfully');
    } else {
      debugPrint('   ⚠️ dimensionOverrides is null or empty, skipping save');
      debugPrint('      dimensionOverrides == null: ${_context!.dimensionOverrides == null}');
      debugPrint('      dimensionOverrides.isEmpty: ${_context!.dimensionOverrides?.isEmpty ?? true}');
    }

    // Recalculate score with new context
    _calculateScore();
    _updateDimensions();

    debugPrint('🔄 Score recalculated: ${_currentScore?.finalScore}');
    notifyListeners();
    debugPrint('📢 Listeners notified');
  }

  /// Submit feedback synchronously (for backward compatibility)
  void submitFeedbackSync(DimensionFeedback feedback) {
    if (_context == null) return;

    final applied = _feedbackService.submitFeedbackSync(feedback);

    // Apply the feedback to the context
    final service = MarginService(_context!);
    _context = service.applyFeedback(applied);

    // Recalculate score with new context
    _calculateScore();
    _updateDimensions();

    notifyListeners();
  }

  /// Update wearable and calendar data (DEV ONLY - for testing)
  /// This allows developers to manually adjust the data for testing
  /// PERSISTED: Values are saved to storage
  void updateWearableData(UserInput newData) async {
    debugPrint('🎚️ Slider adjusted - New values: sleep=${newData.wearableData.sleep}, energy=${newData.wearableData.energy}');
    try {
      _wearableData = newData.wearableData;
      _calendarData = newData.calendarData;

      // Persist the wearable data (sleep, energy) - MUST await!
      await _wearableService.updateData(_wearableData!);
      debugPrint('   ✅ Data saved successfully');

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

  /// Get combined user input (for backwards compatibility)
  UserInput? get userInput {
    if (_wearableData == null || _calendarData == null) return null;
    return UserInput(
      wearableData: _wearableData!,
      calendarData: _calendarData!,
    );
  }

  /// Get wearable data only
  WearableData? get wearableData => _wearableData;

  /// Get calendar data only
  CalendarData? get calendarData => _calendarData;

  Map<String, DimensionValue>? get dimensions => _dimensions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  MarginContext? get context => _context;

  /// Generate AI-powered boundary responses
  Future<BoundaryResponses> generateBoundaryResponses({
    required String text,
    required String relationship,
  }) async {
    // Ensure score is up-to-date before generating responses
    _calculateScore();

    final score = _currentScore?.finalScore ?? 50;
    final level = _currentScore?.capacityLevel ?? CapacityLevel.moderate;

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🤖 AI BOUNDARY RESPONSE GENERATION');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('Input: "$text"');
    debugPrint('Relationship: $relationship');
    debugPrint('Margin Score: $score ($level)');
    debugPrint('Current Score Data: $_currentScore');
    debugPrint('────────────────────────────────────────────────────');

    final responses = await _aiService.generateResponses(
      incomingText: text,
      relationship: relationship,
      marginScore: score,
      capacityLevel: level,
    );

    debugPrint('📤 AI RESPONSES:');
    debugPrint('   Polite Decline: "${responses.politeDecline}"');
    debugPrint('   Soft Compromise: "${responses.softCompromise}"');
    debugPrint('   Reschedule: "${responses.reschedule}"');
    debugPrint('   Accept Request: "${responses.acceptRequest}"');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    return responses;
  }

  @override
  void dispose() {
    debugPrint('🗑️ MarginProvider disposed');
    super.dispose();
  }
}
