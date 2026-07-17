/// AI Feedback Analysis Service
///
/// This service analyzes user feedback on dimension calculations
/// and intelligently determines appropriate adjustments.
///
/// Uses Firebase AI (Gemini) for sophisticated analysis,
/// with local rule-based fallback for when AI is unavailable.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/feedback.dart';
import '../models/margin_context.dart';

/// Result of AI feedback analysis
class FeedbackAnalysisResult {
  final double adjustmentAmount;
  final String reasoning;
  final bool isConfident;
  final String? suggestedValue;
  final bool shouldRecalculate;

  const FeedbackAnalysisResult({
    required this.adjustmentAmount,
    required this.reasoning,
    this.isConfident = true,
    this.suggestedValue,
    this.shouldRecalculate = true,
  });

  factory FeedbackAnalysisResult.fromJson(Map<String, dynamic> json) {
    return FeedbackAnalysisResult(
      adjustmentAmount: (json['adjustmentAmount'] as num?)?.toDouble() ?? 0.0,
      reasoning: json['reasoning'] ?? '',
      isConfident: json['isConfident'] ?? true,
      suggestedValue: json['suggestedValue'],
      shouldRecalculate: json['shouldRecalculate'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adjustmentAmount': adjustmentAmount,
      'reasoning': reasoning,
      'isConfident': isConfident,
      'suggestedValue': suggestedValue,
      'shouldRecalculate': shouldRecalculate,
    };
  }

  /// Apply this analysis to a dimension feedback
  DimensionFeedback applyToFeedback(DimensionFeedback original) {
    return DimensionFeedback(
      dimensionId: original.dimensionId,
      dimensionName: original.dimensionName,
      currentValue: original.currentValue,
      suggestedValue: suggestedValue,
      reason: '$original.reason\n\nAI Adjustment: $reasoning',
      timestamp: original.timestamp,
      applied: true,
    );
  }

  /// Get the new value for the dimension
  String getNewValue(String currentValue) {
    if (suggestedValue != null) return suggestedValue!;

    final numValue = double.tryParse(currentValue);
    if (numValue != null) {
      final newValue = numValue + adjustmentAmount;
      return newValue.toStringAsFixed(1);
    }
    return currentValue;
  }
}

/// AI Feedback Analysis Service
class AIFeedbackAnalysisService {
  /// Firebase AI generative model for feedback analysis
  final model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.5-flash',
  );

  AIFeedbackAnalysisService();

  /// Analyze feedback and determine appropriate adjustment
  Future<FeedbackAnalysisResult> analyzeFeedback(
    DimensionFeedback feedback,
    MarginContext context,
  ) async {
    // Debug output
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🧠 AI FEEDBACK ANALYSIS');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('Dimension: ${feedback.dimensionName} (${feedback.dimensionId})');
    debugPrint('Current Value: ${feedback.currentValue}');
    debugPrint('User Reason: "${feedback.reason}"');
    debugPrint('────────────────────────────────────────────────────');

    // Try AI analysis first, fallback to local on error
    try {
      final result = await _analyzeViaAI(feedback, context);
      _printAnalysisResult(result, 'Firebase AI');
      return result;
    } catch (e) {
      debugPrint('⚠️ AI analysis failed, using local analysis: $e');
      // Fallback to local analysis on error
      final result = _analyzeLocally(feedback, context);
      _printAnalysisResult(result, 'Local (fallback)');
      return result;
    }
  }

