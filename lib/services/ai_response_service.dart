import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/boundary_responses.dart';
import '../models/margin_score.dart';

/// Service for generating AI-powered boundary responses using Google Gemini
///
/// DEMO/HACKATHON NOTE: This service uses client-side API keys for demo purposes.
/// For production, move AI calls to a backend server to secure API keys.
class AIResponseService {
  final String apiKey;
  late final GenerativeModel _model;

  /// Last generated responses for debugging/retry
  BoundaryResponses? _lastResponses;

  /// Whether the service is initialized and ready
  bool get isInitialized => apiKey.isNotEmpty;

  AIResponseService({required this.apiKey}) {
    if (apiKey.isEmpty) {
      debugPrint('AIResponseService: No API key provided. Using mock responses.');
      return;
    }

    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
      );
      debugPrint('AIResponseService: Initialized with Gemini 1.5 Flash');
    } catch (e) {
      debugPrint('AIResponseService: Failed to initialize: $e');
    }
  }

  /// Generate boundary responses based on user context
  ///
  /// Parameters:
  /// - incomingText: The demanding request text the user received
  /// - relationship: Relationship to sender (boss, peer, friend, family)
  /// - marginScore: Current margin score (0-100)
  /// - capacityLevel: Current capacity level (high, moderate, depleted)
  Future<BoundaryResponses> generateResponses({
    required String incomingText,
    required String relationship,
    required int marginScore,
    required CapacityLevel capacityLevel,
  }) async {
    // Use mock responses if no API key or in debug mode
    if (!isInitialized) {
      return _getMockResponses(incomingText, relationship, capacityLevel);
    }

    try {
      final prompt = _buildPrompt(
        incomingText,
        relationship,
        marginScore,
        capacityLevel,
      );

      debugPrint('AIResponseService: Sending prompt to Gemini...');

      final response = await _model.generateContent(
        [Content.text(prompt)],
      );

      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        debugPrint('AIResponseService: Empty response from Gemini');
        return _getMockResponses(incomingText, relationship, capacityLevel);
      }

      // Extract JSON from response (handle markdown code blocks)
      final jsonText = _extractJson(responseText);

      try {
        final jsonData = jsonDecode(jsonText) as Map<String, dynamic>;
        final responses = BoundaryResponses.fromJson(jsonData);
        _lastResponses = responses;
        return responses;
      } catch (e) {
        debugPrint('AIResponseService: Failed to parse JSON: $e');
        debugPrint('AIResponseService: Raw response: $responseText');
        return _getMockResponses(incomingText, relationship, capacityLevel);
      }
    } catch (e) {
      debugPrint('AIResponseService: Generation failed: $e');
      return _getMockResponses(incomingText, relationship, capacityLevel);
    }
  }

  /// Build the prompt for Gemini
  String _buildPrompt(
    String incomingText,
    String relationship,
    int marginScore,
    CapacityLevel capacityLevel,
  ) {
    final capacityDescription = _getCapacityDescription(capacityLevel);
    final responseGuidance = _getResponseGuidance(capacityLevel);

    return '''You are Margin, a proactive psychological bodyguard that helps users set healthy boundaries while maintaining relationships.

CONTEXT:
- User's current Margin Score: $marginScore/100
- Capacity Level: $capacityDescription
- Relationship to sender: $relationship
- Incoming request: "$incomingText"

RESPONSE STRATEGY:
$responseGuidance

Generate 4 distinct response options. Each should be:
- Professional yet authentic
- Clear and direct (no fluff)
- Appropriate for the relationship type
- Reflective of the user's current capacity

Return ONLY valid JSON in this exact format:
{
  "politeDecline": "Full response text here",
  "softCompromise": "Full response text here",
  "reschedule": "Full response text here",
  "acceptRequest": "Full response text here"
}''';
  }

  /// Get human-readable capacity description
  String _getCapacityDescription(CapacityLevel level) {
    switch (level) {
      case CapacityLevel.high:
        return 'HIGH (70-100) - User has bandwidth, is well-rested, and can take on requests';
      case CapacityLevel.moderate:
        return 'MODERATE (40-69) - User has limited bandwidth, should be selective about commitments';
      case CapacityLevel.depleted:
        return 'DEPLETED (0-39) - User is at burnout risk, should protect remaining capacity fiercely';
    }
  }

  /// Get response guidance based on capacity level
  String _getResponseGuidance(CapacityLevel level) {
    switch (level) {
      case CapacityLevel.high:
        return '''
- Polite Decline: Warm and understanding, leaves door open for future
- Soft Compromise: Can offer partial effort or modified timeline
- Reschedule: Suggests specific alternative times when available
- Accept Request: Enthusiastic acceptance with clear next steps''';

      case CapacityLevel.moderate:
        return '''
- Polite Decline: Professional but firm, may offer alternative timing
- Soft Compromise: Offers minimal involvement or resources only
- Reschedule: Cautious about timing, may suggest later in the week
- Accept Request: Accepts with caveats about timeline or scope''';

      case CapacityLevel.depleted:
        return '''
- Polite Decline: Firm boundary, no apologizing, clear closure
- Soft Compromise: Passive resources only (templates, docs, existing work)
- Reschedule: Refuses to suggest times if week is packed
- Accept Request: ADD A CLEAR WARNING about burnout risk at the start''';
    }
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

  /// Get mock responses for testing/demo when API is unavailable
  BoundaryResponses _getMockResponses(
    String incomingText,
    String relationship,
    CapacityLevel capacityLevel,
  ) {
    final isDepleted = capacityLevel == CapacityLevel.depleted;

    return BoundaryResponses(
      politeDecline: isDepleted
          ? 'I need to decline this request. My current bandwidth won\'t allow me to give this the attention it deserves.'
          : 'Thanks for thinking of me! I won\'t be able to take this on right now, but please keep me in mind for future opportunities.',
      softCompromise: isDepleted
          ? 'I can\'t take this on directly, but I have some templates/resources from a similar project that might help. Would you like me to share those?'
          : 'I can\'t commit to the full scope, but I could help with [specific component] or review the approach when you\'re ready.',
      reschedule: isDepleted
          ? 'My schedule is fully packed this week. I won\'t be able to suggest alternative times that would work for this timeline.'
          : 'This week isn\'t ideal for me. Would next week work? I have availability on Tuesday afternoon or Thursday morning.',
      acceptRequest: isDepleted
          ? '⚠️ BURNOUT RISK: Your capacity is at ${capacityLevel.label}. Accepting this may impact your wellbeing.\n\nIf you must proceed, consider: "I can take this on, but I\'ll need to deprioritize [other commitment] to do so."'
          : 'Happy to help! I\'ll get started on this right away and aim to have something to you by [reasonable deadline based on scope].',
    );
  }

  /// Get the last generated responses (for debugging)
  BoundaryResponses? get lastResponses => _lastResponses;
}
