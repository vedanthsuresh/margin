/// CalendarData - metrics derived from calendar integration
/// Sources: Google Calendar, Outlook, etc.
class CalendarData {
  final double meetingLoad; // Meeting hours today (0-16)

  const CalendarData({
    required this.meetingLoad,
  });

  /// Validate inputs are within acceptable ranges
  bool get isValid {
    return meetingLoad >= 0 && meetingLoad <= 16;
  }

  /// Get validation errors
  List<String> get validationErrors {
    final errors = <String>[];
    if (meetingLoad < 0 || meetingLoad > 16) {
      errors.add('Meeting load must be between 0-16 hours');
    }
    return errors;
  }

  CalendarData copyWith({
    double? meetingLoad,
  }) {
    return CalendarData(
      meetingLoad: meetingLoad ?? this.meetingLoad,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meetingLoad': meetingLoad,
    };
  }

  factory CalendarData.fromJson(Map<String, dynamic> json) {
    return CalendarData(
      meetingLoad: (json['meetingLoad'] as num?)?.toDouble() ?? 6.0,
    );
  }

  @override
  String toString() => 'CalendarData(meetingLoad: $meetingLoad)';
}
