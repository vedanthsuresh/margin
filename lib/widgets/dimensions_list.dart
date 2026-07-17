import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/margin_provider.dart';
import '../services/margin_service.dart' show DimensionCategory;
import 'dimension_card.dart';

/// List of all dimensions that affect the Margin Score
class DimensionsList extends StatefulWidget {
  const DimensionsList({super.key});

  @override
  State<DimensionsList> createState() => _DimensionsListState();
}

class _DimensionsListState extends State<DimensionsList> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MarginProvider>(
      builder: (context, provider, child) {
        final dimensions = provider.dimensions;

        if (dimensions == null || dimensions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No dimensions available'),
          );
        }

        // Group dimensions by category
        final temporalDimensions = dimensions.entries
            .where((e) => e.value.category == DimensionCategory.temporal)
            .toList();

        final professionalDimensions = dimensions.entries
            .where((e) => e.value.category == DimensionCategory.professional)
            .toList();

        final personalDimensions = dimensions.entries
            .where((e) => e.value.category == DimensionCategory.personal)
            .toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Temporal Factors
              if (temporalDimensions.isNotEmpty) ...[
                const _SectionHeader(title: 'Time-Based Factors'),
                const SizedBox(height: 8),
                ...temporalDimensions.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DimensionCard(
                      id: entry.key,
                      dimension: entry.value,
                      onFeedback: (feedback) async {
                        await provider.submitFeedback(feedback);
                      },
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Professional Factors
              if (professionalDimensions.isNotEmpty) ...[
                const _SectionHeader(title: 'Professional Factors'),
                const SizedBox(height: 8),
                ...professionalDimensions.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DimensionCard(
                      id: entry.key,
                      dimension: entry.value,
                      onFeedback: (feedback) async {
                        await provider.submitFeedback(feedback);
                      },
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Personal Factors
              if (personalDimensions.isNotEmpty) ...[
                const _SectionHeader(title: 'Personal Factors'),
                const SizedBox(height: 8),
                ...personalDimensions.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DimensionCard(
                      id: entry.key,
                      dimension: entry.value,
                      onFeedback: (feedback) async {
                        await provider.submitFeedback(feedback);
                      },
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
