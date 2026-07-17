/// AI Classification Service for "Other" field inputs
///
/// This service analyzes user-provided "other" text for role and company size
/// and determines their impact on the Margin Score using AI.
///
/// The service provides both local classification (rule-based fallback) and
/// backend-based classification (using Vertex AI via Cloud Run).
import '../models/margin_context.dart';
import '../models/user_preferences.dart';

/// Classification result for a role
class RoleClassificationResult {
  final String matchedRoleKey;
  final String roleDisplayName;
  final double? averageMeetingHours;
  final double? averageFocusTime;
  final int? averageCommunicationsLoad;
  final String reasoning;

  const RoleClassificationResult({
    required this.matchedRoleKey,
    required this.roleDisplayName,
    this.averageMeetingHours,
    this.averageFocusTime,
    this.averageCommunicationsLoad,
    required this.reasoning,
  });

  factory RoleClassificationResult.fromJson(Map<String, dynamic> json) {
    return RoleClassificationResult(
      matchedRoleKey: json['matchedRoleKey'] ?? '',
      roleDisplayName: json['roleDisplayName'] ?? '',
      averageMeetingHours: (json['averageMeetingHours'] as num?)?.toDouble(),
      averageFocusTime: (json['averageFocusTime'] as num?)?.toDouble(),
      averageCommunicationsLoad: json['averageCommunicationsLoad'],
      reasoning: json['reasoning'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchedRoleKey': matchedRoleKey,
      'roleDisplayName': roleDisplayName,
      'averageMeetingHours': averageMeetingHours,
      'averageFocusTime': averageFocusTime,
      'averageCommunicationsLoad': averageCommunicationsLoad,
      'reasoning': reasoning,
    };
  }

  /// Create an IndustryBenchmark from this classification
  IndustryBenchmark? toIndustryBenchmark() {
    if (averageMeetingHours == null || averageFocusTime == null || averageCommunicationsLoad == null) {
      return null;
    }
    return IndustryBenchmark(
      averageMeetingHours: averageMeetingHours!,
      averageFocusTime: averageFocusTime!,
      averageCommunicationsLoad: averageCommunicationsLoad!,
      description: reasoning,
    );
  }
}

/// Classification result for a company size
class CompanySizeClassificationResult {
  final String matchedSizeKey;
  final String sizeDisplayName;
  final int adjustment;
  final String reasoning;

  const CompanySizeClassificationResult({
    required this.matchedSizeKey,
    required this.sizeDisplayName,
    required this.adjustment,
    required this.reasoning,
  });

  factory CompanySizeClassificationResult.fromJson(Map<String, dynamic> json) {
    return CompanySizeClassificationResult(
      matchedSizeKey: json['matchedSizeKey'] ?? '',
      sizeDisplayName: json['sizeDisplayName'] ?? '',
      adjustment: json['adjustment'] ?? 0,
      reasoning: json['reasoning'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchedSizeKey': matchedSizeKey,
      'sizeDisplayName': sizeDisplayName,
      'adjustment': adjustment,
      'reasoning': reasoning,
    };
  }
}

/// Overall classification result for both fields
class ClassificationResult {
  final RoleClassificationResult? roleResult;
  final CompanySizeClassificationResult? companySizeResult;

  const ClassificationResult({
    this.roleResult,
    this.companySizeResult,
  });

  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    return ClassificationResult(
      roleResult: json['roleResult'] != null
          ? RoleClassificationResult.fromJson(json['roleResult'])
          : null,
      companySizeResult: json['companySizeResult'] != null
          ? CompanySizeClassificationResult.fromJson(json['companySizeResult'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roleResult': roleResult?.toJson(),
      'companySizeResult': companySizeResult?.toJson(),
    };
  }
}

/// AI Classification Service
class AIClassificationService {
  /// Base URL for Cloud Run backend
  final String? backendBaseUrl;

  const AIClassificationService({this.backendBaseUrl});

  /// Classify "other" role text
  ///
  /// Returns the best matching role and its industry benchmark data
  Future<RoleClassificationResult> classifyRole(
    String otherRoleText,
    Map<String, IndustryBenchmark> benchmarks,
  ) async {
    // If backend URL is configured, use AI classification
    if (backendBaseUrl != null && backendBaseUrl!.isNotEmpty) {
      try {
        return await _classifyRoleViaBackend(otherRoleText, benchmarks);
      } catch (e) {
        // Fallback to local classification on error
        return _classifyRoleLocally(otherRoleText, benchmarks);
      }
    }

    // Otherwise, use local rule-based classification
    return _classifyRoleLocally(otherRoleText, benchmarks);
  }

