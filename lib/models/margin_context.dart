/// Margin Context - all contextual enrichment factors from backend
class MarginContext {
  final String version;
  final String lastUpdated;
  final Map<String, DayFactor> dayFactors;
  final Map<String, SeasonalFactor> seasonalFactors;
  final List<Holiday> holidays;
  final Map<String, IndustryBenchmark> industryBenchmarks;
  final Map<String, TimezoneFactor> timezoneFactors;
  final Map<String, CompanySizeFactor> companySizeFactors;
  final SleepImpactFactor sleepImpactFactors;

  // User settings (default values, would be set by user)
  String? userRole;
  String? timezoneSpan;
  String? companySize;
  String? chronotype;
  List<int> userMeetingHours;

  // Work-life patterns from calendar analysis or manual input
  WorkLifePatterns? workLifePatterns;

  MarginContext({
    required this.version,
    required this.lastUpdated,
    required this.dayFactors,
    required this.seasonalFactors,
    required this.holidays,
    required this.industryBenchmarks,
    required this.timezoneFactors,
    required this.companySizeFactors,
    required this.sleepImpactFactors,
    this.userRole = 'software_engineer',
    this.timezoneSpan = 'single_timezone',
    this.companySize = 'mid_market',
    this.chronotype = 'consistent',
    this.userMeetingHours = const [6, 6, 6, 6, 6], // Mon-Fri
    this.workLifePatterns,
  });

  /// Parse from JSON (from backend API)
  factory MarginContext.fromJson(Map<String, dynamic> json) {
    final dayFactors = <String, DayFactor>{};
    if (json['day_factors'] != null) {
      (json['day_factors'] as Map<String, dynamic>).forEach((key, value) {
        dayFactors[key] = DayFactor.fromJson(value);
      });
    }

    final seasonalFactors = <String, SeasonalFactor>{};
    if (json['seasonal_factors'] != null) {
      (json['seasonal_factors'] as Map<String, dynamic>).forEach((key, value) {
        seasonalFactors[key] = SeasonalFactor.fromJson(value);
      });
    }

    final holidays = <Holiday>[];
    if (json['holidays_2024'] != null) {
      for (var item in json['holidays_2024']) {
        holidays.add(Holiday.fromJson(item));
      }
    }
    if (json['holidays_2025'] != null) {
      for (var item in json['holidays_2025']) {
        holidays.add(Holiday.fromJson(item));
      }
    }

    final industryBenchmarks = <String, IndustryBenchmark>{};
    if (json['industry_benchmarks'] != null) {
      (json['industry_benchmarks'] as Map<String, dynamic>).forEach((key, value) {
        industryBenchmarks[key] = IndustryBenchmark.fromJson(value);
      });
    }

    final timezoneFactors = <String, TimezoneFactor>{};
    if (json['timezone_factors'] != null) {
      (json['timezone_factors'] as Map<String, dynamic>).forEach((key, value) {
        timezoneFactors[key] = TimezoneFactor.fromJson(value);
      });
    }

    final companySizeFactors = <String, CompanySizeFactor>{};
    if (json['company_size_factors'] != null) {
      (json['company_size_factors'] as Map<String, dynamic>).forEach((key, value) {
        companySizeFactors[key] = CompanySizeFactor.fromJson(value);
      });
    }

    // Parse sleep impact factors
    SleepImpactFactor sleepImpactFactors = const SleepImpactFactor(
      optimal: SleepRange(hours: [7, 8, 9], adjustment: 5, description: 'Optimal'),
      adequate: SleepRange(hours: [6, 10], adjustment: 2, description: 'Adequate'),
      suboptimal: SleepRange(hours: [5, 11], adjustment: -3, description: 'Suboptimal'),
      critical: SleepRange(hours: [0, 1, 2, 3, 4], adjustment: -10, description: 'Critical'),
      oversleep: SleepRange(hours: [12, 13, 14, 15], adjustment: -2, description: 'Oversleep'),
    );
    if (json['sleep_impact_factors'] != null) {
      sleepImpactFactors = SleepImpactFactorsParser.fromJson(json['sleep_impact_factors']);
    }

    return MarginContext(
      version: json['version'] ?? '1.0.0',
      lastUpdated: json['last_updated'] ?? '',
      dayFactors: dayFactors,
      seasonalFactors: seasonalFactors,
      holidays: holidays,
      industryBenchmarks: industryBenchmarks,
      timezoneFactors: timezoneFactors,
      companySizeFactors: companySizeFactors,
      sleepImpactFactors: sleepImpactFactors,
    );
  }

