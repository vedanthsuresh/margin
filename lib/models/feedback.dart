import 'margin_context.dart';

/// Feedback on a specific dimension/factor that affects the Margin Score
class DimensionFeedback {
  final String dimensionId;
  final String dimensionName;
  final String currentValue;
  final String? suggestedValue;
  final String reason;
  final DateTime timestamp;
  final bool applied; // Whether the adjustment has been applied

  DimensionFeedback({
    required this.dimensionId,
    required this.dimensionName,
    required this.currentValue,
    this.suggestedValue,
    required this.reason,
    required this.timestamp,
    this.applied = false,
  });

  /// Create a feedback instance for a specific dimension type
  factory DimensionFeedback.forDayFactor(DayFactor currentFactor, String reason) {
    return DimensionFeedback(
      dimensionId: 'day_factor',
      dimensionName: 'Day Factor',
      currentValue: '${currentFactor.adjustment}',
      reason: reason,
      timestamp: DateTime.now(),
    );
  }

  factory DimensionFeedback.forSeasonalFactor(SeasonalFactor currentFactor, String reason) {
    return DimensionFeedback(
      dimensionId: 'seasonal_factor',
      dimensionName: 'Seasonal Factor',
      currentValue: '${currentFactor.adjustment}',
      reason: reason,
      timestamp: DateTime.now(),
    );
  }

  factory DimensionFeedback.forTimezoneFactor(TimezoneFactor currentFactor, String reason) {
    return DimensionFeedback(
      dimensionId: 'timezone_factor',
      dimensionName: 'Timezone Factor',
      currentValue: '${currentFactor.penalty}',
      reason: reason,
      timestamp: DateTime.now(),
    );
  }

  factory DimensionFeedback.forCompanySize(CompanySizeFactor currentFactor, String reason) {
    return DimensionFeedback(
      dimensionId: 'company_size',
      dimensionName: 'Company Size Factor',
      currentValue: '${currentFactor.adjustment}',
      reason: reason,
      timestamp: DateTime.now(),
    );
  }

  factory DimensionFeedback.forSleepImpact(int hours, int currentAdjustment, String reason) {
    return DimensionFeedback(
      dimensionId: 'sleep_impact',
      dimensionName: 'Sleep Impact',
      currentValue: '$currentAdjustment',
      reason: reason,
      timestamp: DateTime.now(),
    );
  }

  /// Apply the feedback to get the adjusted value
  DimensionFeedback apply() {
    // For now, return a copy with applied = true
    // In the future, this would call an AI to determine the adjustment
    return DimensionFeedback(
      dimensionId: dimensionId,
      dimensionName: dimensionName,
      currentValue: currentValue,
      suggestedValue: suggestedValue,
      reason: reason,
      timestamp: timestamp,
      applied: true,
    );
  }

  /// Get the numeric adjustment value (for static implementation)
  double get adjustmentValue {
    // This is a simplified static adjustment
    // In the future, AI would determine this intelligently
    if (applied) {
      switch (dimensionId) {
        case 'day_factor':
        case 'seasonal_factor':
        case 'company_size':
          // User feedback increases the factor by 1 (less penalty or more bonus)
          final current = double.tryParse(currentValue) ?? 0.0;
          return current + 1;
        case 'timezone_factor':
          final current = double.tryParse(currentValue) ?? 0.0;
          return current + 1; // Reduce penalty
        default:
          return 0.0;
      }
    }
    return 0.0;
  }

  DimensionFeedback copyWith({
    String? dimensionId,
    String? dimensionName,
    String? currentValue,
    String? suggestedValue,
    String? reason,
    DateTime? timestamp,
    bool? applied,
  }) {
    return DimensionFeedback(
      dimensionId: dimensionId ?? this.dimensionId,
      dimensionName: dimensionName ?? this.dimensionName,
      currentValue: currentValue ?? this.currentValue,
      suggestedValue: suggestedValue ?? this.suggestedValue,
      reason: reason ?? this.reason,
      timestamp: timestamp ?? this.timestamp,
      applied: applied ?? this.applied,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dimensionId': dimensionId,
      'dimensionName': dimensionName,
      'currentValue': currentValue,
      'suggestedValue': suggestedValue,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
      'applied': applied,
    };
  }

  factory DimensionFeedback.fromJson(Map<String, dynamic> json) {
    return DimensionFeedback(
      dimensionId: json['dimensionId'] ?? '',
      dimensionName: json['dimensionName'] ?? '',
      currentValue: json['currentValue'] ?? '',
      suggestedValue: json['suggestedValue'],
      reason: json['reason'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      applied: json['applied'] ?? false,
    );
  }
}
