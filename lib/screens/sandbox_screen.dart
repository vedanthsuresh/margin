import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/margin_provider.dart';
import '../models/boundary_responses.dart';
import '../models/margin_score.dart';
import '../services/notification_service.dart';
import '../services/share_intent_service.dart';

/// Boundary Sandbox - Where users paste demanding requests and get AI-generated responses
class SandboxScreen extends StatefulWidget {
  const SandboxScreen({super.key});

  @override
  State<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _responseScrollController = ScrollController();

  Relationship _selectedRelationship = Relationship.peer;
  BoundaryResponses? _responses;
  ActionType? _selectedAction;
  bool _isGenerating = false;
  String? _errorMessage;

  // Friction lock state
  bool _isInQuarantine = false;
  bool _quarantineCompleted = false; // Track if user has completed quarantine
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _checkForSharedText();
    _checkQuarantineState();
  }

  /// Check if text was shared from another app and pre-populate the text field
  void _checkForSharedText() {
    final shareIntentService = ShareIntentService();
    final sharedText = shareIntentService.getSharedText();

    if (sharedText != null && sharedText.isNotEmpty) {
      debugPrint('📥 SandboxScreen: Pre-populating with shared text: "$sharedText"');
      _textController.text = sharedText;
      // Clear the shared text after consuming it
      shareIntentService.clearSharedText();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _textController.dispose();
    _responseScrollController.dispose();
    super.dispose();
  }

  Future<void> _checkQuarantineState() async {
    final provider = context.read<MarginProvider>();
    final isActive = await provider.preferencesService.isQuarantineActive();
    if (isActive) {
      setState(() => _isInQuarantine = true);
    }
  }

  void _startCountdownTimer(StateSetter setDialogState) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final provider = context.read<MarginProvider>();
      final remaining = await provider.preferencesService
          .getQuarantineRemainingMillis();

      if (remaining <= 0) {
        timer.cancel();
        // Mark quarantine as completed and update state
        debugPrint('⏱️ Timer ended, setting _quarantineCompleted = true');
        setState(() {
          _isInQuarantine = false;
          _quarantineCompleted = true;
        });
        setDialogState(() {}); // Trigger dialog rebuild to show "Copy Response" button

        // Show notification immediately (more reliable than scheduled for short timers)
        _showQuarantineEndNotification();
      } else {
        setDialogState(() {}); // Trigger dialog rebuild
      }
    });
  }

  void _showBurnoutWarning(
    BuildContext context,
    String responseText,
    MarginScore score,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false, // Force acknowledgment
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Text('Burnout Warning'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your capacity is at ${score.finalScore}%. Accepting this request puts you at risk of burnout.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'A 15-minute cooling-off period will begin. This time helps you reflect on whether this commitment is truly necessary.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'After 15 minutes, you can choose to proceed with copying the response.',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel - I\'ll reconsider'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _startQuarantine();
              if (!mounted) return;
              _showQuarantineDialog(this.context, responseText);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('I understand - Start 15-min wait'),
          ),
        ],
      ),
    );
  }

  void _showQuarantineDialog(BuildContext context, String responseText) {
    // Get provider before showing dialog to avoid context issues
    final provider = context.read<MarginProvider>();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return FutureBuilder<int>(
            future: provider.preferencesService.getQuarantineRemainingMillis(),
            initialData: 0,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return AlertDialog(
                  title: const Text('Error'),
                  content: Text('Error: ${snapshot.error}'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Close'),
                    ),
                  ],
                );
              }

              final remainingMillis = snapshot.data ?? 0;
              final remaining = Duration(milliseconds: remainingMillis);
              final canCopy = remainingMillis <= 0;

              // Start countdown timer on first build
              if (!canCopy && _countdownTimer == null) {
                _startCountdownTimer(setDialogState);
              }

              return AlertDialog(
                title: const Text('Cooling-Off Period'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!canCopy) ...[
                      Icon(Icons.timer, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text(
                        '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')} remaining',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Take this time to consider: Is this commitment truly necessary?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ] else ...[
                      Icon(Icons.check_circle, size: 48, color: Colors.green),
                      const SizedBox(height: 16),
                      const Text(
                        'Cooling-off period complete.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  if (!canCopy)
                    TextButton(
                      onPressed: () {
                        _countdownTimer?.cancel();
                        _countdownTimer = null;
                        // Cancel notification since user is closing the dialog
                        NotificationService().cancelQuarantineEndNotification();
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Close'),
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        _countdownTimer?.cancel();
                        _countdownTimer = null;
                        Navigator.pop(dialogContext);
                        _copyResponse(responseText);
                      },
                      child: const Text('Copy Response'),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _startQuarantine() async {
    final provider = context.read<MarginProvider>();
    await provider.preferencesService.saveQuarantineTimestamp();

    // Schedule notification for when quarantine ends (backup if app is killed)
    await NotificationService().scheduleQuarantineEndNotification();

    setState(() => _isInQuarantine = true);
  }

  /// Show notification immediately when quarantine ends
  void _showQuarantineEndNotification() async {
    // Cancel the scheduled notification first to avoid duplicates
    await NotificationService().cancelQuarantineEndNotification();

    // Show immediate notification
    await NotificationService().showQuarantineEndNotification();
  }

  /// Generate responses using AI service
  Future<void> _generateResponses() async {
    if (_textController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please paste a request first');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _selectedAction = null;
      // Reset quarantine state for new request
      _quarantineCompleted = false;
      _isInQuarantine = false;
    });

    try {
      final provider = context.read<MarginProvider>();
      final responses = await provider.generateBoundaryResponses(
        text: _textController.text,
        relationship: _selectedRelationship.value,
      );

      setState(() {
        _responses = responses;
        _isGenerating = false;
      });

      // Scroll to show responses
      if (_responseScrollController.hasClients) {
        await Future.delayed(const Duration(milliseconds: 100));
        _responseScrollController.animateTo(
          _responseScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Failed to generate responses: $e';
      });
    }
  }

  /// Copy response to clipboard
  void _copyResponse(String text) async {
    final provider = context.read<MarginProvider>();
    final score = provider.currentScore!;

    // Check if this is an "Accept Request" with depleted capacity
    final isAcceptRequest = _selectedAction == ActionType.acceptRequest;
    final isDepleted = score.capacityLevel == CapacityLevel.depleted;

    debugPrint('📋 _copyResponse called: isAcceptRequest=$isAcceptRequest, isDepleted=$isDepleted, _quarantineCompleted=$_quarantineCompleted');

    if (isAcceptRequest && isDepleted) {
      // If quarantine was just completed, allow the copy
      if (_quarantineCompleted) {
        debugPrint('✅ Quarantine completed, allowing copy');
        // Reset quarantine state and allow copy
        setState(() {
          _quarantineCompleted = false;
          _isInQuarantine = false;
        });
        if (!mounted) return;
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Check if already in quarantine
      final remaining = await provider.preferencesService
          .getQuarantineRemainingMillis();

      debugPrint('🕐 Remaining: ${remaining}ms');

      if (!mounted) return;

      if (remaining > 0) {
        // Still in quarantine - show countdown dialog
        debugPrint('🔒 Still in quarantine, showing countdown dialog');
        setState(() => _isInQuarantine = true);
        _showQuarantineDialog(context, text);
        return;
      }

      // First time - Show burnout warning (will start quarantine on acknowledgment)
      debugPrint('⚠️ First time, showing burnout warning');
      _showBurnoutWarning(context, text, score);
      return;
    }

    // Normal copy flow
    debugPrint('📋 Normal copy flow');
    if (!mounted) return;

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Response copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boundary Sandbox'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'How to use',
          ),
        ],
      ),
      body: Consumer<MarginProvider>(
        builder: (context, provider, child) {
          final score = provider.currentScore;
          final capacityColor = _getCapacityColor(score?.capacityLevel);

          // Show loading state if score is null
          if (score == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            controller: _responseScrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Margin Score Indicator
                _MarginIndicator(score: score, capacityColor: capacityColor),

                const SizedBox(height: 24),

                // Input Section
                _InputSection(
                  controller: _textController,
                  selectedRelationship: _selectedRelationship,
                  onRelationshipChanged: (rel) {
                    setState(() => _selectedRelationship = rel);
                  },
                  onGenerate: _generateResponses,
                  isGenerating: _isGenerating,
                ),

                // Error Message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ErrorMessage(text: _errorMessage!),
                ],

                // Action Buttons (show after generation)
                if (_responses != null) ...[
                  const SizedBox(height: 32),
                  _ActionButtons(
                    responses: _responses!,
                    selectedAction: _selectedAction,
                    onSelectAction: (action) {
                      setState(() => _selectedAction = action);
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_selectedAction != null)
                    _ResponseDisplay(
                      response: _responses!.getResponse(_selectedAction!),
                      onCopy: _copyResponse,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use Boundary Sandbox'),
        content: const SingleChildScrollView(
          child: ListBody(
            children: [
              Text('1. Paste a demanding request you\'ve received'),
              SizedBox(height: 8),
              Text('2. Select your relationship to the sender'),
              SizedBox(height: 8),
              Text('3. Tap "Generate Responses"'),
              SizedBox(height: 8),
              Text('4. Choose an action to see your AI-generated response'),
              SizedBox(height: 8),
              Text('5. Copy and send!'),
              SizedBox(height: 16),
              Text(
                'Responses adapt based on your current Margin Score '
                'and capacity level.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Color _getCapacityColor(CapacityLevel? level) {
    if (level == null) return Colors.grey;
    switch (level) {
      case CapacityLevel.high:
        return const Color(0xFF4CAF50);
      case CapacityLevel.moderate:
        return const Color(0xFFFFC107);
      case CapacityLevel.depleted:
        return const Color(0xFFFF5722);
    }
  }
}

/// Relationship type enum
enum Relationship {
  boss('Boss', Icons.person_outline),
  peer('Peer', Icons.people_outline),
  friend('Friend', Icons.person_pin),
  family('Family', Icons.family_restroom);

  final String value;
  final IconData icon;

  const Relationship(this.value, this.icon);

  String get label => value;
}

/// Margin Score Indicator Widget
class _MarginIndicator extends StatelessWidget {
  final MarginScore? score;
  final Color capacityColor;

  const _MarginIndicator({required this.score, required this.capacityColor});

  @override
  Widget build(BuildContext context) {
    if (score == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Loading score...')),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.psychology_outlined, color: capacityColor, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Your Capacity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '${score!.finalScore}%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: capacityColor,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: capacityColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      score!.capacityLevel.label,
                      style: TextStyle(
                        color: capacityColor,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Input Section Widget
class _InputSection extends StatelessWidget {
  final TextEditingController controller;
  final Relationship selectedRelationship;
  final ValueChanged<Relationship> onRelationshipChanged;
  final VoidCallback onGenerate;
  final bool isGenerating;

  const _InputSection({
    required this.controller,
    required this.selectedRelationship,
    required this.onRelationshipChanged,
    required this.onGenerate,
    required this.isGenerating,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Paste the request you received:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'e.g., "Can you take on this project by Friday?"',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Who is this from?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: Relationship.values.map((rel) {
                final isSelected = selectedRelationship == rel;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(rel.icon, size: 18),
                      const SizedBox(width: 6),
                      Text(rel.label),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    onRelationshipChanged(rel);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isGenerating ? null : onGenerate,
              icon: isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                isGenerating ? 'Generating...' : 'Generate Responses',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error Message Widget
class _ErrorMessage extends StatelessWidget {
  final String text;

  const _ErrorMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Action Buttons Widget
class _ActionButtons extends StatelessWidget {
  final BoundaryResponses responses;
  final ActionType? selectedAction;
  final ValueChanged<ActionType> onSelectAction;

  const _ActionButtons({
    required this.responses,
    required this.selectedAction,
    required this.onSelectAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choose your response:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: ActionType.values.map((action) {
            final isSelected = selectedAction == action;
            return ActionButton(
              action: action,
              isSelected: isSelected,
              onTap: () => onSelectAction(action),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Individual Action Button
class ActionButton extends StatelessWidget {
  final ActionType action;
  final bool isSelected;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.action,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        foregroundColor: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIconData(action.icon), size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(action.label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'cancel':
        return Icons.cancel;
      case 'handshake':
        return Icons.handshake;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'check_circle':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }
}

/// Response Display Widget
class _ResponseDisplay extends StatelessWidget {
  final String response;
  final ValueChanged<String> onCopy;

  const _ResponseDisplay({required this.response, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Your Response:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                IconButton.filled(
                  onPressed: () => onCopy(response),
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy to clipboard',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            SelectableText(
              response,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