  /// Get day factor for a given weekday (1=Monday, 7=Sunday)
  double getDayFactor(int weekday) {
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = dayNames[weekday - 1];
    return dayFactors[dayName]?.adjustment.toDouble() ?? 0.0;
  }

  /// Get seasonal factor for a given month (1-12)
  double getSeasonalFactor(int month) {
    final quarter = ((month - 1) ~/ 3) + 1;
    final seasonKey = 'Q$quarter';
    return seasonalFactors[seasonKey]?.adjustment.toDouble() ?? 0.0;
  }

  /// Get holiday adjustment for current date (including buffer days)
  double getHolidayFactor(DateTime date) {
    for (var holiday in holidays) {
      if (holiday.isEffective(date)) {
        return holiday.adjustment.toDouble();
      }
    }
    return 0.0;
  }

  /// Get timezone penalty based on user's timezone span
  double getTimezonePenalty() {
    return timezoneFactors[timezoneSpan]?.penalty.toDouble() ?? 0.0;
  }

  /// Get company size adjustment
  double getCompanySizeAdjustment() {
    return companySizeFactors[companySize]?.adjustment.toDouble() ?? 0.0;
  }

  /// Get sleep impact based on hours slept
  double getSleepImpact(double hours) {
    final roundedHours = hours.round();
    if (sleepImpactFactors.optimal.hours.contains(roundedHours)) {
      return sleepImpactFactors.optimal.adjustment.toDouble();
    } else if (sleepImpactFactors.adequate.hours.contains(roundedHours)) {
      return sleepImpactFactors.adequate.adjustment.toDouble();
    } else if (sleepImpactFactors.suboptimal.hours.contains(roundedHours)) {
      return sleepImpactFactors.suboptimal.adjustment.toDouble();
    } else if (sleepImpactFactors.oversleep.hours.contains(roundedHours)) {
      return sleepImpactFactors.oversleep.adjustment.toDouble();
    } else {
      return sleepImpactFactors.critical.adjustment.toDouble();
    }
  }

  /// Get stress adjustments based on meeting patterns
  double getStressAdjustments() {
    if (workLifePatterns == null) return 0.0;

    // Calculate stress from late/early meetings
    double stress = 0.0;
    stress += workLifePatterns!.lateMeetingsCount * 0.5;
    stress += workLifePatterns!.veryLateMeetingsCount * 1.5;
    stress += workLifePatterns!.earlyMeetingsCount * 0.3;
    stress += workLifePatterns!.veryEarlyMeetingsCount * 1.0;

    // Average out over analysis period (30 days)
    return stress / workLifePatterns!.analysisDays;
  }

  /// Get work-life penalties from after-hours and weekend work
  double getWorkLifePenalties() {
    if (workLifePatterns == null) return 0.0;

    // Weekend work is a significant boundary violation
    final weekendPenalty = workLifePatterns!.weekendMeetingsCount * 2.0;

    // Average out over analysis period (30 days)
    return weekendPenalty / workLifePatterns!.analysisDays;
  }

  /// Get industry delta for user's role
  double getIndustryDelta(double userMeetingHours) {
    final benchmark = industryBenchmarks[userRole];
    if (benchmark == null) return 0.0;
    return userMeetingHours - benchmark.averageMeetingHours;
  }
}

// ===== SUB-MODELS =====

class DayFactor {
  final int adjustment;
  final String reason;
  final String description;

  DayFactor({
    required this.adjustment,
    required this.reason,
    required this.description,
  });

  factory DayFactor.fromJson(Map<String, dynamic> json) {
    return DayFactor(
      adjustment: json['adjustment'] ?? 0,
      reason: json['reason'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adjustment': adjustment,
      'reason': reason,
      'description': description,
    };
  }
}

class SeasonalFactor {
  final int adjustment;
  final String reason;
  final String description;
  final List<int> months;

  SeasonalFactor({
    required this.adjustment,
    required this.reason,
    required this.description,
    required this.months,
  });

