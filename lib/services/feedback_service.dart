import 'package:flutter/foundation.dart';
import '../models/feedback.dart';
import '../models/margin_context.dart';
import 'ai_feedback_analysis_service.dart';

/// Service for handling user feedback on dimension adjustments
class FeedbackService {
  final List<DimensionFeedback> _feedbackHistory = [];
  final AIFeedbackAnalysisService? _aiAnalysisService;

  FeedbackService({AIFeedbackAnalysisService? aiAnalysisService})
      : _aiAnalysisService = aiAnalysisService;

  /// Submit feedback for a dimension
  ///
  /// If AI analysis service is provided, uses intelligent analysis.
  /// Otherwise applies the feedback directly.
  Future<DimensionFeedback> submitFeedback(
    DimensionFeedback feedback, {
    MarginContext? context,
  }) async {
    debugPrint('🔧 FeedbackService.submitFeedback');
    debugPrint('   Has AI service: ${_aiAnalysisService != null}');
    debugPrint('   Has context: ${context != null}');

    DimensionFeedback applied;

    if (_aiAnalysisService != null && context != null) {
      // Use AI analysis
      debugPrint('🤖 Using AI analysis...');
      final analysis = await _aiAnalysisService.analyzeFeedback(feedback, context);
      debugPrint('   ✅ AI analysis complete');
      debugPrint('   📊 Suggested adjustment: ${analysis.adjustmentAmount}');
      debugPrint('   💬 AI reasoning: ${analysis.reasoning}');
      if (analysis.suggestedValue != null) {
        debugPrint('   🎯 Suggested value: ${analysis.suggestedValue}');
      }
      applied = analysis.applyToFeedback(feedback);
      debugPrint('   ✅ Applied to feedback');
    } else {
      // Apply directly without AI analysis
      debugPrint('⚡ Using direct application (no AI)');
      applied = feedback.apply();
    }

    _feedbackHistory.add(applied);
    debugPrint('💾 Feedback saved to history');
    return applied;
  }

  /// Submit feedback synchronously (for backward compatibility)
  DimensionFeedback submitFeedbackSync(DimensionFeedback feedback) {
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
