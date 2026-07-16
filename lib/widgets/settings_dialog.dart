import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../providers/margin_provider.dart';

/// Settings dialog with debug options
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    // Get the provider before showing dialog to avoid scope issues
    final provider = context.read<MarginProvider>();
    return showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: provider,
        child: const SettingsDialog(),
      ),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.settings),
          const SizedBox(width: 12),
          const Text('Settings'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Info Section
            const Text(
              'Margin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Your personal capacity score for setting boundaries.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),

            // Debug Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bug_report_outlined,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Debug Options',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DebugActionButton(
                    label: 'Reset Onboarding',
                    icon: Icons.refresh,
                    color: Colors.orange,
                    description: 'Clear preferences and restart onboarding',
                    onPressed: () async {
                      final confirmed = await _showConfirmDialog(
                        context,
                        'Reset Onboarding?',
                        'This will clear all your preferences and restart the onboarding flow. Continue?',
                      );
                      if (confirmed && context.mounted) {
                        await PreferencesService().clearPreferences();
                        if (context.mounted) {
                          Navigator.of(context).pop(); // Close settings
                          Navigator.of(
                            context,
                          ).pushReplacementNamed('/'); // Restart app
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _DebugActionButton(
                    label: 'Reset Calendar Connection',
                    icon: Icons.calendar_today,
                    color: Colors.blue,
                    description:
                        'Disconnect calendar (keeps other preferences)',
                    onPressed: () async {
                      final confirmed = await _showConfirmDialog(
                        context,
                        'Disconnect Calendar?',
                        'This will disconnect your calendar but keep other preferences.',
                      );
                      if (confirmed && context.mounted) {
                        // Just show a message for now - you'd need to add calendar disconnect logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Calendar connection reset'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // DEV ONLY Section - DELETE BEFORE PRODUCTION
            Builder(
              builder: (dialogContext) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'DEV ONLY - DELETE BEFORE PRODUCTION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Edit wearable data for testing',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Use context from the parent widget tree (outside dialog)
                    _DevWearableDataEditor(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<bool> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _DebugActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String description;
  final VoidCallback onPressed;

  const _DebugActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

/// Dev-only widget for editing wearable data - DELETE BEFORE PRODUCTION
class _DevWearableDataEditor extends StatefulWidget {
  @override
  State<_DevWearableDataEditor> createState() => _DevWearableDataEditorState();
}

class _DevWearableDataEditorState extends State<_DevWearableDataEditor> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MarginProvider>(
      builder: (context, provider, child) {
        // Don't show if loading or no data
        if (provider.isLoading || provider.wearableData == null) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Loading data...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          );
        }

        final data = provider.wearableData!;
        return Column(
          children: [
            _DevSlider(
              label: 'Sleep',
              value: data.sleep,
              min: 0,
              max: 12,
              unit: 'h',
              icon: Icons.bedtime,
              color: Colors.indigo,
              onChanged: (value) {
                provider.updateWearableData(data.copyWith(sleep: value));
              },
            ),
            const SizedBox(height: 8),
            _DevSlider(
              label: 'Energy',
              value: data.energy,
              min: 1,
              max: 10,
              unit: '/10',
              icon: Icons.bolt,
              color: Colors.amber,
              onChanged: (value) {
                provider.updateWearableData(data.copyWith(energy: value));
              },
            ),
            const SizedBox(height: 8),
            _DevSlider(
              label: 'Meetings',
              value: data.meetingLoad,
              min: 0,
              max: 16,
              unit: 'h',
              icon: Icons.event,
              color: Colors.red,
              onChanged: (value) {
                provider.updateWearableData(data.copyWith(meetingLoad: value));
              },
            ),
          ],
        );
      },
    );
  }
}

class _DevSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final IconData icon;
  final Color color;
  final ValueChanged<double> onChanged;

  const _DevSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final valueText = '${value.toStringAsFixed(1)}$unit';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              valueText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.1),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min) > 0 ? (max - min).toInt() : null,
            label: valueText,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
