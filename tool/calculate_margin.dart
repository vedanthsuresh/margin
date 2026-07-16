#!/usr/bin/env dart

/// Terminal script for developers to test Margin Score calculation
/// Usage: dart tool/calculate_margin.dart
library margin_dev_tool;

import 'dart:convert';
import 'dart:io';

// Simple models for score calculation (copied from lib/ for standalone use)

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
  String? userRole;
  String? timezoneSpan;
  String? companySize;
  String? chronotype;
  List<int> userMeetingHours;
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
    this.userMeetingHours = const [6, 6, 6, 6, 6],
    this.workLifePatterns,
  });

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

  double getDayFactor(int weekday) {
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = dayNames[weekday - 1];
    return dayFactors[dayName]?.adjustment.toDouble() ?? 0.0;
  }

  double getSeasonalFactor(int month) {
    final quarter = ((month - 1) ~/ 3) + 1;
    final seasonKey = 'Q$quarter';
    return seasonalFactors[seasonKey]?.adjustment.toDouble() ?? 0.0;
  }

  double getHolidayFactor(DateTime date) {
    for (var holiday in holidays) {
      if (holiday.isEffective(date)) {
        return holiday.adjustment.toDouble();
      }
    }
    return 0.0;
  }

  double getTimezonePenalty() {
    return timezoneFactors[timezoneSpan]?.penalty.toDouble() ?? 0.0;
  }

  double getCompanySizeAdjustment() {
    return companySizeFactors[companySize]?.adjustment.toDouble() ?? 0.0;
  }

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

  double getStressAdjustments() {
    if (workLifePatterns == null) return 0.0;
    double stress = 0.0;
    stress += workLifePatterns!.lateMeetingsCount * 0.5;
    stress += workLifePatterns!.veryLateMeetingsCount * 1.5;
    stress += workLifePatterns!.earlyMeetingsCount * 0.3;
    stress += workLifePatterns!.veryEarlyMeetingsCount * 1.0;
    return stress / workLifePatterns!.analysisDays;
  }

  double getWorkLifePenalties() {
    if (workLifePatterns == null) return 0.0;
    final weekendPenalty = workLifePatterns!.weekendMeetingsCount * 2.0;
    return weekendPenalty / workLifePatterns!.analysisDays;
  }
}

// Supporting classes
class DayFactor {
  final int adjustment;
  final String reason;
  final String description;

  DayFactor({required this.adjustment, required this.reason, required this.description});

