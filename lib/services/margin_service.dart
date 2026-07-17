import 'package:flutter/foundation.dart';
import '../models/margin_score.dart';
import '../models/margin_context.dart';
import '../models/user_input.dart';
import '../models/feedback.dart';

/// Service for Margin Score calculations
class MarginService {
  final MarginContext _context;

  MarginService(this._context);

  /// Calculate Margin Score from user inputs
  MarginScore calculateScore(UserInput input) {
    return MarginScore.calculate(
      sleep: input.sleep,
      energy: input.energy,
      meetingLoad: input.meetingLoad,
      context: _context,
    );
  }

  /// Apply feedback to create an adjusted context
  MarginContext applyFeedback(DimensionFeedback feedback) {
    debugPrint('🔧 MarginService.applyFeedback');
    debugPrint('   Dimension: ${feedback.dimensionName} (${feedback.dimensionId})');
    debugPrint('   Current Value: ${feedback.currentValue}');
    debugPrint('   Suggested Value: ${feedback.suggestedValue ?? "N/A (using default adjustment)"}');

    switch (feedback.dimensionId) {
      case 'day_factor':
        final adjustedDayFactors = Map<String, DayFactor>.from(_context.dayFactors);
        final todayKey = _getTodayDayKey();
        final currentFactor = adjustedDayFactors[todayKey];
        if (currentFactor != null) {
          // Use AI suggested value if available, otherwise add 1
          final newAdjustment = feedback.suggestedValue != null
              ? (double.tryParse(feedback.suggestedValue!)?.toInt() ?? currentFactor.adjustment + 1)
              : currentFactor.adjustment + 1;

          debugPrint('   New Day Factor adjustment: $newAdjustment');
          adjustedDayFactors[todayKey] = DayFactor(
            adjustment: newAdjustment,
            reason: feedback.reason,
            description: '${currentFactor.description} (adjusted based on feedback)',
          );
        }
        // Store adjustment in dimensionOverrides for persistence
        final overrides = Map<String, double>.from(_context.dimensionOverrides ?? {});
        overrides['day_factor'] = adjustedDayFactors[todayKey]?.adjustment.toDouble() ?? 0.0;
        debugPrint('   💾 Stored day_factor override in dimensionOverrides: ${overrides['day_factor']}');
        return MarginContext(
          version: _context.version,
          lastUpdated: _context.lastUpdated,
          dayFactors: adjustedDayFactors,
          seasonalFactors: _context.seasonalFactors,
          holidays: _context.holidays,
          industryBenchmarks: _context.industryBenchmarks,
          timezoneFactors: _context.timezoneFactors,
          companySizeFactors: _context.companySizeFactors,
          sleepImpactFactors: _context.sleepImpactFactors,
          userRole: _context.userRole,
          timezoneSpan: _context.timezoneSpan,
          companySize: _context.companySize,
          chronotype: _context.chronotype,
          userMeetingHours: _context.userMeetingHours,
          aiClassifiedCompanySizeAdjustment: _context.aiClassifiedCompanySizeAdjustment,
          workLifePatterns: _context.workLifePatterns,
          dimensionOverrides: overrides,
        );

      case 'seasonal_factor':
        debugPrint('   🔍 seasonal_factors keys: ${_context.seasonalFactors.keys}');
        final adjustedSeasonal = Map<String, SeasonalFactor>.from(_context.seasonalFactors);
        final currentKey = _getCurrentSeasonKey();
        debugPrint('   🔍 currentKey (season): $currentKey');
        final currentFactor = adjustedSeasonal[currentKey];
        debugPrint('   🔍 currentFactor: ${currentFactor != null ? currentFactor.adjustment : 'NULL'}');
        if (currentFactor != null) {
          // Use AI suggested value if available, otherwise add 1
          final newAdjustment = feedback.suggestedValue != null
              ? (double.tryParse(feedback.suggestedValue!)?.toInt() ?? currentFactor.adjustment + 1)
              : currentFactor.adjustment + 1;

          debugPrint('   New Seasonal Factor adjustment: $newAdjustment');
          adjustedSeasonal[currentKey] = SeasonalFactor(
            adjustment: newAdjustment,
            reason: feedback.reason,
            description: currentFactor.description,
            months: currentFactor.months,
          );
        }
        // Store adjustment in dimensionOverrides for persistence
        final overrides = Map<String, double>.from(_context.dimensionOverrides ?? {});
        overrides['seasonal_factor'] = adjustedSeasonal[currentKey]?.adjustment.toDouble() ?? 0.0;
        debugPrint('   💾 Stored seasonal_factor override in dimensionOverrides: ${overrides['seasonal_factor']}');
        debugPrint('   🔍 Full overrides map: $overrides');
        debugPrint('   🔍 overrides.isEmpty: ${overrides.isEmpty}');
        return MarginContext(
          version: _context.version,
          lastUpdated: _context.lastUpdated,
          dayFactors: _context.dayFactors,
          seasonalFactors: adjustedSeasonal,
          holidays: _context.holidays,
          industryBenchmarks: _context.industryBenchmarks,
          timezoneFactors: _context.timezoneFactors,
          companySizeFactors: _context.companySizeFactors,
          sleepImpactFactors: _context.sleepImpactFactors,
          userRole: _context.userRole,
          timezoneSpan: _context.timezoneSpan,
          companySize: _context.companySize,
          chronotype: _context.chronotype,
          userMeetingHours: _context.userMeetingHours,
          aiClassifiedCompanySizeAdjustment: _context.aiClassifiedCompanySizeAdjustment,
          workLifePatterns: _context.workLifePatterns,
          dimensionOverrides: overrides,
        );

      case 'timezone_factor':
        final adjustedTz = Map<String, TimezoneFactor>.from(_context.timezoneFactors);
        final currentKey = _context.timezoneSpan ?? 'single_timezone';
        final currentFactor = adjustedTz[currentKey];
        if (currentFactor != null) {
          // Use AI suggested value if available, otherwise reduce penalty by 1
          final newPenalty = feedback.suggestedValue != null
              ? (double.tryParse(feedback.suggestedValue!)?.toInt() ?? currentFactor.penalty + 1)
              : currentFactor.penalty + 1;

          debugPrint('   New Timezone Factor penalty: $newPenalty');
          adjustedTz[currentKey] = TimezoneFactor(
            penalty: newPenalty,
            description: '${currentFactor.description} (adjusted based on feedback)',
          );
        }
        // Store adjustment in dimensionOverrides for persistence
        final overrides = Map<String, double>.from(_context.dimensionOverrides ?? {});
        overrides['timezone_factor'] = adjustedTz[currentKey]?.penalty.toDouble() ?? 0.0;
        debugPrint('   💾 Stored timezone_factor override in dimensionOverrides: ${overrides['timezone_factor']}');
        return MarginContext(
          version: _context.version,
          lastUpdated: _context.lastUpdated,
          dayFactors: _context.dayFactors,
          seasonalFactors: _context.seasonalFactors,
          holidays: _context.holidays,
          industryBenchmarks: _context.industryBenchmarks,
          timezoneFactors: adjustedTz,
          companySizeFactors: _context.companySizeFactors,
          sleepImpactFactors: _context.sleepImpactFactors,
          userRole: _context.userRole,
          timezoneSpan: _context.timezoneSpan,
          companySize: _context.companySize,
          chronotype: _context.chronotype,
          userMeetingHours: _context.userMeetingHours,
          aiClassifiedCompanySizeAdjustment: _context.aiClassifiedCompanySizeAdjustment,
          workLifePatterns: _context.workLifePatterns,
          dimensionOverrides: overrides,
        );

      case 'company_size':
        final adjustedCompany = Map<String, CompanySizeFactor>.from(_context.companySizeFactors);
        final currentKey = _context.companySize ?? 'mid_market';
        final currentFactor = adjustedCompany[currentKey];
        if (currentFactor != null) {
          // Use AI suggested value if available, otherwise add 1
          final newAdjustment = feedback.suggestedValue != null
              ? (double.tryParse(feedback.suggestedValue!)?.toInt() ?? currentFactor.adjustment + 1)
              : currentFactor.adjustment + 1;

          debugPrint('   New Company Size adjustment: $newAdjustment');
          adjustedCompany[currentKey] = CompanySizeFactor(
            adjustment: newAdjustment,
            description: '${currentFactor.description} (adjusted based on feedback)',
          );
        }
        // Store adjustment in dimensionOverrides for persistence
        final overrides = Map<String, double>.from(_context.dimensionOverrides ?? {});
        overrides['company_size'] = adjustedCompany[currentKey]?.adjustment.toDouble() ?? 0.0;
        debugPrint('   💾 Stored company_size override in dimensionOverrides: ${overrides['company_size']}');
        return MarginContext(
          version: _context.version,
          lastUpdated: _context.lastUpdated,
          dayFactors: _context.dayFactors,
          seasonalFactors: _context.seasonalFactors,
          holidays: _context.holidays,
          industryBenchmarks: _context.industryBenchmarks,
          timezoneFactors: _context.timezoneFactors,
          companySizeFactors: adjustedCompany,
          sleepImpactFactors: _context.sleepImpactFactors,
          userRole: _context.userRole,
          timezoneSpan: _context.timezoneSpan,
          companySize: _context.companySize,
          chronotype: _context.chronotype,
          userMeetingHours: _context.userMeetingHours,
          aiClassifiedCompanySizeAdjustment: _context.aiClassifiedCompanySizeAdjustment,
          workLifePatterns: _context.workLifePatterns,
          dimensionOverrides: overrides,
        );

      case 'holiday_factor':
        debugPrint('   ℹ️ Holiday factor is calculated from actual holidays and cannot be manually adjusted');
        return _context;

      case 'meeting_load':
        debugPrint('   ℹ️ Meeting load is derived from calendar data, not adjustable via feedback');
        return _context;

      case 'sleep_impact':
        if (feedback.suggestedValue != null) {
          final overrideValue = double.tryParse(feedback.suggestedValue!);
          if (overrideValue != null) {
            debugPrint('   🎯 Storing sleep impact override: $overrideValue');
            // Create or update dimension overrides map
            final overrides = Map<String, double>.from(_context.dimensionOverrides ?? {});
            overrides['sleep_impact'] = overrideValue;
            return _context.copyWith(dimensionOverrides: overrides);
          }
        }
        debugPrint('   ℹ️ Sleep impact feedback has no suggested value, ignoring');
        return _context;

      case 'stress_indicators':
        debugPrint('   ℹ️ Stress indicators are derived from work-life patterns, not adjustable via feedback');
        return _context;

      default:
        debugPrint('   ⚠️ Unknown dimension ID: ${feedback.dimensionId}');
        return _context;
    }
  }

