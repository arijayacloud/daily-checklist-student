import 'package:flutter/material.dart';
import '/models/activity_model.dart';
import '/models/checklist_item_model.dart';
import '/lib/theme/app_theme.dart';

class ActivityDetailCard extends StatelessWidget {
  final ActivityModel activity;
  final ChecklistItemModel item;

  const ActivityDetailCard({
    super.key,
    required this.activity,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final homeObservation = item.homeObservation;
    final schoolObservation = item.schoolObservation;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            activity.description,
            style: TextStyle(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Activity details
          _buildDetailRow('Difficulty:', activity.difficulty),
          _buildDetailRow('Environment:', activity.environment),
          _buildDetailRow(
            'Age Range:',
            '${activity.ageRange.min}-${activity.ageRange.max} years',
          ),
          const SizedBox(height: 16),

          // Home observation
          if (homeObservation.completed) ...[
            _buildSectionHeader('Home Observation'),
            if (homeObservation.completedAt != null)
              _buildDetailRow(
                'Completed on:',
                _formatDate(homeObservation.completedAt!.toDate()),
              ),
            if (homeObservation.duration != null)
              _buildDetailRow(
                'Duration:',
                '${homeObservation.duration} minutes',
              ),
            if (homeObservation.engagement != null)
              _buildDetailRow(
                'Engagement:',
                _getStarRating(homeObservation.engagement!),
              ),
            if (homeObservation.notes != null &&
                homeObservation.notes!.isNotEmpty)
              _buildDetailRow('Notes:', homeObservation.notes!),
            const SizedBox(height: 16),
          ],

          // School observation
          if (schoolObservation.completed) ...[
            _buildSectionHeader('School Observation'),
            if (schoolObservation.completedAt != null)
              _buildDetailRow(
                'Completed on:',
                _formatDate(schoolObservation.completedAt!.toDate()),
              ),
            if (schoolObservation.duration != null)
              _buildDetailRow(
                'Duration:',
                '${schoolObservation.duration} minutes',
              ),
            if (schoolObservation.engagement != null)
              _buildDetailRow(
                'Engagement:',
                _getStarRating(schoolObservation.engagement!),
              ),
            if (schoolObservation.notes != null &&
                schoolObservation.notes!.isNotEmpty)
              _buildDetailRow('Notes:', schoolObservation.notes!),
            if (schoolObservation.learningOutcomes != null &&
                schoolObservation.learningOutcomes!.isNotEmpty)
              _buildDetailRow(
                'Learning Outcomes:',
                schoolObservation.learningOutcomes!,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getStarRating(int rating) {
    return List.filled(rating, '⭐').join(' ');
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
