import 'margin_context.dart';

/// Margin Score - represents user's real-time emotional and mental capacity (0-100)
class MarginScore {
  final double baseScore;
  final double enrichedScore;
  final int finalScore;
  final CapacityLevel capacityLevel;
  final DateTime calculatedAt;

  MarginScore({
    required this.baseScore,
    required this.enrichedScore,
    required this.finalScore,
    required this.capacityLevel,
    required this.calculatedAt,
  });

  factory MarginScore.calculate({
    required double sleep,
    required double energy,
    required double meetingLoad,
    required MarginContext context,
  }) {
    // Step 1: Calculate base score with balanced weights

    // Sleep contribution: 0-35 points based on quality
    // Optimal (7-9h) = 35, Adequate (6h,10h) = 25, Suboptimal (5h,11h) = 15, Critical = 5
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

    // Energy contribution: 0-50 points (1-10 scale)
    // Updated to allow reaching 100% with optimal inputs
    final energyScore = energy * 5;

    // Meeting load penalty: 0 to -25 points (0-16h scale)
    // Low penalty for first 2 hours, then scales up
    double meetingPenalty;
    if (meetingLoad <= 2) {
      meetingPenalty = meetingLoad * 1.5; // 0-3 points
    } else if (meetingLoad <= 6) {
      meetingPenalty = 3 + (meetingLoad - 2) * 3; // 3-15 points
    } else {
      meetingPenalty = 15 + (meetingLoad - 6) * 2.5; // 15-25 points max
    }

    // Base score ranges from ~5 to ~85 points before contextual adjustments
    final base = sleepScore + energyScore - meetingPenalty;

    // Step 2: Apply contextual adjustments
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

    // Clamp to 0-100
    final clamped = enriched.clamp(0, 100).round();

    return MarginScore(
      baseScore: base,
      enrichedScore: enriched,
      finalScore: clamped,
      capacityLevel: CapacityLevel.fromScore(clamped),
      calculatedAt: now,
    );
  }

  /// Get the display color for the current capacity level
  String get colorHex {
    switch (capacityLevel) {
      case CapacityLevel.high:
        return '#4CAF50'; // Green
      case CapacityLevel.moderate:
        return '#FFC107'; // Yellow/Amber
      case CapacityLevel.depleted:
        return '#FF5722'; // Orange/Red
    }
  }

  /// Get the color name for display
  String get colorName {
    switch (capacityLevel) {
      case CapacityLevel.high:
        return 'green';
      case CapacityLevel.moderate:
        return 'yellow';
      case CapacityLevel.depleted:
        return 'orange';
    }
  }
}

/// Capacity level based on score
enum CapacityLevel {
  high(70, 100, 'High Capacity'),
  moderate(40, 69, 'Moderate Capacity'),
  depleted(0, 39, 'Depleted');

  const CapacityLevel(this.minScore, this.maxScore, this.label);

  final int minScore;
  final int maxScore;
  final String label;

  static CapacityLevel fromScore(int score) {
    if (score >= 70) return CapacityLevel.high;
    if (score >= 40) return CapacityLevel.moderate;
    return CapacityLevel.depleted;
  }

  static String getLabel(CapacityLevel level) => level.label;
}