  String _getTodayDayKey() {
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return dayNames[DateTime.now().weekday - 1];
  }

  String _getCurrentSeasonKey() {
    final month = DateTime.now().month;
    final quarter = ((month - 1) ~/ 3) + 1;
    return 'Q$quarter';
  }

  String _getSleepDescription(double sleepHours) {
    final roundedHours = sleepHours.round();
    final hours = sleepHours.toStringAsFixed(1);
    final factors = _context.sleepImpactFactors;

    if (factors.optimal.hours.contains(roundedHours)) {
      // Optimal sleep - vary message based on exact hours
      if (sleepHours >= 7.5 && sleepHours <= 8.5) {
        return 'Sweet spot! $hours hours for peak cognitive performance';
      } else if (sleepHours >= 8.5) {
        return 'Well-rested: $hours hours, excellent recovery time';
      } else {
        return 'Optimal rest: $hours hours for sustained focus';
      }
    } else if (factors.adequate.hours.contains(roundedHours)) {
      // Adequate sleep - helpful messages
      if (roundedHours == 6) {
        return 'Functional on $hours hours, but 7-8h is better';
      } else if (roundedHours == 10) {
        return 'Adequate: $hours hours, slight oversleep';
      } else {
        return 'Adequate: $hours hours, room for improvement';
      }
    } else if (factors.suboptimal.hours.contains(roundedHours)) {
      // Suboptimal sleep - warning messages
      if (roundedHours == 5) {
        return 'Sleep deficit alert: $hours hours impacts decision-making';
      } else if (roundedHours == 11) {
        return 'Oversleeping: $hours hours may cause grogginess';
      } else {
        return 'Suboptimal: $hours hours affects your margin';
      }
    } else if (factors.oversleep.hours.contains(roundedHours)) {
      // Oversleep - gentle warning
      return 'Overslept: $hours hours, may affect energy levels';
    } else {
      // Critical sleep - urgent messages
      if (roundedHours <= 4) {
        return 'Critical: Only $hours hours - consider prioritizing rest';
      } else if (roundedHours == 0) {
        return 'No sleep detected - immediate burnout risk';
      } else {
        return 'Critical deprivation at $hours hours - highly discouraged';
      }
    }
  }

