import 'package:flutter/material.dart';
import 'package:daily_checklist_student/laravel_api/models/activity_model.dart';
import 'package:daily_checklist_student/laravel_api/models/checklist_item_model.dart';
import 'package:daily_checklist_student/lib/theme/app_theme.dart';

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
    // Since the Laravel API model doesn't have observation fields directly,
    // we'll just show the general checklist item information
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
            '${activity.minAge}-${activity.maxAge} years',
          ),
          const SizedBox(height: 16),
          
          // Checklist item details
          _buildSectionHeader('Checklist Item'),
          _buildDetailRow('Title:', item.title),
          _buildDetailRow('Description:', item.description),
          _buildDetailRow('Status:', item.completed ? 'Completed' : 'Not Completed'),
          _buildDetailRow('Last Updated:', _formatDate(item.updatedAt)),
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
