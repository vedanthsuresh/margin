import 'package:flutter/material.dart';
import '../models/feedback.dart';

/// Dialog for collecting user feedback on a dimension
class FeedbackDialog extends StatefulWidget {
  final String dimensionId;
  final String dimensionName;
  final String currentValue;
  final Function(DimensionFeedback) onSubmit;

  const FeedbackDialog({
    super.key,
    required this.dimensionId,
    required this.dimensionName,
    required this.currentValue,
    required this.onSubmit,
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _quickReasons = [
    'This doesn\'t match how I feel today',
    'I have more capacity than this shows',
    'I have less capacity than this shows',
    'This factor doesn\'t apply to me',
    'Other reason...',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for your feedback'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final feedback = DimensionFeedback(
      dimensionId: widget.dimensionId,
      dimensionName: widget.dimensionName,
      currentValue: widget.currentValue,
      reason: _reasonController.text.trim(),
      timestamp: DateTime.now(),
    );

    widget.onSubmit(feedback);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.feedback_outlined, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Feedback on ${widget.dimensionName}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current value display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    'Current value: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    widget.currentValue,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick reason buttons
            const Text(
              'Quick reasons:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickReasons.map((reason) {
                return OutlinedButton(
                  onPressed: () {
                    _reasonController.text = reason;
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    reason,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Custom reason input
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Your reason (required)',
                hintText: 'Tell us why this factor seems off...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 8),

            // Info text
            Text(
              'Your feedback will adjust this factor and recalculate your Margin Score.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitFeedback,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Feedback'),
        ),
      ],
    );
  }
}