  factory DayFactor.fromJson(Map<String, dynamic> json) {
    return DayFactor(
      adjustment: json['adjustment'] ?? 0,
      reason: json['reason'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class SeasonalFactor {
  final int adjustment;
  final String reason;
  final String description;
  final List<int> months;

  SeasonalFactor({required this.adjustment, required this.reason, required this.description, required this.months});

  factory SeasonalFactor.fromJson(Map<String, dynamic> json) {
    return SeasonalFactor(
      adjustment: json['adjustment'] ?? 0,
      reason: json['reason'] ?? '',
      description: json['description'] ?? '',
      months: (json['months'] as List?)?.cast<int>() ?? [],
    );
  }
}

class Holiday {
  final String date;
  final String name;
  final int bufferDays;
  final int adjustment;

  Holiday({required this.date, required this.name, required this.bufferDays, required this.adjustment});

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      date: json['date'] ?? '',
      name: json['name'] ?? '',
      bufferDays: json['buffer_days'] ?? 0,
      adjustment: json['adjustment'] ?? 0,
    );
  }

  bool isEffective(DateTime date) {
    final holidayDate = DateTime.parse(this.date);
    final diff = date.difference(holidayDate).inDays.abs();
    return diff <= bufferDays;
  }
}

class IndustryBenchmark {
  final double averageMeetingHours;
  final double averageFocusTime;
  final int averageCommunicationsLoad;
  final String description;

  IndustryBenchmark({required this.averageMeetingHours, required this.averageFocusTime, required this.averageCommunicationsLoad, required this.description});

  factory IndustryBenchmark.fromJson(Map<String, dynamic> json) {
    return IndustryBenchmark(
      averageMeetingHours: (json['average_meeting_hours'] as num?)?.toDouble() ?? 0.0,
      averageFocusTime: (json['average_focus_time'] as num?)?.toDouble() ?? 0.0,
      averageCommunicationsLoad: json['average_communications_load'] ?? 0,
      description: json['description'] ?? '',
    );
  }
}

class TimezoneFactor {
  final int penalty;
  final String description;

  TimezoneFactor({required this.penalty, required this.description});

  factory TimezoneFactor.fromJson(Map<String, dynamic> json) {
    return TimezoneFactor(
      penalty: json['penalty'] ?? 0,
      description: json['description'] ?? '',
    );
  }
}

class CompanySizeFactor {
  final int adjustment;
  final String description;

  CompanySizeFactor({required this.adjustment, required this.description});

  factory CompanySizeFactor.fromJson(Map<String, dynamic> json) {
    return CompanySizeFactor(
      adjustment: json['adjustment'] ?? 0,
      description: json['description'] ?? '',
    );
  }
}

class SleepRange {
  final List<int> hours;
  final int adjustment;
  final String description;

  const SleepRange({required this.hours, required this.adjustment, required this.description});
}

class SleepImpactFactor {
  final SleepRange optimal;
  final SleepRange adequate;
  final SleepRange suboptimal;
  final SleepRange critical;
  final SleepRange oversleep;

  const SleepImpactFactor({required this.optimal, required this.adequate, required this.suboptimal, required this.critical, required this.oversleep});
}

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
}

// Score calculation
int calculateMarginScore(double sleep, double energy, double meetingLoad, MarginContext context) {
  // Sleep contribution: 0-35 points based on quality
  final sleepQuality = context.getSleepImpact(sleep);
  double sleepScore;
  if (sleepQuality >= 4) {
    sleepScore = 35; // Optimal
  } else if (sleepQuality >= 2) {
    sleepScore = 25; // Adequate
  } else if (sleepQuality >= -2) {
    sleepScore = 15; // Suboptimal
  } else {
    sleepScore = 5; // Critical
  }

  // Energy contribution: 5-40 points (1-10 scale)
  final energyScore = (energy * 3.5) + 5;

  // Meeting load penalty: 0 to -25 points
  double meetingPenalty;
  if (meetingLoad <= 2) {
    meetingPenalty = meetingLoad * 1.5;
  } else if (meetingLoad <= 6) {
    meetingPenalty = 3 + (meetingLoad - 2) * 3;
  } else {
    meetingPenalty = 15 + (meetingLoad - 6) * 2.5;
  }

  final base = sleepScore + energyScore - meetingPenalty;

  // Contextual adjustments
  final now = DateTime.now();
  final dayFactor = context.getDayFactor(now.weekday);
  final seasonalFactor = context.getSeasonalFactor(now.month);
  final holidayFactor = context.getHolidayFactor(now);
  final timezonePenalty = context.getTimezonePenalty();
  final companySizeAdjustment = context.getCompanySizeAdjustment();
  final stressAdjustments = context.getStressAdjustments();
  final workLifePenalties = context.getWorkLifePenalties();

  final enriched = base +
      dayFactor +
      seasonalFactor +
      holidayFactor +
      timezonePenalty +
      companySizeAdjustment +
      stressAdjustments +
      workLifePenalties;

  return enriched.clamp(0, 100).round();
}

String getCapacityLevel(int score) {
  if (score >= 70) return 'High Capacity';
  if (score >= 40) return 'Moderate Capacity';
  return 'Depleted';
}

String getSleepQualityLabel(double sleep) {
  final roundedHours = sleep.round();
  if (roundedHours >= 7 && roundedHours <= 9) return 'Optimal';
  if (roundedHours == 6 || roundedHours == 10) return 'Adequate';
  if (roundedHours == 5 || roundedHours == 11) return 'Suboptimal';
  if (roundedHours >= 12 && roundedHours <= 15) return 'Oversleep';
  return 'Critical';
}

Future<MarginContext> loadContext() async {
  final file = File('backend-data/static/margin-context.json');
  if (!await file.exists()) {
    throw Exception('Context file not found: backend-data/static/margin-context.json');
  }
  final json = jsonDecode(await file.readAsString());
  return MarginContext.fromJson(json);
}

double? parseDouble(String input) {
  final value = double.tryParse(input);
  if (value == null) {
    print('  ❌ Invalid number. Please try again.');
    return null;
  }
  return value;
}

void printHeader() {
  print('\n' + '=' * 60);
  print('  Margin Score Calculator - Developer Tool');
  print('=' * 60);
}

void printResults(double sleep, double energy, double meetingLoad, int score, MarginContext context) {
  final now = DateTime.now();
  final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][now.weekday - 1];