  /// Classify "other" company size text
  ///
  /// Returns the appropriate adjustment value based on company size
  Future<CompanySizeClassificationResult> classifyCompanySize(
    String otherCompanySizeText,
    Map<String, CompanySizeFactor> companySizeFactors,
  ) async {
    // If backend URL is configured, use AI classification
    if (backendBaseUrl != null && backendBaseUrl!.isNotEmpty) {
      try {
        return await _classifyCompanySizeViaBackend(otherCompanySizeText, companySizeFactors);
      } catch (e) {
        // Fallback to local classification on error
        return _classifyCompanySizeLocally(otherCompanySizeText, companySizeFactors);
      }
    }

    // Otherwise, use local rule-based classification
    return _classifyCompanySizeLocally(otherCompanySizeText, companySizeFactors);
  }

  /// Classify both fields at once (for onboarding completion)
  Future<ClassificationResult> classifyUserPreferences(
    UserPreferences preferences,
    MarginContext context,
  ) async {
    ClassificationResult result = const ClassificationResult();

    // Classify role if "other" was selected
    if (preferences.userRole == 'other' && preferences.otherRole != null) {
      final roleResult = await classifyRole(
        preferences.otherRole!,
        context.industryBenchmarks,
      );
      result = ClassificationResult(
        roleResult: roleResult,
        companySizeResult: result.companySizeResult,
      );
    }

    // Classify company size if "other" was selected
    if (preferences.companySize == 'other' && preferences.otherCompanySize != null) {
      final companySizeResult = await classifyCompanySize(
        preferences.otherCompanySize!,
        context.companySizeFactors,
      );
      result = ClassificationResult(
        roleResult: result.roleResult,
        companySizeResult: companySizeResult,
      );
    }

    return result;
  }

  /// Backend-based role classification via Cloud Run
  Future<RoleClassificationResult> _classifyRoleViaBackend(
    String otherRoleText,
    Map<String, IndustryBenchmark> benchmarks,
  ) async {
    // TODO: Implement actual API call to Cloud Run backend
    // For now, fallback to local classification
    return _classifyRoleLocally(otherRoleText, benchmarks);
  }

  /// Backend-based company size classification via Cloud Run
  Future<CompanySizeClassificationResult> _classifyCompanySizeViaBackend(
    String otherCompanySizeText,
    Map<String, CompanySizeFactor> companySizeFactors,
  ) async {
    // TODO: Implement actual API call to Cloud Run backend
    // For now, fallback to local classification
    return _classifyCompanySizeLocally(otherCompanySizeText, companySizeFactors);
  }

  /// Local rule-based role classification
  RoleClassificationResult _classifyRoleLocally(
    String otherRoleText,
    Map<String, IndustryBenchmark> benchmarks,
  ) {
    final text = otherRoleText.toLowerCase();

    // Define role keyword mappings for local classification
    final Map<String, List<String>> roleKeywords = {
      'software_engineer': ['engineer', 'developer', 'programmer', 'coder', 'software', 'full stack', 'backend', 'frontend', 'devops', 'sre'],
      'product_manager': ['product manager', 'pm', 'product owner', 'scrum master'],
      'designer': ['designer', 'ux', 'ui', 'graphic', 'visual', 'product design'],
      'sales': ['sales', 'account executive', 'ae', 'business development', 'bd'],
      'marketing': ['marketing', 'growth', 'brand', 'content', 'seo', 'social media'],
      'executive': ['ceo', 'cto', 'cfo', 'coo', 'chief', 'vp', 'vice president', 'director'],
      'hr': ['hr', 'human resources', 'recruiter', 'people', 'talent'],
      'finance': ['finance', 'accounting', 'accountant', 'financial analyst', 'controller'],
      'consultant': ['consultant', 'advisor', 'contractor'],
      'freelancer': ['freelancer', 'independent', 'self-employed', 'solopreneur'],
      'student': ['student', 'intern', 'graduate', 'undergraduate'],
    };

    // Find best matching role based on keywords
    String? bestMatch;
    int bestMatchScore = 0;

    for (var entry in roleKeywords.entries) {
      final keywords = entry.value;
      int score = 0;

      for (var keyword in keywords) {
        if (text.contains(keyword)) {
          score += keyword.length; // Longer matches get higher scores
        }
      }

      if (score > bestMatchScore) {
        bestMatchScore = score;
        bestMatch = entry.key;
      }
    }

    // If we found a match, use its benchmark
    if (bestMatch != null && benchmarks.containsKey(bestMatch)) {
      final benchmark = benchmarks[bestMatch]!;
      return RoleClassificationResult(
        matchedRoleKey: bestMatch,
        roleDisplayName: UserPreferences.getRoleDisplayName(bestMatch),
        averageMeetingHours: benchmark.averageMeetingHours,
        averageFocusTime: benchmark.averageFocusTime,
        averageCommunicationsLoad: benchmark.averageCommunicationsLoad,
        reasoning: 'Matched to $bestMatch based on keyword analysis',
      );
    }

    // Default fallback to "software_engineer" if no match found
    final defaultBenchmark = benchmarks['software_engineer']!;
    return RoleClassificationResult(
      matchedRoleKey: 'software_engineer',
      roleDisplayName: 'Software Engineer',
      averageMeetingHours: defaultBenchmark.averageMeetingHours,
      averageFocusTime: defaultBenchmark.averageFocusTime,
      averageCommunicationsLoad: defaultBenchmark.averageCommunicationsLoad,
      reasoning: 'No specific match found, using default software engineer benchmark',
    );
  }