  factory SeasonalFactor.fromJson(Map<String, dynamic> json) {
    return SeasonalFactor(
      adjustment: json['adjustment'] ?? 0,
      reason: json['reason'] ?? '',
      description: json['description'] ?? '',
      months: (json['months'] as List?)?.cast<int>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adjustment': adjustment,
      'reason': reason,
      'description': description,
      'months': months,
    };
  }
}

class Holiday {
  final String date;
  final String name;
  final int bufferDays;
  final int adjustment;

  Holiday({
    required this.date,
    required this.name,
    required this.bufferDays,
    required this.adjustment,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      date: json['date'] ?? '',
      name: json['name'] ?? '',
      bufferDays: json['buffer_days'] ?? 0,
      adjustment: json['adjustment'] ?? 0,
    );
  }

  /// Check if this holiday is effective on the given date (including buffer days)
  bool isEffective(DateTime date) {
    final holidayDate = DateTime.parse(this.date);
    final diff = date.difference(holidayDate).inDays.abs();
    return diff <= bufferDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'name': name,
      'buffer_days': bufferDays,
      'adjustment': adjustment,
    };
  }
}

class IndustryBenchmark {
  final double averageMeetingHours;
  final double averageFocusTime;
  final int averageCommunicationsLoad;
  final String description;

  IndustryBenchmark({
    required this.averageMeetingHours,
    required this.averageFocusTime,
    required this.averageCommunicationsLoad,
    required this.description,
  });

  factory IndustryBenchmark.fromJson(Map<String, dynamic> json) {
    return IndustryBenchmark(
      averageMeetingHours: (json['average_meeting_hours'] as num?)?.toDouble() ?? 0.0,
      averageFocusTime: (json['average_focus_time'] as num?)?.toDouble() ?? 0.0,
      averageCommunicationsLoad: json['average_communications_load'] ?? 0,
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average_meeting_hours': averageMeetingHours,
      'average_focus_time': averageFocusTime,
      'average_communications_load': averageCommunicationsLoad,
      'description': description,
    };
  }
}

class TimezoneFactor {
  final int penalty;
  final String description;

  TimezoneFactor({
    required this.penalty,
    required this.description,
  });

  factory TimezoneFactor.fromJson(Map<String, dynamic> json) {
    return TimezoneFactor(
      penalty: json['penalty'] ?? 0,
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'penalty': penalty,
      'description': description,
    };
  }
}

class CompanySizeFactor {
  final int adjustment;
  final String description;

  CompanySizeFactor({
    required this.adjustment,
    required this.description,
  });

  factory CompanySizeFactor.fromJson(Map<String, dynamic> json) {
    return CompanySizeFactor(
      adjustment: json['adjustment'] ?? 0,
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adjustment': adjustment,
      'description': description,
    };
  }
}

class SleepRange {
  final List<int> hours;
  final int adjustment;
  final String description;

  const SleepRange({
    required this.hours,
    required this.adjustment,
    required this.description,
  });
}

class SleepImpactFactor {
  final SleepRange optimal;
  final SleepRange adequate;
  final SleepRange suboptimal;
  final SleepRange critical;
  final SleepRange oversleep;

  const SleepImpactFactor({
    required this.optimal,
    required this.adequate,
    required this.suboptimal,
    required this.critical,
    required this.oversleep,
  });
}

/// Parser for sleep impact factors from JSON
class SleepImpactFactorsParser {
  static SleepImpactFactor fromJson(Map<String, dynamic> json) {
    return SleepImpactFactor(
      optimal: SleepRange(
        hours: _parseHours(json['optimal']?['hours']),
        adjustment: json['optimal']?['adjustment'] ?? 5,
        description: json['optimal']?['description'] ?? 'Optimal',
      ),
      adequate: SleepRange(
        hours: _parseHours(json['adequate']?['hours']),
        adjustment: json['adequate']?['adjustment'] ?? 2,
        description: json['adequate']?['description'] ?? 'Adequate',
      ),
      suboptimal: SleepRange(
        hours: _parseHours(json['suboptimal']?['hours']),
        adjustment: json['suboptimal']?['adjustment'] ?? -3,
        description: json['suboptimal']?['description'] ?? 'Suboptimal',
      ),
      critical: SleepRange(
        hours: _parseHours(json['critical']?['hours']),
        adjustment: json['critical']?['adjustment'] ?? -10,
        description: json['critical']?['description'] ?? 'Critical',
      ),
      oversleep: SleepRange(
        hours: _parseHours(json['oversleep']?['hours']),
        adjustment: json['oversleep']?['adjustment'] ?? -2,
        description: json['oversleep']?['description'] ?? 'Oversleep',
      ),
    );
  }

