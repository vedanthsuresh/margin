import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/user_preferences.dart';
import '../services/preferences_service.dart';
import '../services/calendar_service.dart';
import '../widgets/onboarding_widgets.dart';

/// Onboarding flow for collecting user preferences
class OnboardingScreen extends StatefulWidget {
  final PreferencesService preferencesService;

  const OnboardingScreen({
    super.key,
    required this.preferencesService,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Track selections for each question
  String? _selectedRole;
  String? _selectedCompanySize;
  String? _selectedTimezoneSpan;
  String? _selectedChronotype;
  bool? _calendarConnected;

  // Calendar service
  final CalendarService _calendarService = CalendarService();

  // Manual work-life answers (if calendar declined)
  bool? _worksLateHours;
  bool? _worksWeekends;

  // Loading state
  bool _isConnectingCalendar = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _connectCalendar() async {
    setState(() => _isConnectingCalendar = true);

    try {
      await _calendarService.connect();

      if (mounted) {
        setState(() {
          _calendarConnected = true;
          _isConnectingCalendar = false;
        });

        // Skip manual questions and go to completion page (2 pages ahead)
        _pageController.jumpToPage(_pages.length - 1);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnectingCalendar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not connect to calendar: $e')),
        );
      }
    }
  }

  void _skipCalendar() {
    setState(() => _calendarConnected = false);

    // Move to manual questions page
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    final preferences = UserPreferences(
      userRole: _selectedRole ?? 'software_engineer',
      companySize: _selectedCompanySize ?? 'mid_market',
      timezoneSpan: _selectedTimezoneSpan ?? 'single_timezone',
      chronotype: _selectedChronotype,
      calendarConnected: _calendarConnected ?? false,
      worksLateHours: _worksLateHours,
      worksWeekends: _worksWeekends,
    );

    await widget.preferencesService.savePreferences(preferences);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  List<Widget> get _pages => [
    _WelcomePage(onGetStarted: _nextPage),
    _QuestionPage(
      question: 'What\'s your role?',
      subtitle: 'This helps us compare your workload to industry benchmarks',
      options: UserPreferences.roleOptions,
      selectedOption: _selectedRole,
      onOptionSelected: (value) {
        setState(() => _selectedRole = value);
      },
    ),
    _QuestionPage(
      question: 'What\'s your company size?',
      subtitle: 'Organization size affects meeting complexity and overhead',
      options: UserPreferences.companySizeOptions,
      selectedOption: _selectedCompanySize,
      onOptionSelected: (value) {
        setState(() => _selectedCompanySize = value);
      },
    ),
    _QuestionPage(
      question: 'Do you work across multiple timezones?',
      subtitle: 'Working across timezones adds cognitive load',
      options: UserPreferences.timezoneSpanOptions,
      selectedOption: _selectedTimezoneSpan,
      onOptionSelected: (value) {
        setState(() => _selectedTimezoneSpan = value);
      },
    ),
    _QuestionPage(
      question: 'When\'s your peak energy?',
      subtitle: 'Optional - helps us understand your daily rhythm',
      options: UserPreferences.chronotypeOptions,
      selectedOption: _selectedChronotype,
      onOptionSelected: (value) {
        setState(() => _selectedChronotype = value);
      },
      isOptional: true,
    ),
    _CalendarQuestionPage(
      onConnect: _connectCalendar,
      onSkip: _skipCalendar,
      isConnecting: _isConnectingCalendar,
    ),
    _WorkLifeManualQuestionPage(
      worksLateHours: _worksLateHours,
      worksWeekends: _worksWeekends,
      onLateHoursChanged: (value) {
        setState(() => _worksLateHours = value);
      },
      onWeekendsChanged: (value) {
        setState(() => _worksWeekends = value);
      },
      onNext: _nextPage,
    ),
    _CompletionPage(
      onComplete: _completeOnboarding,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            OnboardingProgress(
              currentStep: _currentPage + 1,
              totalSteps: _pages.length,
              progress: (_currentPage + 1) / _pages.length,
            ),

            // Page view
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: _pages,
              ),
            ),

            // Navigation buttons
            _buildNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigation() {
    final isFirstPage = _currentPage == 0;
    final isLastPage = _currentPage == _pages.length - 1;
    final isCalendarPage = _currentPage == 5; // Calendar page has its own buttons
    final isWorkLifePage = _currentPage == 6; // Work-life page has its own buttons

    // Hide default navigation for calendar and work-life pages
    if (isCalendarPage || isWorkLifePage) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (!isFirstPage)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back'),
              ),
            ),
          if (!isFirstPage) const SizedBox(width: 16),
          Expanded(
            flex: isFirstPage ? 1 : 2,
            child: ElevatedButton(
              onPressed: _canProceed() ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(isLastPage ? 'Complete' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    if (_currentPage == 0) return true; // Welcome page
    if (_currentPage == 5) return true; // Calendar page handles itself
    if (_currentPage == 6) return true; // Work-life page handles itself
    if (_currentPage == _pages.length - 1) return true; // Completion page

    // Required questions
    if (_currentPage == 1) return _selectedRole != null;
    if (_currentPage == 2) return _selectedCompanySize != null;
    if (_currentPage == 3) return _selectedTimezoneSpan != null;
    if (_currentPage == 4) return true; // Chronotype is optional

    return true;
  }
}

// Welcome Page
class _WelcomePage extends StatelessWidget {
  final VoidCallback onGetStarted;

  const _WelcomePage({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.psychology_outlined,
            size: 80,
            color: Color(0xFF6366F1),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: 32),
          Text(
            'Welcome to Margin',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fade(delay: 100.ms),
          const SizedBox(height: 16),
          Text(
            'Your personal capacity score helps you set boundaries and protect your time.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ).animate().fade(delay: 200.ms),
          const SizedBox(height: 48),
          Text(
            'Answer a few questions to personalize your score',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ).animate().fade(delay: 300.ms),
          const SizedBox(height: 8),
          Text(
            'Takes about 1 minute',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ).animate().fade(delay: 300.ms),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// Question Page
class _QuestionPage extends StatelessWidget {
  final String question;
  final String subtitle;
  final Map<String, String> options;
  final String? selectedOption;
  final Function(String) onOptionSelected;
  final bool isOptional;

  const _QuestionPage({
    required this.question,
    required this.subtitle,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            question,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...options.entries.map((entry) {
            final isSelected = selectedOption == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OptionCard(
                label: entry.value,
                isSelected: isSelected,
                onTap: () => onOptionSelected(entry.key),
              ),
            );
          }),
          if (isOptional)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: () => onOptionSelected(''),
                child: Text(
                  'Skip',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Calendar Connection Page
class _CalendarQuestionPage extends StatelessWidget {
  final VoidCallback onConnect;
  final VoidCallback onSkip;
  final bool isConnecting;

  const _CalendarQuestionPage({
    required this.onConnect,
    required this.onSkip,
    required this.isConnecting,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_month,
            size: 64,
            color: Color(0xFF6366F1),
          ),
          const SizedBox(height: 24),
          const Text(
            'Connect your calendar?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'We\'ll analyze your meeting patterns to detect late hours and weekend work',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your calendar data stays on your device',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (isConnecting)
            const CircularProgressIndicator()
          else
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onConnect,
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Connect Calendar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Skip for now',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// Manual Work-Life Questions Page
class _WorkLifeManualQuestionPage extends StatefulWidget {
  final bool? worksLateHours;
  final bool? worksWeekends;
  final Function(bool) onLateHoursChanged;
  final Function(bool) onWeekendsChanged;
  final VoidCallback onNext;

  const _WorkLifeManualQuestionPage({
    required this.worksLateHours,
    required this.worksWeekends,
    required this.onLateHoursChanged,
    required this.onWeekendsChanged,
    required this.onNext,
  });

  @override
  State<_WorkLifeManualQuestionPage> createState() =>
      _WorkLifeManualQuestionPageState();
}

class _WorkLifeManualQuestionPageState extends State<_WorkLifeManualQuestionPage> {
  late bool _worksLate = widget.worksLateHours ?? false;
  late bool _worksWeekends = widget.worksWeekends ?? false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.schedule,
            size: 48,
            color: Colors.orange,
          ),
          const SizedBox(height: 24),
          const Text(
            'Tell us about your work patterns',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Since you skipped calendar, we\'ll ask a couple of questions',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _ToggleCard(
            title: 'Do you work late hours?',
            subtitle: 'Meetings or work after 6pm',
            value: _worksLate,
            onChanged: (value) {
              setState(() => _worksLate = value);
              widget.onLateHoursChanged(value);
            },
          ),
          const SizedBox(height: 16),
          _ToggleCard(
            title: 'Do you work weekends?',
            subtitle: 'Meetings or work on Saturday/Sunday',
            value: _worksWeekends,
            onChanged: (value) {
              setState(() => _worksWeekends = value);
              widget.onWeekendsChanged(value);
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }
}

// Completion Page
class _CompletionPage extends StatelessWidget {
  final VoidCallback onComplete;

  const _CompletionPage({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 48,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'You\'re all set!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your personalized Margin Score is ready',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              child: const Text('See My Score'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF6366F1) : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