  /// Local rule-based company size classification
  CompanySizeClassificationResult _classifyCompanySizeLocally(
    String otherCompanySizeText,
    Map<String, CompanySizeFactor> companySizeFactors,
  ) {
    final text = otherCompanySizeText.toLowerCase();

    // Extract employee count if present (e.g., "50 employees", "1000+ employees")
    final employeeMatch = RegExp(r'(\d+).*?(?:employee|people|staff|member)', caseSensitive: false).firstMatch(text);

    int? employeeCount;
    if (employeeMatch != null) {
      employeeCount = int.tryParse(employeeMatch.group(1) ?? '');
    }

    // Classify based on employee count
    if (employeeCount != null) {
      if (employeeCount < 10) {
        return CompanySizeClassificationResult(
          matchedSizeKey: 'startup',
          sizeDisplayName: 'Startup',
          adjustment: companySizeFactors['startup']?.adjustment ?? -3,
          reasoning: 'Classified as startup based on employee count ($employeeCount)',
        );
      } else if (employeeCount < 50) {
        return CompanySizeClassificationResult(
          matchedSizeKey: 'small_business',
          sizeDisplayName: 'Small Business (10-50 employees)',
          adjustment: companySizeFactors['small_business']?.adjustment ?? -2,
          reasoning: 'Classified as small business based on employee count ($employeeCount)',
        );
      } else if (employeeCount < 500) {
        return CompanySizeClassificationResult(
          matchedSizeKey: 'mid_market',
          sizeDisplayName: 'Mid-Market (50-500 employees)',
          adjustment: companySizeFactors['mid_market']?.adjustment ?? 0,
          reasoning: 'Classified as mid-market based on employee count ($employeeCount)',
        );
      } else if (employeeCount < 10000) {
        return CompanySizeClassificationResult(
          matchedSizeKey: 'enterprise',
          sizeDisplayName: 'Enterprise (500+ employees)',
          adjustment: companySizeFactors['enterprise']?.adjustment ?? -2,
          reasoning: 'Classified as enterprise based on employee count ($employeeCount)',
        );
      } else {
        return CompanySizeClassificationResult(
          matchedSizeKey: 'mega_corp',
          sizeDisplayName: 'Mega Corporation (10K+ employees)',
          adjustment: companySizeFactors['mega_corp']?.adjustment ?? -4,
          reasoning: 'Classified as mega corporation based on employee count ($employeeCount)',
        );
      }
    }

    // Keyword-based classification as fallback
    if (text.contains('startup') || text.contains('early stage')) {
      return CompanySizeClassificationResult(
        matchedSizeKey: 'startup',
        sizeDisplayName: 'Startup',
        adjustment: companySizeFactors['startup']?.adjustment ?? -3,
        reasoning: 'Classified as startup based on keyword analysis',
      );
    } else if (text.contains('small') || text.contains('smb')) {
      return CompanySizeClassificationResult(
        matchedSizeKey: 'small_business',
        sizeDisplayName: 'Small Business (10-50 employees)',
        adjustment: companySizeFactors['small_business']?.adjustment ?? -2,
        reasoning: 'Classified as small business based on keyword analysis',
      );
    } else if (text.contains('fortune') || text.contains('large') || text.contains('big')) {
      return CompanySizeClassificationResult(
        matchedSizeKey: 'mega_corp',
        sizeDisplayName: 'Mega Corporation (10K+ employees)',
        adjustment: companySizeFactors['mega_corp']?.adjustment ?? -4,
        reasoning: 'Classified as mega corporation based on keyword analysis',
      );
    } else if (text.contains('enterprise') || text.contains('public') || text.contains('corp')) {
      return CompanySizeClassificationResult(
        matchedSizeKey: 'enterprise',
        sizeDisplayName: 'Enterprise (500+ employees)',
        adjustment: companySizeFactors['enterprise']?.adjustment ?? -2,
        reasoning: 'Classified as enterprise based on keyword analysis',
      );
    }

    // Default fallback to mid-market
    return CompanySizeClassificationResult(
      matchedSizeKey: 'mid_market',
      sizeDisplayName: 'Mid-Market (50-500 employees)',
      adjustment: companySizeFactors['mid_market']?.adjustment ?? 0,
      reasoning: 'No specific match found, using default mid-market classification',
    );
  }
}
