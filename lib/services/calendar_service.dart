import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/margin_context.dart';
import '../models/calendar_data.dart';

/// Enable demo mode (simulated calendar connection) for development/testing
/// Set this to false when OAuth is properly configured
const bool _kDemoMode = true;

/// Service for Google Calendar integration and work-life pattern analysis
class CalendarService {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'google_access_token';

  // Only initialize GoogleSignIn if not in demo mode
  final GoogleSignIn? _googleSignIn = _kDemoMode ? null : GoogleSignIn(
    scopes: [
      calendar.CalendarApi.calendarReadonlyScope,
    ],
  );

  bool _isConnected = false;
  calendar.CalendarApi? _calendarApi;
  WorkLifePatterns? _cachedPatterns;

  /// Check if calendar is connected
  bool get isConnected => _isConnected;

  /// Check if user has previously signed in
  Future<bool> hasPreviousSignIn() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null;
  }

  /// Get today's meeting load (hours of meetings today)
  Future<CalendarData> getTodayMeetingLoad() async {
    if (!_isConnected || _calendarApi == null) {
      // Return mock data for demo mode
      return _getDemoMeetingLoad();
    }

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Fetch today's events
      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: startOfDay,
        timeMax: endOfDay,
        singleEvents: true,
        orderBy: 'startTime',
      );

      // Calculate total meeting hours
      double totalHours = 0;
      for (final event in events.items ?? []) {
        if (event.start?.dateTime != null && event.end?.dateTime != null) {
          final duration = event.end!.dateTime!.difference(event.start!.dateTime!);
          totalHours += duration.inMinutes / 60;
        }
      }

      return CalendarData(meetingLoad: totalHours.clamp(0.0, 16.0));
    } catch (e) {
      debugPrint('Error fetching today\'s meetings: $e');
      return _getDemoMeetingLoad();
    }
  }

  /// Get demo meeting load based on day of week
  CalendarData _getDemoMeetingLoad() {
    final now = DateTime.now();
    double meetingLoad;

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

    return CalendarData(meetingLoad: meetingLoad);
  }

  /// Connect to Google Calendar
  Future<bool> connect() async {
    // Demo mode fallback for development without OAuth setup
    if (_kDemoMode) {
      await Future.delayed(const Duration(seconds: 1));
      _isConnected = true;
      _cachedPatterns = _generateDemoPatterns();
      debugPrint('📅 Calendar connected (DEMO MODE)');
      return true;
    }

    if (_googleSignIn == null) {
      debugPrint('GoogleSignIn not initialized');
      return false;
    }

    try {
      // Try silent sign-in first (for returning users)
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();

      // If silent sign-in fails, try interactive sign-in
      account ??= await _googleSignIn.signIn();

      if (account == null) {
        // User canceled sign-in
        return false;
      }

      // Get authenticated HTTP client
      final auth = await account.authentication;
      final accessToken = auth.accessToken;

      if (accessToken != null) {
        // Store token for future use
        await _storage.write(key: _accessTokenKey, value: accessToken);

        // Create Calendar API client
        final httpClient = _GoogleAuthClient(accessToken);
        _calendarApi = calendar.CalendarApi(httpClient);
        _isConnected = true;

        // Analyze patterns after connection
        await fetchAndAnalyzePatterns();

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Calendar connection error: $e');
      return false;
    }
  }

  /// Fetch and analyze calendar patterns
  Future<WorkLifePatterns?> fetchAndAnalyzePatterns() async {
    if (!_isConnected || _calendarApi == null) {
      return null;
    }

    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Fetch events from the last 30 days
      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: thirtyDaysAgo,
        timeMax: now,
        singleEvents: true,
        orderBy: 'startTime',
      );

      // Analyze patterns
      _cachedPatterns = _analyzeEvents(events.items ?? []);
      return _cachedPatterns;
    } catch (e) {
      debugPrint('Error fetching calendar events: $e');
      return null;
    }
  }

  /// Analyze calendar events to detect work-life patterns
  WorkLifePatterns _analyzeEvents(List<calendar.Event> events) {
    int lateMeetingsCount = 0;
    int veryLateMeetingsCount = 0;
    int earlyMeetingsCount = 0;
    int veryEarlyMeetingsCount = 0;
    int weekendMeetingsCount = 0;

    for (final event in events) {
      // Skip events without start time or all-day events
      if (event.start?.dateTime == null) continue;

      final start = event.start!.dateTime!;
      final hour = start.hour;

      // Late meetings (after 6 PM)
      if (hour >= 18 && hour < 21) {
        lateMeetingsCount++;
      } else if (hour >= 21) {
        veryLateMeetingsCount++;
      }

      // Early meetings (before 8 AM)
      if (hour >= 6 && hour < 8) {
        earlyMeetingsCount++;
      } else if (hour < 6) {
        veryEarlyMeetingsCount++;
      }

      // Weekend meetings
      if (start.weekday == DateTime.saturday || start.weekday == DateTime.sunday) {
        weekendMeetingsCount++;
      }
    }

    // Calculate average daily penalty
    final totalDays = 30;
    double penalty = 0;
    penalty += lateMeetingsCount * 1.5;
    penalty += veryLateMeetingsCount * 3.0;
    penalty += earlyMeetingsCount * 1.0;
    penalty += veryEarlyMeetingsCount * 2.0;
    penalty += weekendMeetingsCount * 5.0;

    final averageDailyPenalty = penalty / totalDays;

    return WorkLifePatterns(
      lateMeetingsCount: lateMeetingsCount,
      veryLateMeetingsCount: veryLateMeetingsCount,
      earlyMeetingsCount: earlyMeetingsCount,
      veryEarlyMeetingsCount: veryEarlyMeetingsCount,
      weekendMeetingsCount: weekendMeetingsCount,
      averageDailyPenalty: averageDailyPenalty,
      analysisDays: totalDays,
    );
  }

  /// Generate demo patterns for development/testing
  WorkLifePatterns _generateDemoPatterns() {
    // Simulate realistic work-life patterns for demo
    return WorkLifePatterns(
      lateMeetingsCount: 3, // ~3 late meetings in last 30 days
      veryLateMeetingsCount: 1, // 1 very late meeting (after 9pm)
      earlyMeetingsCount: 0,
      veryEarlyMeetingsCount: 0,
      weekendMeetingsCount: 2, // 2 weekend meetings
      averageDailyPenalty: 1.2, // Moderate penalty
      analysisDays: 30,
    );
  }

  /// Find available time slots for rescheduling
  Future<List<TimeSlot>> findAvailableSlots({
    required DateTime start,
    required DateTime end,
    int minimumDurationMinutes = 30,
  }) async {
    if (!_isConnected || _calendarApi == null) {
      return [];
    }

    try {
      // Fetch existing events in the range
      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: start,
        timeMax: end,
        singleEvents: true,
        orderBy: 'startTime',
      );

      // Find free slots between events
      final slots = <TimeSlot>[];
      final sortedEvents = events.items?.toList() ?? [];

      // Sort by start time
      sortedEvents.sort((a, b) {
        final aStart = a.start?.dateTime ?? start;
        final bStart = b.start?.dateTime ?? start;
        return aStart.compareTo(bStart);
      });

      DateTime currentStart = start;

      for (final event in sortedEvents) {
        if (event.start?.dateTime == null || event.end?.dateTime == null) continue;

        final eventStart = event.start!.dateTime!;
        final eventEnd = event.end!.dateTime!;

        // Check if there's a gap before this event
        if (eventStart.isAfter(currentStart)) {
          final gapDuration = eventStart.difference(currentStart);
          if (gapDuration.inMinutes >= minimumDurationMinutes) {
            slots.add(TimeSlot(
              start: currentStart,
              end: eventStart,
              duration: gapDuration,
            ));
          }
        }

        currentStart = eventEnd;
      }

      // Check for time after the last event
      if (end.isAfter(currentStart)) {
        final gapDuration = end.difference(currentStart);
        if (gapDuration.inMinutes >= minimumDurationMinutes) {
          slots.add(TimeSlot(
            start: currentStart,
            end: end,
            duration: gapDuration,
          ));
        }
      }

      return slots;
    } catch (e) {
      debugPrint('Error finding available slots: $e');
      return [];
    }
  }

  /// Check if a specific time slot is available
  Future<bool> isSlotAvailable(DateTime start, DateTime end) async {
    if (!_isConnected || _calendarApi == null) {
      return true; // Assume available if not connected
    }

    try {
      // Check for events that overlap with the proposed time
      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: start,
        timeMax: end,
        singleEvents: true,
        q: 'meeting', // Filter for meeting-related events
      );

      // If there are any events, the slot is not fully available
      return (events.items?.length ?? 0) == 0;
    } catch (e) {
      debugPrint('Error checking slot availability: $e');
      return true;
    }
  }

  /// Sign out and clear connection
  Future<void> disconnect() async {
    await _googleSignIn?.signOut();
    await _storage.delete(key: _accessTokenKey);
    _isConnected = false;
    _calendarApi = null;
    _cachedPatterns = null;
  }

  /// Clear connection without signing out (for when user wants to stay signed in)
  void clearCache() {
    _cachedPatterns = null;
  }
}

/// Custom HTTP client with Google authentication
class _GoogleAuthClient extends http.BaseClient {
  final String _accessToken;
  final _httpClient = http.Client();

  _GoogleAuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Add Authorization header
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _httpClient.send(request);
  }
}

/// Time slot for scheduling
class TimeSlot {
  final DateTime start;
  final DateTime end;
  final Duration duration;

  TimeSlot({
    required this.start,
    required this.end,
    required this.duration,
  });

  @override
  String toString() {
    return '${start.hour}:${start.minute.toString().padLeft(2, '0')} - ${end.hour}:${end.minute.toString().padLeft(2, '0')}';
  }
}

/// Calendar event model (simplified)
class CalendarEvent {
  final String title;
  final DateTime start;
  final DateTime end;

  CalendarEvent({
    required this.title,
    required this.start,
    required this.end,
  });

  bool get isLateMeeting => start.hour >= 18;
  bool get isVeryLateMeeting => start.hour >= 21;
  bool get isEarlyMeeting => start.hour > 0 && start.hour < 8;
  bool get isWeekendMeeting =>
      start.weekday == DateTime.saturday || start.weekday == DateTime.sunday;
}
