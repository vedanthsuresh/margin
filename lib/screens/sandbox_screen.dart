import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/margin_provider.dart';
import '../models/boundary_responses.dart';
import '../models/margin_score.dart';

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

  @override
  void dispose() {
    _textController.dispose();
    _responseScrollController.dispose();
    super.dispose();
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
  void _copyResponse(String text) {
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

          return SingleChildScrollView(
            controller: _responseScrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Margin Score Indicator
                _MarginIndicator(
                  score: score,
                  capacityColor: capacityColor,
                ),

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

  const _MarginIndicator({
    required this.score,
    required this.capacityColor,
  });

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
                Icon(
                  Icons.psychology_outlined,
                  color: capacityColor,
                  size: 32,
                ),
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
              children: [
                Text(
                  '${score!.finalScore}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: capacityColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: capacityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    score!.capacityLevel.label,
                    style: TextStyle(
                      color: capacityColor,
                      fontWeight: FontWeight.w500,
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
            SegmentedButton<Relationship>(
              segments: Relationship.values.map((rel) {
                return ButtonSegment(
                  value: rel,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(rel.icon, size: 18),
                      const SizedBox(width: 6),
                      Text(rel.label),
                    ],
                  ),
                );
              }).toList(),
              selected: {selectedRelationship},
              onSelectionChanged: (Set<Relationship> selected) {
                onRelationshipChanged(selected.first);
              },
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
              label: Text(isGenerating ? 'Generating...' : 'Generate Responses'),
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
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
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
          Text(action.label),
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

  const _ResponseDisplay({
    required this.response,
    required this.onCopy,
  });

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
                Text(
                  'Your Response:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
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