  void _printAnalysisResult(FeedbackAnalysisResult result, String method) {
    debugPrint('📊 ANALYSIS RESULT ($method):');
    debugPrint('   Adjustment: ${result.adjustmentAmount > 0 ? "+" : ""}${result.adjustmentAmount}');
    debugPrint('   New Value: ${result.suggestedValue ?? "auto-calculated"}');
    debugPrint('   Reasoning: ${result.reasoning}');
    debugPrint('   Confidence: ${result.isConfident ? "HIGH" : "LOW"}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// AI-based analysis via Firebase AI (Gemini)
  Future<FeedbackAnalysisResult> _analyzeViaAI(
    DimensionFeedback feedback,
    MarginContext context,
  ) async {
    final prompt = _buildPrompt(feedback, context);
    debugPrint('📤 Sending prompt to Firebase AI...');

    final response = await model.generateContent([
      Content.text(prompt),
    ]);

    final responseText = response.text;
    if (responseText == null || responseText.isEmpty) {
      debugPrint('AIResponseService: Empty response from Gemini');
      throw Exception('Empty response from AI');
    }

    debugPrint('📥 AI response received');
    final jsonText = _extractJson(responseText);

    try {
      final jsonData = jsonDecode(jsonText) as Map<String, dynamic>;
      return FeedbackAnalysisResult.fromJson(jsonData);
    } catch (e) {
      debugPrint('AIResponseService: JSON parsing error: $e');
      debugPrint('AIResponseService: Raw response: $responseText');
      rethrow;
    }
  }

  /// Build prompt for AI feedback analysis
  String _buildPrompt(DimensionFeedback feedback, MarginContext context) {
    return '''You are an intelligent assistant that analyzes user feedback on dimension calculations for a psychological bandwidth app called "Margin".

The user has provided feedback on a dimension that affects their margin score calculation.

## Dimension Details
- ID: ${feedback.dimensionId}
- Name: ${feedback.dimensionName}
- Current Value: ${feedback.currentValue}
- User's Reason: "${feedback.reason}"

## Context
The margin score calculates a user's emotional and mental capacity (0-100%) based on various factors like sleep, meeting load, energy, day of week, seasonal factors, etc.

## Your Task
Analyze the user's feedback and determine the appropriate adjustment. Return a JSON object with:
- adjustmentAmount: Numeric value to add to current value (can be negative to reduce, positive to increase)
- reasoning: Clear explanation of why this adjustment makes sense
- isConfident: true if you're confident in this adjustment, false otherwise
- suggestedValue: (optional) The specific new value to set (as a string number)
- shouldRecalculate: Whether this change should trigger a full score recalculation

## Guidelines
1. If the user says a factor "doesn't apply" or "isn't relevant", set adjustmentAmount to remove it (e.g., -current value for negative factors)
2. If the user reports having MORE capacity than calculated, adjust to reduce penalties or increase bonuses
3. If the user reports having LESS capacity than calculated, adjust to increase penalties or reduce bonuses
4. Be conservative with adjustments (typically -3 to +3 range)
5. Provide clear reasoning that connects the user's feedback to the adjustment

## Response Format (strict JSON only, no markdown):
```json
{
  "adjustmentAmount": -2.0,
  "reasoning": "User indicated this factor does not apply to them. Removing the penalty.",
  "isConfident": true,
  "suggestedValue": "0",
  "shouldRecalculate": true
}
```

Now analyze this feedback and return only the JSON:''';
  }

  /// Extract JSON from markdown code block if present
  String _extractJson(String text) {
    // Check for JSON in markdown code blocks
    final codeBlockPattern = RegExp(r'```json\s*([\s\S]*?)\s*```');
    final match = codeBlockPattern.firstMatch(text);

    if (match != null && match.groupCount >= 1) {
      return match.group(1)!.trim();
    }

    // If no code block, try to find JSON object
    final objectPattern = RegExp(r'\{[\s\S]*\}');
    final objectMatch = objectPattern.firstMatch(text);

    if (objectMatch != null) {
      return objectMatch.group(0)!.trim();
    }

    return text.trim();
  }

  /// Local rule-based analysis (intelligent fallback)
  FeedbackAnalysisResult _analyzeLocally(
    DimensionFeedback feedback,
    MarginContext context,
  ) {
    final reason = feedback.reason.toLowerCase();
    final currentNum = double.tryParse(feedback.currentValue);

    // Analyze based on dimension type and user's reason
    switch (feedback.dimensionId) {
      case 'day_factor':
      case 'seasonal_factor':
      case 'holiday_factor':
        return _analyzeTemporalFactor(feedback, context);

      case 'company_size':
        return _analyzeCompanySizeFactor(feedback, context);

      case 'timezone_factor':
        return _analyzeTimezoneFactor(feedback, context);

      case 'meeting_load':
        return _analyzeMeetingLoad(feedback, context);

      case 'sleep_impact':
        return _analyzeSleepImpact(feedback, context);

      default:
        return _analyzeGeneric(feedback, currentNum ?? 0.0, reason);
    }
  }

  /// Analyze temporal factors (day, seasonal, holiday)
  FeedbackAnalysisResult _analyzeTemporalFactor(
    DimensionFeedback feedback,
    MarginContext context,
  ) {
    final reason = feedback.reason.toLowerCase();
    final currentNum = double.tryParse(feedback.currentValue) ?? 0.0;

    // User says factor doesn't apply
    if (reason.contains('doesn\'t apply') ||
        reason.contains('not relevant') ||
        reason.contains('doesn\'t affect')) {
      return FeedbackAnalysisResult(
        adjustmentAmount: -currentNum, // Remove the factor entirely
        reasoning: 'User indicated this factor does not apply to them. Factor removed.',
        isConfident: true,
        suggestedValue: '0',
      );
    }

    // User has more capacity
    if (reason.contains('more capacity') ||
        reason.contains('feeling better') ||
        reason.contains('actually good')) {
      final adjustment = currentNum >= 0 ? 2.0 : -2.0; // Increase bonus or reduce penalty
      return FeedbackAnalysisResult(
        adjustmentAmount: adjustment,
        reasoning: 'User reports having more capacity than calculated. Increasing buffer.',
        isConfident: true,
        suggestedValue: (currentNum + adjustment).toStringAsFixed(1),
      );
    }

    // User has less capacity
    if (reason.contains('less capacity') ||
        reason.contains('more tired') ||
        reason.contains('worse than this')) {
      final adjustment = currentNum <= 0 ? -2.0 : 2.0; // Decrease bonus or increase penalty
      return FeedbackAnalysisResult(
        adjustmentAmount: adjustment,
        reasoning: 'User reports having less capacity than calculated. Increasing penalty.',
        isConfident: true,
        suggestedValue: (currentNum + adjustment).toStringAsFixed(1),
      );
    }

    // Generic adjustment
    return FeedbackAnalysisResult(
      adjustmentAmount: 1.0,
      reasoning: 'Adjusting factor based on user feedback.',
      isConfident: false,
    );
  }

  /// Analyze company size factor
  FeedbackAnalysisResult _analyzeCompanySizeFactor(
    DimensionFeedback feedback,
    MarginContext context,
  ) {
    final reason = feedback.reason.toLowerCase();
    final currentNum = double.tryParse(feedback.currentValue) ?? 0.0;

    // If user provides specific company info
    if (reason.contains('startup') || reason.contains('small company')) {
      return FeedbackAnalysisResult(
        adjustmentAmount: -3.0 - currentNum,
        reasoning: 'User confirmed startup/small company environment. Applying startup adjustment.',
        isConfident: true,
        suggestedValue: '-3',
      );
    }

    if (reason.contains('enterprise') || reason.contains('large company') ||
        reason.contains('fortune') || reason.contains('big company')) {
      return FeedbackAnalysisResult(
        adjustmentAmount: -2.0 - currentNum,
        reasoning: 'User confirmed enterprise/large company. Applying enterprise adjustment.',
        isConfident: true,
        suggestedValue: '-2',
      );
    }

    if (reason.contains('doesn\'t affect') || reason.contains('not relevant')) {
      return FeedbackAnalysisResult(
        adjustmentAmount: -currentNum,
        reasoning: 'User indicated company size does not affect their capacity.',
        isConfident: true,
        suggestedValue: '0',
      );
    }

    // Default adjustment
    return FeedbackAnalysisResult(
      adjustmentAmount: 1.0,
      reasoning: 'Adjusting company size factor based on feedback.',
      isConfident: false,
    );
  }

  /// Analyze timezone factor
  FeedbackAnalysisResult _analyzeTimezoneFactor(
    DimensionFeedback feedback,
    MarginContext context,
  ) {
    final reason = feedback.reason.toLowerCase();
    final currentNum = double.tryParse(feedback.currentValue) ?? 0.0;

    // User says timezone isn't an issue
    if (reason.contains('not an issue') ||
        reason.contains('doesn\'t affect') ||
        reason.contains('used to it') ||
        reason.contains('fine with')) {
      return FeedbackAnalysisResult(
        adjustmentAmount: -currentNum, // Remove penalty
        reasoning: 'User reports timezone span does not negatively impact them. Penalty removed.',
        isConfident: true,
        suggestedValue: '0',
      );
    }

    // User says it's harder than calculated
    if (reason.contains('harder') ||
        reason.contains('worse') ||
        reason.contains('more difficult') ||
        reason.contains('exhausting')) {
      return FeedbackAnalysisResult(
        adjustmentAmount: -2.0,
        reasoning: 'User reports timezone challenges are more severe than calculated. Increasing penalty.',
        isConfident: true,
        suggestedValue: (currentNum - 2.0).toStringAsFixed(1),
      );
    }

    // Default adjustment
    return FeedbackAnalysisResult(
      adjustmentAmount: 1.0,
      reasoning: 'Adjusting timezone factor based on feedback.',
      isConfident: false,
    );
  }

  /// Analyze meeting load
  FeedbackAnalysisResult _analyzeMeetingLoad(
    DimensionFeedback feedback,
    MarginContext context,
  ) {
    final reason = feedback.reason.toLowerCase();

    // User says meetings are less impactful
    if (reason.contains('not that bad') ||
        reason.contains('manageable') ||
        reason.contains('used to it') ||
        reason.contains('less impact')) {
      return FeedbackAnalysisResult(
        adjustmentAmount: -1.0,
        reasoning: 'User reports meeting load is more manageable than calculated. Reducing impact.',
        isConfident: true,
      );
    }

    // User says meetings are more draining
    if (reason.contains('more draining') ||
        reason.contains('exhausting') ||
        reason.contains('too many') ||
        reason.contains('worse')) {
      return FeedbackAnalysisResult(
        adjustmentAmount: -2.0,
        reasoning: 'User reports meeting load is more draining than calculated. Increasing impact.',
        isConfident: true,
      );
    }

    // Default adjustment
    return FeedbackAnalysisResult(
      adjustmentAmount: -1.0,
      reasoning: 'Adjusting meeting load factor based on feedback.',
      isConfident: false,
    );
  }

  /// Analyze sleep impact
  FeedbackAnalysisResult _analyzeSleepImpact(
    DimensionFeedback feedback,
    MarginContext context,
  ) {
    final reason = feedback.reason.toLowerCase();

    // User handles poor sleep better than average
    if (reason.contains('function fine') ||
        reason.contains('used to it') ||
        reason.contains('doesn\'t affect me') ||
        reason.contains('resilient')) {
      return FeedbackAnalysisResult(
        adjustmentAmount: 3.0,
        reasoning: 'User reports higher resilience to sleep quality. Reducing penalty.',
        isConfident: true,
      );
    }

    // User is more affected by poor sleep
    if (reason.contains('more affected') ||
        reason.contains('really need sleep') ||
        reason.contains('worse when') ||
        reason.contains('very sensitive')) {
      return FeedbackAnalysisResult(
        adjustmentAmount: -3.0,
        reasoning: 'User reports higher sensitivity to sleep quality. Increasing penalty.',
        isConfident: true,
      );
    }

    // Default adjustment
    return FeedbackAnalysisResult(
      adjustmentAmount: 1.0,
      reasoning: 'Adjusting sleep impact factor based on feedback.',
      isConfident: false,
    );
  }

  /// Generic analysis for unknown dimension types
  FeedbackAnalysisResult _analyzeGeneric(
    DimensionFeedback feedback,
    double currentValue,
    String reason,
  ) {
    // Determine direction from sentiment
    final isPositive = reason.contains('better') ||
        reason.contains('more') ||
        reason.contains('good') ||
        reason.contains('fine');

    final isNegative = reason.contains('worse') ||
        reason.contains('less') ||
        reason.contains('bad') ||
        reason.contains('harder');

    double adjustment;
    String reasoning;

    if (isNegative) {
      adjustment = -1.5;
      reasoning = 'User reports negative impact. Adjusting accordingly.';
    } else if (isPositive) {
      adjustment = 1.5;
      reasoning = 'User reports positive capacity. Adjusting accordingly.';
    } else {
      adjustment = 1.0;
      reasoning = 'Adjusting based on user feedback.';
    }

    return FeedbackAnalysisResult(
      adjustmentAmount: adjustment,
      reasoning: reasoning,
      isConfident: false,
    );
  }
}