  String _getSleepImpactValue(double sleepHours) {
    final roundedHours = sleepHours.round();
    final adjustment = _context.getSleepImpact(sleepHours);
    final factors = _context.sleepImpactFactors;

    // Return value with quality prefix for dimension_card.dart to parse
    if (factors.optimal.hours.contains(roundedHours)) {
      return 'OPTIMAL:$adjustment';
    } else if (factors.adequate.hours.contains(roundedHours)) {
      return 'ADEQUATE:$adjustment';
    } else if (factors.suboptimal.hours.contains(roundedHours)) {
      return 'SUBOPTIMAL:$adjustment';
    } else if (factors.oversleep.hours.contains(roundedHours)) {
      return 'OVERSLEEP:$adjustment';
    } else {
      return 'CRITICAL:$adjustment';
    }
  }

  String _getMeetingPenalty(double meetingLoad) {
    // Calculate penalty using same formula as margin_score.dart
    double meetingPenalty;
    if (meetingLoad <= 2) {
      meetingPenalty = meetingLoad * 1.5;
    } else if (meetingLoad <= 6) {
      meetingPenalty = 3 + (meetingLoad - 2) * 3;
    } else {
      meetingPenalty = 15 + (meetingLoad - 6) * 2.5;
    }

    // Return as formatted penalty value
    final penaltyValue = meetingPenalty.toStringAsFixed(1);
    return '-$penaltyValue';
  }

