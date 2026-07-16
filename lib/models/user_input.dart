/// User Inputs - self-reported values that feed into Margin Score calculation
class UserInput {
  final double sleep; // Hours of sleep (0-12 for dev testing)
  final double energy; // Energy level (1-10)
  final double meetingLoad; // Meeting hours (0-16)

  UserInput({
    required this.sleep,
    required this.energy,
    required this.meetingLoad,
  });

  /// Validate inputs are within acceptable ranges
  bool get isValid {
    return sleep >= 0 && sleep <= 12 &&
           energy >= 1 && energy <= 10 &&
           meetingLoad >= 0 && meetingLoad <= 16;
  }

  /// Get validation errors
  List<String> get validationErrors {
    final errors = <String>[];
    if (sleep < 0 || sleep > 12) {
      errors.add('Sleep must be between 0-12 hours');
    }
    if (energy < 1 || energy > 10) {
      errors.add('Energy must be between 1-10');
    }
    if (meetingLoad < 0 || meetingLoad > 16) {
      errors.add('Meeting load must be between 0-16 hours');
    }
    return errors;
  }

  UserInput copyWith({
    double? sleep,
    double? energy,
    double? meetingLoad,
  }) {
    return UserInput(
      sleep: sleep ?? this.sleep,
      energy: energy ?? this.energy,
      meetingLoad: meetingLoad ?? this.meetingLoad,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sleep': sleep,
      'energy': energy,
      'meetingLoad': meetingLoad,
    };
  }

  factory UserInput.fromJson(Map<String, dynamic> json) {
    return UserInput(
      sleep: (json['sleep'] as num?)?.toDouble() ?? 7.0,
      energy: (json['energy'] as num?)?.toDouble() ?? 7.0,
      meetingLoad: (json['meetingLoad'] as num?)?.toDouble() ?? 6.0,
    );
  }
}
