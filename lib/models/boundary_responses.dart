/// BoundaryResponses - AI-generated response options for setting boundaries
///
/// Contains four response strategies that change based on user's current margin score:
/// - Polite Decline: Warm if high capacity, firm if low capacity
/// - Soft Compromise: Offers partial labor if high capacity, passive resources only if low
/// - Reschedule: Suggests time if high capacity, refuses if low capacity or week is packed
/// - Accept Request: Enthusiastic if high capacity, friction warning if low capacity
class BoundaryResponses {
  final String politeDecline;
  final String softCompromise;
  final String reschedule;
  final String acceptRequest;

  BoundaryResponses({
    required this.politeDecline,
    required this.softCompromise,
    required this.reschedule,
    required this.acceptRequest,
  });

  /// Create from JSON
  factory BoundaryResponses.fromJson(Map<String, dynamic> json) {
    return BoundaryResponses(
      politeDecline: json['politeDecline'] as String? ?? '',
      softCompromise: json['softCompromise'] as String? ?? '',
      reschedule: json['reschedule'] as String? ?? '',
      acceptRequest: json['acceptRequest'] as String? ?? '',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'politeDecline': politeDecline,
      'softCompromise': softCompromise,
      'reschedule': reschedule,
      'acceptRequest': acceptRequest,
    };
  }

  /// Get response by action type
  String getResponse(ActionType action) {
    switch (action) {
      case ActionType.politeDecline:
        return politeDecline;
      case ActionType.softCompromise:
        return softCompromise;
      case ActionType.reschedule:
        return reschedule;
      case ActionType.acceptRequest:
        return acceptRequest;
    }
  }

  /// Copy with replacement
  BoundaryResponses copyWith({
    String? politeDecline,
    String? softCompromise,
    String? reschedule,
    String? acceptRequest,
  }) {
    return BoundaryResponses(
      politeDecline: politeDecline ?? this.politeDecline,
      softCompromise: softCompromise ?? this.softCompromise,
      reschedule: reschedule ?? this.reschedule,
      acceptRequest: acceptRequest ?? this.acceptRequest,
    );
  }

  @override
  String toString() =>
      'BoundaryResponses(politeDecline: ${politeDecline.length} chars, '
      'softCompromise: ${softCompromise.length} chars, '
      'reschedule: ${reschedule.length} chars, '
      'acceptRequest: ${acceptRequest.length} chars)';
}

/// Action types for boundary responses
enum ActionType {
  politeDecline,
  softCompromise,
  reschedule,
  acceptRequest;

  /// Get display label for the action
  String get label {
    switch (this) {
      case ActionType.politeDecline:
        return 'Polite Decline';
      case ActionType.softCompromise:
        return 'Soft Compromise';
      case ActionType.reschedule:
        return 'Reschedule';
      case ActionType.acceptRequest:
        return 'Accept Request';
    }
  }

  /// Get icon for the action
  String get icon {
    switch (this) {
      case ActionType.politeDecline:
        return 'cancel';
      case ActionType.softCompromise:
        return 'handshake';
      case ActionType.reschedule:
        return 'calendar_today';
      case ActionType.acceptRequest:
        return 'check_circle';
    }
  }
}
