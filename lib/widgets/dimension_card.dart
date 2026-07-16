import 'package:flutter/material.dart';
import '../services/margin_service.dart' show DimensionValue;
import '../models/feedback.dart';
import 'feedback_dialog.dart';

/// Card widget for displaying a single dimension with feedback option
class DimensionCard extends StatefulWidget {
  final String id;
  final DimensionValue dimension;
  final Function(DimensionFeedback) onFeedback;

  const DimensionCard({
    super.key,
    required this.id,
    required this.dimension,
    required this.onFeedback,
  });

  @override
  State<DimensionCard> createState() => _DimensionCardState();
}

class _DimensionCardState extends State<DimensionCard> {
  bool _showFeedbackButton = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final value = widget.dimension.value;
    final description = widget.dimension.description;
    final needsExpansion = description.length > 40;

    return MouseRegion(
      onEnter: (_) => setState(() => _showFeedbackButton = true),
      onExit: (_) => setState(() => _showFeedbackButton = false),
      child: InkWell(
        onTap: needsExpansion ? () => setState(() => _isExpanded = !_isExpanded) : null,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _getValueColor(value).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getValueColor(value).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIcon(value),
                    color: _getValueColor(value),
                    size: 20,
                  ),
                ),

                const SizedBox(width: 12),

                // Name and value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.dimension.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(value).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getStatus(value),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _getStatusColor(value),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: _isExpanded ? null : 1,
                              overflow: _isExpanded ? null : TextOverflow.ellipsis,
                            ),
                          ),
                          if (needsExpansion && !_isExpanded)
                            Text(
                              '...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w600,
                              ),
                          ),
                          if (needsExpansion)
                            Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: Icon(
                                _isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Value badge with status indicator
                Row(
                  children: [
                    // Status indicator dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getValueColor(value),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Value badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getValueColor(value).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getValueColor(value).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _formatValue(value),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getValueColor(value),
                        ),
                      ),
                    ),
                  ],
                ),

                // Feedback button
                if (_showFeedbackButton) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showFeedbackDialog(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.feedback_outlined,
                          size: 18,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String value) {
    final numValue = double.tryParse(value);
    if (numValue == null) return Colors.grey.shade500;

    if (numValue > 0) return Colors.green.shade600;
    if (numValue < 0) return Colors.orange.shade700;
    return Colors.blue.shade600;
  }

  String _getStatus(String value) {
    // Handle sleep impact quality prefixes
    if (value.contains(':')) {
      final parts = value.split(':');
      if (parts.length >= 2) {
        final quality = parts[0];
        switch (quality) {
          case 'OPTIMAL':
          case 'ADEQUATE':
            return 'Bonus';
          case 'SUBOPTIMAL':
          case 'OVERSLEEP':
          case 'CRITICAL':
            return 'Penalty';
        }
      }
    }

    // Handle meeting load (values like "6.0h")
    if (value.endsWith('h')) {
      final numStr = value.substring(0, value.length - 1);
      final numValue = double.tryParse(numStr);
      if (numValue != null) {
        if (numValue > 8) return 'High';
        if (numValue > 4) return 'Moderate';
        return 'Low';
      }
    }

    final numValue = double.tryParse(value);
    if (numValue == null) return 'Varies';

    if (numValue > 0) return 'Bonus';
    if (numValue < 0) return 'Penalty';
    return 'Baseline';
  }

  Color _getValueColor(String value) {
    // Handle sleep impact quality prefixes
    if (value.contains(':')) {
      final parts = value.split(':');
      if (parts.length >= 2) {
        final quality = parts[0];
        switch (quality) {
          case 'OPTIMAL':
            return Colors.green.shade600;
          case 'ADEQUATE':
            return Colors.amber.shade600;
          case 'SUBOPTIMAL':
            return Colors.orange.shade600;
          case 'OVERSLEEP':
            return Colors.lightBlue.shade600;
          case 'CRITICAL':
            return Colors.red.shade700;
        }
      }
    }

    // Handle meeting load (values like "6.0h")
    if (value.endsWith('h')) {
      final numStr = value.substring(0, value.length - 1);
      final numValue = double.tryParse(numStr);
      if (numValue != null) {
        if (numValue > 8) return Colors.red.shade700;
        if (numValue > 4) return Colors.orange.shade600;
        return Colors.green.shade600;
      }
    }

    final numValue = double.tryParse(value);
    if (numValue == null) return Colors.grey.shade500;

    if (numValue > 0) return Colors.green.shade600;
    if (numValue < 0) return Colors.orange.shade700;
    return Colors.blue.shade600; // Neutral gets blue instead of grey
  }

  IconData _getIcon(String value) {
    // First, check by dimension ID for specific icons
    switch (widget.id) {
      case 'meeting_load':
        return Icons.event_rounded;
      case 'timezone_factor':
        return Icons.public;
      case 'company_size':
        return Icons.business;
      case 'stress_indicators':
        return Icons.psychology_rounded;
      case 'work_life_balance':
        return Icons.balance_rounded;
      case 'day_factor':
        return Icons.today_rounded;
      case 'seasonal_factor':
        return Icons.calendar_month_rounded;
      case 'holiday_factor':
        return Icons.celebration_rounded;
    }

    // Handle sleep impact quality prefixes
    if (value.contains(':')) {
      final parts = value.split(':');
      if (parts.length >= 2) {
        final quality = parts[0];
        switch (quality) {
          case 'OPTIMAL':
            return Icons.bedtime_rounded;
          case 'ADEQUATE':
            return Icons.bedtime_outlined;
          case 'SUBOPTIMAL':
            return Icons.bedtime_outlined;
          case 'OVERSLEEP':
            return Icons.more_time_rounded;
          case 'CRITICAL':
            return Icons.warning_amber_rounded;
        }
      }
    }

    final numValue = double.tryParse(value);
    if (numValue == null) return Icons.info_outline;

    if (numValue > 0) return Icons.add_circle_outline;
    if (numValue < 0) return Icons.remove_circle_outline;
    return Icons.circle_outlined; // More meaningful neutral icon
  }

  String _formatValue(String value) {
    // Handle sleep impact quality prefixes - extract just the numeric value
    if (value.contains(':')) {
      final parts = value.split(':');
      if (parts.length >= 2) {
        final numValue = double.tryParse(parts[1]);
        if (numValue != null) {
          return '${numValue > 0 ? '+' : ''}${parts[1]}';
        }
      }
    }

    final numValue = double.tryParse(value);
    if (numValue == null) return value;
    return '${numValue > 0 ? '+' : ''}$value';
  }

  bool _isAdjustment(String value) {
    final numValue = double.tryParse(value);
    return numValue != null && numValue != 0;
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FeedbackDialog(
        dimensionId: widget.id,
        dimensionName: widget.dimension.name,
        currentValue: widget.dimension.value,
        onSubmit: (feedback) {
          widget.onFeedback(feedback);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Thank you! Your feedback has been applied.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