  /// Get quality label for a given sleep impact value
  /// Returns a label like "OPTIMAL:5.0", "CRITICAL:-3.0", etc.
  String _getQualityLabelForValue(double value) {
    if (value >= 4) return 'OPTIMAL:$value';
    if (value >= 1) return 'ADEQUATE:$value';
    if (value >= -2) return 'SUBOPTIMAL:$value';
    if (value > -5) return 'CRITICAL:$value';
    return 'CRITICAL:$value';
  }

  /// Get current dimension values for display
  Map<String, DimensionValue> getCurrentDimensions([UserInput? userInput]) {
    final now = DateTime.now();

    return {
      'day_factor': DimensionValue(
        id: 'day_factor',
        name: 'Day Factor',
        value: _context.getDayFactor(now.weekday).toString(),
        description: _context.dayFactors[_getTodayDayKey()]?.description ?? '',
        category: DimensionCategory.temporal,
      ),
      'seasonal_factor': DimensionValue(
        id: 'seasonal_factor',
        name: 'Seasonal Factor',
        value: _context.getSeasonalFactor(now.month).toString(),
        description: _context.seasonalFactors[_getCurrentSeasonKey()]?.description ?? '',
        category: DimensionCategory.temporal,
      ),
      'holiday_factor': DimensionValue(
        id: 'holiday_factor',
        name: 'Holiday Buffer',
        value: _context.getHolidayFactor(now).toString(),
        description: 'Upcoming holiday adjustments',
        category: DimensionCategory.temporal,
      ),
      'timezone_factor': DimensionValue(
        id: 'timezone_factor',
        name: 'Timezone Penalty',
        value: _context.getTimezonePenalty().toString(),
        description: _context.timezoneFactors[_context.timezoneSpan]?.description ?? '',
        category: DimensionCategory.professional,
      ),
      'company_size': DimensionValue(
        id: 'company_size',
        name: 'Company Size Factor',
        value: _context.getCompanySizeAdjustment().toString(),
        description: _context.companySizeFactors[_context.companySize]?.description ?? '',
        category: DimensionCategory.professional,
      ),
      'meeting_load': DimensionValue(
        id: 'meeting_load',
        name: 'Meeting Load',
        value: _getMeetingPenalty(userInput?.meetingLoad ?? 0),
        description: 'Hours: ${userInput?.meetingLoad.toStringAsFixed(1) ?? '0.0'}h',
        category: DimensionCategory.professional,
      ),
      'sleep_impact': DimensionValue(
        id: 'sleep_impact',
        name: 'Sleep Impact',
        value: _context.dimensionOverrides?['sleep_impact'] != null
            ? _getQualityLabelForValue(_context.dimensionOverrides!['sleep_impact']!)
            : _getSleepImpactValue(userInput?.sleep ?? 7),
        description: _context.dimensionOverrides?['sleep_impact'] != null
            ? '${_getSleepDescription(userInput?.sleep ?? 7)} (user adjusted: ${_context.dimensionOverrides!['sleep_impact']!.toStringAsFixed(1)})'
            : _getSleepDescription(userInput?.sleep ?? 7),
        category: DimensionCategory.personal,
      ),
      'stress_indicators': DimensionValue(
        id: 'stress_indicators',
        name: 'Meeting Pattern Stress',
        value: _context.getStressAdjustments().toStringAsFixed(2),
        description: _context.workLifePatterns?.description ?? 'No data available',
        category: DimensionCategory.professional,
      ),
    };
  }
}

/// Represents a single dimension value for display
class DimensionValue {
  final String id;
  final String name;
  final String value;
  final String description;
  final DimensionCategory category;

  DimensionValue({
    required this.id,
    required this.name,
    required this.value,
    required this.description,
    required this.category,
  });
}

/// Categories for organizing dimensions
enum DimensionCategory {
  temporal,
  professional,
  personal,
}
