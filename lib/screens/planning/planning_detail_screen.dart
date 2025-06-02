import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/planning_model.dart';
import '/models/activity_model.dart';
import '/providers/activity_provider.dart';
import '/providers/planning_provider.dart';
import '/lib/theme/app_theme.dart';
import '/providers/checklist_provider.dart';
import '/models/user_model.dart';
import '/providers/child_provider.dart';

class PlanningDetailScreen extends StatelessWidget {
  final String planId;
  final String activityId;
  final Timestamp scheduledDate;

  const PlanningDetailScreen({
    Key? key,
    required this.planId,
    required this.activityId,
    required this.scheduledDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Aktivitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Bagikan',
            onPressed: () {
              // Implementasi bagikan aktivitas
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur berbagi akan datang segera'),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<PlanningProvider, ActivityProvider>(
        builder: (context, planningProvider, activityProvider, _) {
          // Ambil detail plan dan aktivitas
          final plan = planningProvider.getPlanById(planId);

          if (plan == null) {
            return const Center(
              child: Text('Data perencanaan tidak ditemukan'),
            );
          }

          // Cari aktivitas dalam plan
          PlannedActivity? plannedActivity;
          for (final activity in plan.activities) {
            if (activity.activityId == activityId &&
                activity.scheduledDate.toDate().day ==
                    scheduledDate.toDate().day) {
              plannedActivity = activity;
              break;
            }
          }

          if (plannedActivity == null) {
            return const Center(
              child: Text('Aktivitas tidak ditemukan dalam perencanaan'),
            );
          }

          // Dapatkan detail aktivitas
          final activity = activityProvider.getActivityById(activityId);

          if (activity == null) {
            return const Center(
              child: Text('Detail aktivitas tidak ditemukan'),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(context, activity, plannedActivity),
                  const SizedBox(height: 24),
                  _buildInfoSection(activity),
                  const SizedBox(height: 24),
                  _buildStepsSection(activity),
                  const SizedBox(height: 24),
                  _buildScheduleSection(plannedActivity),
                  const SizedBox(height: 24),
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
      ),
    );
  }

  Widget _buildHeaderSection(
    BuildContext context,
    ActivityModel activity,
    PlannedActivity plannedActivity,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                  'Usia ${activity.ageRange.min}-${activity.ageRange.max} tahun',
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
        ),
      ),
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

  Widget _buildInfoSection(ActivityModel activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Aktivitas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
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
                  '${activity.ageRange.min}-${activity.ageRange.max} tahun',
                  AppTheme.primary,
                ),
                if (activity.nextActivityId != null) ...[
                  const Divider(),
                  _buildInfoRow(
                    'Aktivitas Lanjutan',
                    'Tersedia',
                    AppTheme.tertiary,
                  ),
                ],
              ],
            ),
          ),
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
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsSection(ActivityModel activity) {
    final steps =
        activity.customSteps.isNotEmpty
            ? activity.customSteps.first.steps
            : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Langkah-langkah Aktivitas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                steps.isEmpty
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Tidak ada langkah yang ditentukan untuk aktivitas ini',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                    : Column(
                      children:
                          steps.asMap().entries.map((entry) {
                            final index = entry.key;
                            final step = entry.value;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: AppTheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      step,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSection(PlannedActivity plannedActivity) {
    final scheduledDate = plannedActivity.scheduledDate.toDate();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detail Jadwal',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildScheduleRow(
                  'Tanggal',
                  DateFormat(
                    'EEEE, d MMMM yyyy',
                    'id_ID',
                  ).format(scheduledDate),
                  AppTheme.primary,
                ),
                const Divider(),
                _buildScheduleRow(
                  'Waktu',
                  plannedActivity.scheduledTime ?? 'Tidak ditentukan',
                  AppTheme.tertiary,
                ),
                const Divider(),
                _buildScheduleRow(
                  'Pengingat',
                  plannedActivity.reminder ? 'Aktif' : 'Tidak Aktif',
                  plannedActivity.reminder ? AppTheme.success : Colors.grey,
                ),
                const Divider(),
                _buildScheduleRow(
                  'Status',
                  plannedActivity.completed ? 'Selesai' : 'Belum Selesai',
                  plannedActivity.completed ? AppTheme.success : Colors.orange,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
          'Status Penyelesaian',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatusIndicator(plannedActivity.completed),
                const SizedBox(height: 16),
                Text(
                  plannedActivity.completed
                      ? 'Aktivitas ini telah diselesaikan'
                      : 'Aktivitas ini belum diselesaikan',
                  style: TextStyle(
                    color:
                        plannedActivity.completed
                            ? AppTheme.success
                            : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(bool completed) {
    return Container(
      width: double.infinity,
      height: 10,
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            flex: completed ? 100 : 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.success,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          Expanded(flex: completed ? 0 : 100, child: Container()),
        ],
      ),
    );
  }

  IconData _getEnvironmentIcon(String environment) {
    switch (environment) {
      case 'Home':
        return Icons.home;
      case 'School':
        return Icons.school;
      case 'Both':
        return Icons.sync;
      default:
        return Icons.location_on;
    }
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
}
