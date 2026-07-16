import '../models/feedback.dart';

/// Service for handling user feedback on dimension adjustments
class FeedbackService {
  final List<DimensionFeedback> _feedbackHistory = [];

  /// Submit feedback for a dimension
  DimensionFeedback submitFeedback(DimensionFeedback feedback) {
    final applied = feedback.apply();
    _feedbackHistory.add(applied);
    return applied;
  }

  /// Get all feedback history
  List<DimensionFeedback> getFeedbackHistory() {
    return List.unmodifiable(_feedbackHistory);
  }

  /// Get feedback for a specific dimension
  List<DimensionFeedback> getFeedbackForDimension(String dimensionId) {
    return _feedbackHistory
        .where((f) => f.dimensionId == dimensionId)
        .toList();
  }

  /// Clear feedback history
  void clearHistory() {
    _feedbackHistory.clear();
  }

  /// Get the most recent applied adjustment for a dimension
  double? getLatestAdjustment(String dimensionId) {
    final feedback = _feedbackHistory
        .where((f) => f.dimensionId == dimensionId && f.applied)
        .lastOrNull;
    return feedback?.adjustmentValue;
  }
}