  static List<int> _parseHours(dynamic hours) {
    if (hours is List) {
      return hours.cast<int>();
    }
    return [];
  }
}

/// Work-life pattern analysis results
/// Can come from calendar analysis or manual user input
class WorkLifePatterns {
  final int lateMeetingsCount;
  final int veryLateMeetingsCount;
  final int earlyMeetingsCount;
  final int veryEarlyMeetingsCount;
  final int weekendMeetingsCount;
  final double averageDailyPenalty;
  final int analysisDays;

  WorkLifePatterns({
    required this.lateMeetingsCount,
    required this.veryLateMeetingsCount,
    required this.earlyMeetingsCount,
    required this.veryEarlyMeetingsCount,
    required this.weekendMeetingsCount,
    required this.averageDailyPenalty,
    required this.analysisDays,
  });

  /// Create from manual user preferences
  factory WorkLifePatterns.fromManualPreferences({
    required bool worksLateHours,
    required bool worksWeekends,
  }) {
    double penalty = 0;

    // Estimate daily penalty based on manual answers
    if (worksLateHours) penalty += 3.0;
    if (worksWeekends) penalty += 5.0;

    return WorkLifePatterns(
      lateMeetingsCount: worksLateHours ? 8 : 0,
      veryLateMeetingsCount: 0,
      earlyMeetingsCount: 0,
      veryEarlyMeetingsCount: 0,
      weekendMeetingsCount: worksWeekends ? 4 : 0,
      averageDailyPenalty: penalty,
      analysisDays: 30,
    );
  }

  /// Get total penalty for display
  double get totalPenalty => averageDailyPenalty;

  /// Get description of patterns
  String get description {
    final parts = <String>[];

    if (weekendMeetingsCount > 0) {
      parts.add('$weekendMeetingsCount weekend meetings');
    }
    if (lateMeetingsCount > 0) {
      parts.add('$lateMeetingsCount late meetings');
    }
    if (earlyMeetingsCount > 0) {
      parts.add('$earlyMeetingsCount early meetings');
    }

    if (parts.isEmpty) {
      return 'Good work-life balance';
    }

    return 'Detected: ${parts.join(", ")}';
  }

  Map<String, dynamic> toJson() {
    return {
      'lateMeetingsCount': lateMeetingsCount,
      'veryLateMeetingsCount': veryLateMeetingsCount,
      'earlyMeetingsCount': earlyMeetingsCount,
      'veryEarlyMeetingsCount': veryEarlyMeetingsCount,
      'weekendMeetingsCount': weekendMeetingsCount,
      'averageDailyPenalty': averageDailyPenalty,
      'analysisDays': analysisDays,
    };
  }

  factory WorkLifePatterns.fromJson(Map<String, dynamic> json) {
    return WorkLifePatterns(
      lateMeetingsCount: json['lateMeetingsCount'] ?? 0,
      veryLateMeetingsCount: json['veryLateMeetingsCount'] ?? 0,
      earlyMeetingsCount: json['earlyMeetingsCount'] ?? 0,
      veryEarlyMeetingsCount: json['veryEarlyMeetingsCount'] ?? 0,
      weekendMeetingsCount: json['weekendMeetingsCount'] ?? 0,
      averageDailyPenalty: (json['averageDailyPenalty'] as num?)?.toDouble() ?? 0.0,
      analysisDays: json['analysisDays'] ?? 30,
    );
  }

  /// Create empty patterns (no penalties)
  static WorkLifePatterns get neutral => WorkLifePatterns(
        lateMeetingsCount: 0,
        veryLateMeetingsCount: 0,
        earlyMeetingsCount: 0,
        veryEarlyMeetingsCount: 0,
        weekendMeetingsCount: 0,
        averageDailyPenalty: 0,
        analysisDays: 30,
      );

  /// Create demo patterns for development/testing
  static WorkLifePatterns demo() {
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
}
