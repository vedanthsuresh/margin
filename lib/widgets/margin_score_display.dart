import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/margin_provider.dart';
import '../models/margin_score.dart';

/// Widget that displays the Margin Score in large bold text with color coding
class MarginScoreDisplay extends StatelessWidget {
  const MarginScoreDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MarginProvider>(
      builder: (context, provider, child) {
        final score = provider.currentScore;
        if (score == null) {
          return const SizedBox.shrink();
        }

        final color = _getScoreColor(score.capacityLevel);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.05),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: color.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              // Score Number
              Text(
                '${score.finalScore}%',
                style: TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -4,
                ),
              ).animate().fade(duration: 300.ms).scale(delay: 100.ms),

              const SizedBox(height: 8),

              // Capacity Level Label
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  score.capacityLevel.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 1,
                  ),
                ),
              ).animate().fade(delay: 200.ms),

              const SizedBox(height: 16),

              // Additional stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStat(context, 'Base', '${score.baseScore.toStringAsFixed(0)}'),
                  Container(
                    height: 20,
                    width: 1,
                    color: color.withOpacity(0.3),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  _buildStat(context, 'Adjusted', '${score.enrichedScore.toStringAsFixed(0)}'),
                ],
              ).animate().fade(delay: 300.ms),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(CapacityLevel level) {
    switch (level) {
      case CapacityLevel.high:
        return const Color(0xFF4CAF50); // Green
      case CapacityLevel.moderate:
        return const Color(0xFFFFC107); // Yellow/Amber
      case CapacityLevel.depleted:
        return const Color(0xFFFF5722); // Orange/Red
    }
  }
}
