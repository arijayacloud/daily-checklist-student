import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '/laravel_api/models/planning_model.dart';
import '/laravel_api/models/activity_model.dart';
import '/laravel_api/providers/activity_provider.dart';
import '/laravel_api/providers/planning_provider.dart';
import '/lib/theme/app_theme.dart';
import '/laravel_api/providers/user_provider.dart';

class PlanningDetailScreen extends StatelessWidget {
  final int planId;
  final List<PlannedActivity> activities;
  final DateTime selectedDate;

  const PlanningDetailScreen({
    Key? key,
    required this.planId,
    required this.activities,
    required this.selectedDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Memastikan data guru dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchTeachers();
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Aktivitas')),
      body: Consumer2<PlanningProvider, ActivityProvider>(
        builder: (context, planningProvider, activityProvider, _) {
          // Ambil detail plan
          final plan = planningProvider.plans.firstWhere(
            (p) => p.id == planId, 
            orElse: () => Planning(
              id: 0,
              type: 'daily',
              teacherId: '0',
              childId: null,
              startDate: DateTime.now(),
              activities: [],
            )
          );

          if (plan.id == 0) {
            return const Center(
              child: Text('Data perencanaan tidak ditemukan'),
            );
          }

          if (activities.isEmpty) {
            return const Center(
              child: Text('Tidak ada aktivitas dalam perencanaan'),
            );
          }

          return ListView.builder(
            itemCount: activities.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, index) {
              final plannedActivity = activities[index];
              
              // Dapatkan detail aktivitas
              final activity = activityProvider.getActivityById(
                plannedActivity.activityId.toString()
              );

              if (activity == null) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Detail aktivitas tidak ditemukan'),
                  ),
                );
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(context, activity, plannedActivity),
                      const SizedBox(height: 16),
                      _buildInfoSection(activity),
                      const SizedBox(height: 16),
                      _buildStepsSection(activity),
                      const SizedBox(height: 16),
                      _buildScheduleSection(plannedActivity),
                      const SizedBox(height: 16),
                      _buildStatusSection(
                        context,
                        plannedActivity,
                        planningProvider,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(
    BuildContext context,
    ActivityModel activity,
    PlannedActivity plannedActivity,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                activity.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _getDifficultyColor(
                  activity.difficulty,
                ).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _translateDifficultyToIndonesian(activity.difficulty),
                style: TextStyle(
                  color: _getDifficultyColor(activity.difficulty),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              _getEnvironmentIcon(activity.environment),
              color: _getEnvironmentColor(activity.environment),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _translateEnvironmentToIndonesian(activity.environment),
              style: TextStyle(
                color: _getEnvironmentColor(activity.environment),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.calendar_today,
              color: AppTheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Usia ${activity.minAge}-${activity.maxAge} tahun',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          activity.description,
          style: TextStyle(fontSize: 16, color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }

  String _translateDifficultyToIndonesian(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return 'Mudah';
      case 'Medium':
        return 'Sedang';
      case 'Hard':
        return 'Sulit';
      default:
        return difficulty;
    }
  }

  String _translateEnvironmentToIndonesian(String environment) {
    switch (environment) {
      case 'Home':
        return 'Rumah';
      case 'School':
        return 'Sekolah';
      case 'Both':
        return 'Keduanya';
      default:
        return environment;
    }
  }

  IconData _getEnvironmentIcon(String environment) {
    switch (environment) {
      case 'Home':
        return Icons.home;
      case 'School':
        return Icons.school;
      case 'Both':
        return Icons.merge_type;
      default:
        return Icons.category;
    }
  }

  Widget _buildInfoSection(ActivityModel activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Aktivitas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            _buildInfoRow(
              'Tingkat Kesulitan',
              _translateDifficultyToIndonesian(activity.difficulty),
              _getDifficultyColor(activity.difficulty),
            ),
            const Divider(),
            _buildInfoRow(
              'Lingkungan',
              _translateEnvironmentToIndonesian(activity.environment),
              _getEnvironmentColor(activity.environment),
            ),
            const Divider(),
            _buildInfoRow(
              'Rentang Usia',
              '${activity.minAge}-${activity.maxAge} tahun',
              AppTheme.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsSection(ActivityModel activity) {
    List<String> steps = [];
    
    if (activity.activitySteps.isNotEmpty) {
      steps = activity.activitySteps.first.steps;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Langkah-langkah Aktivitas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        steps.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Tidak ada langkah-langkah untuk aktivitas ini',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryContainer,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: AppTheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(steps[index]),
              );
            },
          ),
      ],
    );
  }

  Widget _buildScheduleSection(PlannedActivity plannedActivity) {
    final formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID')
        .format(plannedActivity.scheduledDate);
    final time = plannedActivity.scheduledTime ?? 'Tidak diatur';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jadwal',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.calendar_today, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.access_time, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              time,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.notifications, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              plannedActivity.reminder
                  ? 'Pengingat aktif'
                  : 'Pengingat tidak aktif',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection(
    BuildContext context,
    PlannedActivity plannedActivity,
    PlanningProvider planningProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: plannedActivity.completed
                    ? null
                    : () => _markActivityAsCompleted(
                          context,
                          plannedActivity,
                          planningProvider,
                        ),
                icon: Icon(
                  plannedActivity.completed
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                ),
                label: Text(
                  plannedActivity.completed
                      ? 'Sudah Selesai'
                      : 'Tandai Selesai',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: plannedActivity.completed
                      ? Colors.green.withOpacity(0.7)
                      : AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.green.withOpacity(0.7),
                  disabledForegroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        if (plannedActivity.completed)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Aktivitas ini telah diselesaikan',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getEnvironmentColor(String environment) {
    switch (environment) {
      case 'Home':
        return Colors.purple;
      case 'School':
        return Colors.blue;
      case 'Both':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _markActivityAsCompleted(
    BuildContext context,
    PlannedActivity plannedActivity,
    PlanningProvider planningProvider,
  ) async {
    if (plannedActivity.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat menemukan ID aktivitas')),
      );
      return;
    }

    try {
      await planningProvider.markActivityAsCompleted(
        plannedActivity.id!,
        true,
      );
      
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aktivitas telah diselesaikan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menandai aktivitas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
