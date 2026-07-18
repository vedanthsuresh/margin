import 'dart:convert';
import 'package:flutter/foundation.dart';
// ignore: implementation_imports
import '../models/boundary_responses.dart';
import '../models/margin_score.dart';

import 'package:firebase_ai/firebase_ai.dart';

/// Service for generating AI-powered boundary responses using Google Gemini
///
/// DEMO/HACKATHON NOTE: This service uses client-side API keys for demo purposes.
/// For production, move AI calls to a backend server to secure API keys.
class AIResponseService {
  /// Set to true to use mock responses instead of calling AI API (for testing)
  static const bool useMock = true;

  final model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.5-flash',
  );

  /// Last generated responses for debugging/retry
  BoundaryResponses? _lastResponses;

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
    // Use mock responses if in mock mode (for testing)
    if (useMock) {
      debugPrint('AIResponseService: Using mock responses (useMock=true)');
      return _getMockResponses(incomingText, relationship, capacityLevel);
    }

    try {
      // Add a random variety hint to encourage different responses each time
      final varietyHint = _getVarietyHint();

      final prompt = _buildPrompt(
        incomingText,
        relationship,
        marginScore,
        capacityLevel,
        varietyHint,
      );

      debugPrint('AIResponseService: Sending prompt to Gemini...');

      // Using google_gemini_ai package API
      // To generate text output, call generateContent with the text input

      final response = await model.generateContent([Content.text(prompt)]);
      debugPrint('AIResponseService: Response received: ${response.text}');

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
        debugPrint("success! Generated AI responses");
        return responses;
      } catch (e) {
        debugPrint("failure! JSON parsing error: $e");
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
    String varietyHint,
  ) {
    final capacityDescription = _getCapacityDescription(capacityLevel);
    final responseGuidance = _getResponseGuidance(capacityLevel);
    final relationshipContext = _getRelationshipContext(relationship);

    return '''You are Margin, a proactive psychological bodyguard that helps users set healthy boundaries while maintaining relationships.

USER CONTEXT:
- Current Margin Score: $marginScore/100
- Capacity Level: $capacityDescription
- Relationship to sender: $relationship ($relationshipContext)

INCOMING REQUEST:
"$incomingText"

VARIETY GUIDANCE: $varietyHint

CRITICAL REQUIREMENTS:
1. EVERY response must directly reference the specific request above - use concrete details from what they said
2. VARY YOUR RESPONSES - Do NOT use the same phrases repeatedly. Each generation should feel fresh and different from previous ones.
3. Use natural, conversational language - avoid template filler and generic phrases
4. Match the tone to the relationship (formal for boss, casual for friend/family, professional for peer)
5. Responses should feel like they were written by a real person in this specific moment

RESPONSE STRATEGY:
$responseGuidance

IMPORTANT: Generate UNIQUE responses each time. Vary your:
- Opening phrases (instead of always starting with "Thanks for..." or "I'd like to...")
- Sentence structure and length
- Specific wording and vocabulary
- Level of formality within the appropriate range for the relationship

Generate 4 distinct, authentic response options. Each must:
- Acknowledge the specific request using varied language
- Include relevant details from the request where appropriate
- Sound contextual and freshly written, not templated

Return ONLY valid JSON in this exact format:
{
  "politeDecline": "Full, contextual response text here",
  "softCompromise": "Full, contextual response text here",
  "reschedule": "Full, contextual response text here",
  "acceptRequest": "Full, contextual response text here"
}''';
  }

  /// Get context-specific guidance for relationship type
  String _getRelationshipContext(String relationship) {
    switch (relationship.toLowerCase()) {
      case 'boss':
        return 'formal/power dynamic - respect authority while protecting boundaries';
      case 'peer':
        return 'professional equality - collaborative but firm';
      case 'friend':
        return 'personal/casual - warmth valued, honesty essential';
      case 'family':
        return 'personal/emotional - boundaries may be harder, gentle but clear';
      default:
        return 'professional setting';
    }
  }

  /// Get a random variety hint to encourage different responses each time
  String _getVarietyHint() {
    final hints = [
      'Try varying your opening phrases - use different ways to acknowledge the request.',
      'Experiment with different sentence lengths and structures for variety.',
      'Use varied vocabulary - avoid repeating the same words across responses.',
      'Mix up your tone within the appropriate range - sometimes more direct, sometimes more explanatory.',
      'Consider different ways to phrase similar concepts.',
      'Vary how you transition between ideas in your responses.',
      'Try different closing phrases - not always the same sign-off.',
      'Adjust your level of detail - sometimes more concise, sometimes more explanatory.',
    ];
    return hints[DateTime.now().millisecondsSinceEpoch % hints.length];
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
    final greeting = _getGreeting(relationship);
    final relationshipTone = _getRelationshipTone(relationship);

    // Extract key elements from the request for personalization
    String requestRef = 'this request';
    if (incomingText.toLowerCase().contains('project')) {
      requestRef = 'this project';
    }
    if (incomingText.toLowerCase().contains('meeting')) {
      requestRef = 'this meeting';
    }
    if (incomingText.toLowerCase().contains('deadline')) {
      requestRef = 'this deadline';
    }
    if (incomingText.toLowerCase().contains('help') ||
        incomingText.toLowerCase().contains('assist')) {
      requestRef = 'this';
    }

    return BoundaryResponses(
      politeDecline: _buildPersonalizedDecline(
        incomingText,
        relationship,
        isDepleted,
        greeting,
        relationshipTone,
        requestRef,
      ),
      softCompromise: _buildPersonalizedCompromise(
        incomingText,
        relationship,
        isDepleted,
        greeting,
        relationshipTone,
        requestRef,
      ),
      reschedule: _buildPersonalizedReschedule(
        incomingText,
        relationship,
        isDepleted,
        greeting,
        relationshipTone,
        requestRef,
      ),
      acceptRequest: _buildPersonalizedAccept(
        incomingText,
        relationship,
        isDepleted,
        capacityLevel,
        greeting,
        relationshipTone,
        requestRef,
      ),
    );
  }

  /// Get appropriate greeting based on relationship
  String _getGreeting(String relationship) {
    switch (relationship.toLowerCase()) {
      case 'boss':
        return '';
      case 'peer':
        return 'Hi there,';
      case 'friend':
        return 'Hey!';
      case 'family':
        return 'Hi,';
      default:
        return '';
    }
  }

  /// Get tone indicator based on relationship
  String _getRelationshipTone(String relationship) {
    switch (relationship.toLowerCase()) {
      case 'boss':
        return 'formal';
      case 'peer':
        return 'professional';
      case 'friend':
        return 'casual';
      case 'family':
        return 'warm';
      default:
        return 'professional';
    }
  }

  /// Build personalized decline response
  String _buildPersonalizedDecline(
    String incomingText,
    String relationship,
    bool isDepleted,
    String greeting,
    String tone,
    String requestRef,
  ) {
    final baseDecline = isDepleted
        ? 'I need to be upfront - I\'m currently at capacity and wouldn\'t be able to give $requestRef the attention it deserves.'
        : '$greeting Thanks for reaching out about $requestRef! I won\'t be able to take this on right now.';

    final contextAddition = _getContextualAddition(incomingText, tone);
    return '$baseDecline $contextAddition';
  }

  /// Build personalized compromise response
  String _buildPersonalizedCompromise(
    String incomingText,
    String relationship,
    bool isDepleted,
    String greeting,
    String tone,
    String requestRef,
  ) {
    final baseCompromise = isDepleted
        ? '$greeting I can\'t take $requestRef on directly right now.'
        : '$greeting I can\'t commit to the full scope of $requestRef.';

    final offer = isDepleted
        ? 'However, I do have some templates and resources from similar work that might save you time. Want me to share those?'
        : 'That said, I could help with a specific piece or review the approach when you\'re further along. Let me know what would be most helpful.';

    return '$baseCompromise $offer';
  }

  /// Build personalized reschedule response
  String _buildPersonalizedReschedule(
    String incomingText,
    String relationship,
    bool isDepleted,
    String greeting,
    String tone,
    String requestRef,
  ) {
    if (isDepleted) {
      return '$greeting I looked at my schedule and this week is fully booked. I wouldn\'t be able to give $requestRef the time it needs in the current timeline. Can we revisit this when things calm down?';
    }

    final timingSuggestion = incomingText.toLowerCase().contains('week')
        ? 'Would early next week work? I have some bandwidth then.'
        : 'This week isn\'t ideal timing-wise. Would next week work better?';

    return '$greeting Thanks for thinking of me for $requestRef! $timingSuggestion I want to make sure I can give this proper attention.';
  }

  /// Build personalized accept response
  String _buildPersonalizedAccept(
    String incomingText,
    String relationship,
    bool isDepleted,
    CapacityLevel capacityLevel,
    String greeting,
    String tone,
    String requestRef,
  ) {
    if (isDepleted) {
      return '⚠️ BURNOUT WARNING: Your capacity is critically low (${capacityLevel.label}).\n\nIf you must accept, consider: "$greeting I can take on $requestRef, but given my current bandwidth, I\'ll need to adjust expectations on [other commitment] to make this work. Can we discuss scope?"';
    }

    final enthusiasm = tone == 'casual'
        ? 'Happy to help!'
        : 'I\'d be glad to take this on.';
    final timeline =
        incomingText.toLowerCase().contains('deadline') ||
            incomingText.toLowerCase().contains('friday')
        ? 'I\'ll review the requirements and get back to you with a realistic timeline.'
        : 'I\'ll get started and keep you posted on progress.';

    return '$greeting $enthusiasm $timeline';
  }

  /// Get contextual addition based on request content and tone
  String _getContextualAddition(String incomingText, String tone) {
    final lower = incomingText.toLowerCase();

    if (lower.contains('deadline') ||
        lower.contains('asap') ||
        lower.contains('urgent')) {
      return tone == 'formal'
          ? 'Given the timeline, I want to ensure you find someone who can give this proper attention.'
          : 'With the timeline you mentioned, I want to make sure you get the help you need promptly.';
    }

    if (lower.contains('project') || lower.contains('long-term')) {
      return 'Please keep me in mind for future collaborations though!';
    }

    return tone == 'casual'
        ? 'Hope you find someone who can help!'
        : 'Please reach out if there\'s anything else I can assist with.';
  }

  /// Get the last generated responses (for debugging)
  BoundaryResponses? get lastResponses => _lastResponses;
}
