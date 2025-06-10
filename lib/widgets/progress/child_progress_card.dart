import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/config.dart';
import '/laravel_api/models/child_model.dart';
import '/laravel_api/providers/activity_provider.dart';
import '/widgets/home/laravel_child_avatar.dart';
import '/lib/theme/app_theme.dart';

class ChildProgressCard extends StatelessWidget {
  final ChildModel child;
  final int completedCount;
  final int totalCount;
  final VoidCallback onTap;

  const ChildProgressCard({
    super.key,
    required this.child,
    required this.completedCount,
    required this.totalCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double progressPercentage = totalCount > 0 
        ? (completedCount / totalCount) 
        : 0.0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              LaravelChildAvatar(
                child: child,
                size: 60,
              ),
              const SizedBox(height: 12),
              Text(
                child.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${child.age} tahun',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progressPercentage,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(progressPercentage),
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(
                '$completedCount dari $totalCount aktivitas',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 0.3) {
      return Colors.red;
    } else if (percentage < 0.7) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
