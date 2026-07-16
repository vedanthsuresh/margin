/// WearableData - metrics from wearable devices
/// Sources: Apple Watch, Fitbit, Oura Ring, etc.
class WearableData {
  final double sleep; // Hours of sleep (0-12)
  final double energy; // Energy level (1-10)

  const WearableData({
    required this.sleep,
    required this.energy,
  });

  /// Validate inputs are within acceptable ranges
  bool get isValid {
    return sleep >= 0 && sleep <= 12 && energy >= 1 && energy <= 10;
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
    return errors;
  }

  WearableData copyWith({
    double? sleep,
    double? energy,
  }) {
    return WearableData(
      sleep: sleep ?? this.sleep,
      energy: energy ?? this.energy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sleep': sleep,
      'energy': energy,
    };
  }

  factory WearableData.fromJson(Map<String, dynamic> json) {
    return WearableData(
      sleep: (json['sleep'] as num?)?.toDouble() ?? 7.0,
      energy: (json['energy'] as num?)?.toDouble() ?? 7.0,
    );
  }

  @override
  String toString() => 'WearableData(sleep: $sleep, energy: $energy)';
}
