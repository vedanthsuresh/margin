import 'wearable_data.dart';
import 'calendar_data.dart';

/// UserInput - combines all data sources for Margin Score calculation
class UserInput {
  final WearableData wearableData;
  final CalendarData calendarData;

  UserInput({
    required this.wearableData,
    required this.calendarData,
  });

  /// Convenience getter for sleep
  double get sleep => wearableData.sleep;

  /// Convenience getter for energy
  double get energy => wearableData.energy;

  /// Convenience getter for meeting load
  double get meetingLoad => calendarData.meetingLoad;

  /// Validate all inputs are within acceptable ranges
  bool get isValid => wearableData.isValid && calendarData.isValid;

  /// Get all validation errors
  List<String> get validationErrors {
    return [...wearableData.validationErrors, ...calendarData.validationErrors];
  }

  /// Create from individual values (for backwards compatibility)
  factory UserInput.fromValues({
    required double sleep,
    required double energy,
    required double meetingLoad,
  }) {
    return UserInput(
      wearableData: WearableData(sleep: sleep, energy: energy),
      calendarData: CalendarData(meetingLoad: meetingLoad),
    );
  }

  UserInput copyWith({
    WearableData? wearableData,
    CalendarData? calendarData,
    double? sleep,
    double? energy,
    double? meetingLoad,
  }) {
    return UserInput(
      wearableData: wearableData ??
          this.wearableData.copyWith(
            sleep: sleep,
            energy: energy,
          ),
      calendarData: calendarData ??
          this.calendarData.copyWith(
            meetingLoad: meetingLoad,
          ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wearableData': wearableData.toJson(),
      'calendarData': calendarData.toJson(),
    };
  }

  factory UserInput.fromJson(Map<String, dynamic> json) {
    return UserInput(
      wearableData: json['wearableData'] != null
          ? WearableData.fromJson(json['wearableData'])
          : WearableData(
              sleep: (json['sleep'] as num?)?.toDouble() ?? 7.0,
              energy: (json['energy'] as num?)?.toDouble() ?? 7.0,
            ),
      calendarData: json['calendarData'] != null
          ? CalendarData.fromJson(json['calendarData'])
          : CalendarData(
              meetingLoad: (json['meetingLoad'] as num?)?.toDouble() ?? 6.0,
            ),
    );
  }

  @override
  String toString() =>
      'UserInput(wearable: $wearableData, calendar: $calendarData)';
}