  print('\n' + '─' * 60);
  print('  RESULTS');
  print('─' * 60);
  print('  📊 Margin Score: ${score}% - ${getCapacityLevel(score)}');
  print('');
  print('  Input Factors:');
  print('    😴 Sleep: ${sleep.toStringAsFixed(1)}h (${getSleepQualityLabel(sleep)})');
  print('    ⚡ Energy: ${energy.toStringAsFixed(1)}/10');
  print('    📅 Meetings: ${meetingLoad.toStringAsFixed(1)}h');
  print('');
  print('  Contextual Factors:');
  print('    📆 Day: $weekday (${context.getDayFactor(now.weekday) > 0 ? '+' : ''}${context.getDayFactor(now.weekday)})');
  print('    🌍 Season: Q${((now.month - 1) ~/ 3) + 1} (${context.getSeasonalFactor(now.month) > 0 ? '+' : ''}${context.getSeasonalFactor(now.month)})');
  final holiday = context.holidays.firstWhere(
    (h) => h.isEffective(now),
    orElse: () => Holiday(date: '', name: 'None', bufferDays: 0, adjustment: 0),
  );
  if (holiday.name != 'None') {
    print('    🎉 Holiday: ${holiday.name} (+${holiday.adjustment})');
  }
  print('─' * 60 + '\n');
}

void main() async {
  printHeader();

  // Load context
  print('  Loading context data...');
  final context = await loadContext();
  print('  ✓ Context loaded\n');

  while (true) {
    print('\n  Enter your values (or "q" to quit):\n');

    // Get sleep input
    double? sleep;
    while (sleep == null) {
      stdout.write('  😴 Sleep hours (0-12): ');
      final input = stdin.readLineSync();
      if (input == null || input.toLowerCase() == 'q') {
        print('\n  👋 Goodbye!\n');
        exit(0);
      }
      sleep = parseDouble(input);
      if (sleep != null && (sleep < 0 || sleep > 12)) {
        print('  ⚠️  Please enter a value between 0 and 12.');
        sleep = null;
      }
    }

    // Get energy input
    double? energy;
    while (energy == null) {
      stdout.write('  ⚡ Energy level (1-10): ');
      final input = stdin.readLineSync();
      if (input == null || input.toLowerCase() == 'q') {
        print('\n  👋 Goodbye!\n');
        exit(0);
      }
      energy = parseDouble(input);
      if (energy != null && (energy < 1 || energy > 10)) {
        print('  ⚠️  Please enter a value between 1 and 10.');
        energy = null;
      }
    }

    // Get meeting load input
    double? meetingLoad;
    while (meetingLoad == null) {
      stdout.write('  📅 Meeting load hours (0-16): ');
      final input = stdin.readLineSync();
      if (input == null || input.toLowerCase() == 'q') {
        print('\n  👋 Goodbye!\n');
        exit(0);
      }
      meetingLoad = parseDouble(input);
      if (meetingLoad != null && (meetingLoad < 0 || meetingLoad > 16)) {
        print('  ⚠️  Please enter a value between 0 and 16.');
        meetingLoad = null;
      }
    }

    // Calculate score
    final score = calculateMarginScore(sleep, energy, meetingLoad, context);

    // Print results
    printResults(sleep, energy, meetingLoad, score, context);

    // Ask to continue
    stdout.write('\n  Calculate another score? (y/n): ');
    final continueInput = stdin.readLineSync();
    if (continueInput == null || continueInput.toLowerCase() != 'y') {
      print('\n  👋 Goodbye!\n');
      break;
    }
  }
}
