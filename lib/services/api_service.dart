import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/margin_context.dart';

/// Service for fetching data from the Margin backend API
class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({
    this.baseUrl = 'http://localhost:8080',
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Fetch margin context from backend
  /// Falls back to mock data if API is unavailable
  Future<MarginContext> fetchMarginContext() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/margin/context'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Return mock data on timeout
          throw Exception('API timeout - using mock data');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return MarginContext.fromJson(json);
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      // Fall back to mock data for development
      return _getMockContext();
    }
  }

  /// Get mock context data for development/testing
  MarginContext _getMockContext() {
    return MarginContext(
      version: '1.0.0',
      lastUpdated: '2024-07-15',
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
      holidays: [
        Holiday(date: '2024-11-28', name: 'Thanksgiving', bufferDays: 2, adjustment: 10),
        Holiday(date: '2024-12-25', name: 'Christmas', bufferDays: 2, adjustment: 8),
        Holiday(date: '2025-01-01', name: 'New Year', bufferDays: 1, adjustment: 8),
        Holiday(date: '2025-07-04', name: 'Independence Day', bufferDays: 1, adjustment: 6),
      ],
      industryBenchmarks: {
        'software_engineer': IndustryBenchmark(
          averageMeetingHours: 6.0,
          averageFocusTime: 5.5,
          averageCommunicationsLoad: 15,
          description: 'Tech industry benchmarks',
        ),
        'product_manager': IndustryBenchmark(
          averageMeetingHours: 12.0,
          averageFocusTime: 2.5,
          averageCommunicationsLoad: 35,
          description: 'Product management role',
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
    );
  }

  /// Dispose the HTTP client
  void dispose() {
    _client.close();
  }
}
