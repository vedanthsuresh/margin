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
    // For now, create a copy of the context with adjusted values
    // In the future, this would use AI to intelligently adjust factors

    switch (feedback.dimensionId) {
      case 'day_factor':
        final adjustedDayFactors = Map<String, DayFactor>.from(_context.dayFactors);
        final todayKey = _getTodayDayKey();
        final currentFactor = adjustedDayFactors[todayKey];
        if (currentFactor != null) {
          adjustedDayFactors[todayKey] = DayFactor(
            adjustment: currentFactor.adjustment + 1,
            reason: currentFactor.reason,
            description: '${currentFactor.description} (user adjusted)',
          );
        }
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
        );

      case 'seasonal_factor':
        final adjustedSeasonal = Map<String, SeasonalFactor>.from(_context.seasonalFactors);
        final currentKey = _getCurrentSeasonKey();
        final currentFactor = adjustedSeasonal[currentKey];
        if (currentFactor != null) {
          adjustedSeasonal[currentKey] = SeasonalFactor(
            adjustment: currentFactor.adjustment + 1,
            reason: currentFactor.reason,
            description: currentFactor.description,
            months: currentFactor.months,
          );
        }
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
        );

      case 'timezone_factor':
        final adjustedTz = Map<String, TimezoneFactor>.from(_context.timezoneFactors);
        final currentKey = _context.timezoneSpan ?? 'single_timezone';
        final currentFactor = adjustedTz[currentKey];
        if (currentFactor != null) {
          adjustedTz[currentKey] = TimezoneFactor(
            penalty: currentFactor.penalty + 1,
            description: '${currentFactor.description} (user adjusted)',
          );
        }
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
        );

      case 'company_size':
        final adjustedCompany = Map<String, CompanySizeFactor>.from(_context.companySizeFactors);
        final currentKey = _context.companySize ?? 'mid_market';
        final currentFactor = adjustedCompany[currentKey];
        if (currentFactor != null) {
          adjustedCompany[currentKey] = CompanySizeFactor(
            adjustment: currentFactor.adjustment + 1,
            description: '${currentFactor.description} (user adjusted)',
          );
        }
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
        );

      default:
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

  String _getWorkLifeDescription() {
    final patterns = _context.workLifePatterns;
    if (patterns == null) return 'No data available';

    if (patterns.weekendMeetingsCount > 0) {
      return '${patterns.weekendMeetingsCount} weekend meetings detected';
    } else if (patterns.lateMeetingsCount > 0) {
      return '${patterns.lateMeetingsCount} late meetings detected';
    } else {
      return 'Good boundaries maintained';
    }
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
        value: _getSleepImpactValue(userInput?.sleep ?? 7),
        description: _getSleepDescription(userInput?.sleep ?? 7),
        category: DimensionCategory.personal,
      ),
      'stress_indicators': DimensionValue(
        id: 'stress_indicators',
        name: 'Meeting Pattern Stress',
        value: _context.getStressAdjustments().toStringAsFixed(2),
        description: _context.workLifePatterns?.description ?? 'No data available',
        category: DimensionCategory.professional,
      ),
      'work_life_balance': DimensionValue(
        id: 'work_life_balance',
        name: 'Work-Life Balance',
        value: _context.getWorkLifePenalties().toStringAsFixed(2),
        description: _getWorkLifeDescription(),
        category: DimensionCategory.personal,
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
