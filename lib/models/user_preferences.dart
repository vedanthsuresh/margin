/// User preferences collected during onboarding
class UserPreferences {
  final String userRole;
  final String companySize;
  final String timezoneSpan;
  final String? chronotype;

  // Calendar and work-life
  final bool calendarConnected;
  final bool? worksLateHours;
  final bool? worksWeekends;

  final DateTime completedAt;

  UserPreferences({
    required this.userRole,
    required this.companySize,
    required this.timezoneSpan,
    this.chronotype,
    this.calendarConnected = false,
    this.worksLateHours,
    this.worksWeekends,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'userRole': userRole,
      'companySize': companySize,
      'timezoneSpan': timezoneSpan,
      'chronotype': chronotype,
      'calendarConnected': calendarConnected,
      'worksLateHours': worksLateHours,
      'worksWeekends': worksWeekends,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  /// Create from JSON storage
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userRole: json['userRole'] ?? 'software_engineer',
      companySize: json['companySize'] ?? 'mid_market',
      timezoneSpan: json['timezoneSpan'] ?? 'single_timezone',
      chronotype: json['chronotype'],
      calendarConnected: json['calendarConnected'] ?? false,
      worksLateHours: json['worksLateHours'],
      worksWeekends: json['worksWeekends'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  /// Check if onboarding is complete
  bool get isOnboarded => userRole.isNotEmpty;

  /// Available role options
  static const Map<String, String> roleOptions = {
    'software_engineer': 'Software Engineer',
    'product_manager': 'Product Manager',
    'designer': 'Designer',
    'sales': 'Sales',
    'marketing': 'Marketing',
    'executive': 'Executive',
    'hr': 'Human Resources',
    'finance': 'Finance/Accounting',
    'consultant': 'Consultant',
    'freelancer': 'Freelancer',
    'student': 'Student',
  };

  /// Available company size options
  static const Map<String, String> companySizeOptions = {
    'startup': 'Startup',
    'small_business': 'Small Business (10-50 employees)',
    'mid_market': 'Mid-Market (50-500 employees)',
    'enterprise': 'Enterprise (500+ employees)',
    'mega_corp': 'Mega Corporation (10K+ employees)',
  };

  /// Available timezone span options
  static const Map<String, String> timezoneSpanOptions = {
    'single_timezone': 'Single timezone',
    'dual_timezone': 'Dual timezone (US coasts)',
    'multi_timezone': 'Multi (3+ timezones)',
    'global_team': 'Global team (APAC, EMEA, Americas)',
  };

  /// Available chronotype options
  static const Map<String, String> chronotypeOptions = {
    'morning_person': 'Morning person',
    'afternoon_person': 'Afternoon person',
    'evening_person': 'Evening person',
    'consistent': 'Consistent throughout day',
  };

  /// Get display name for a role key
  static String getRoleDisplayName(String key) {
    return roleOptions[key] ?? key;
  }

  /// Get display name for a company size key
  static String getCompanySizeDisplayName(String key) {
    return companySizeOptions[key] ?? key;
  }

  /// Get display name for a timezone span key
  static String getTimezoneSpanDisplayName(String key) {
    return timezoneSpanOptions[key] ?? key;
  }

  /// Get display name for a chronotype key
  static String getChronotypeDisplayName(String? key) {
    if (key == null) return 'Not specified';
    return chronotypeOptions[key] ?? key;
  }

  UserPreferences copyWith({
    String? userRole,
    String? companySize,
    String? timezoneSpan,
    String? chronotype,
    DateTime? completedAt,
  }) {
    return UserPreferences(
      userRole: userRole ?? this.userRole,
      companySize: companySize ?? this.companySize,
      timezoneSpan: timezoneSpan ?? this.timezoneSpan,
      chronotype: chronotype ?? this.chronotype,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
