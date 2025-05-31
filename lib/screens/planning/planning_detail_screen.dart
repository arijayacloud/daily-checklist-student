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
                  const SizedBox(height: 32),
                  _buildActionsSection(
                    context,
                    plannedActivity,
                    activity,
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
                    activity.difficulty,
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
                  activity.environment,
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

  Widget _buildInfoSection(ActivityModel activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informasi Aktivitas'),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInfoItem(
                  icon: Icons.category,
                  title: 'Kesulitan',
                  value: activity.difficulty,
                  color: _getDifficultyColor(activity.difficulty),
                ),
                const Divider(),
                _buildInfoItem(
                  icon: _getEnvironmentIcon(activity.environment),
                  title: 'Lingkungan',
                  value: activity.environment,
                  color: _getEnvironmentColor(activity.environment),
                ),
                const Divider(),
                _buildInfoItem(
                  icon: Icons.child_care,
                  title: 'Rentang Usia',
                  value:
                      '${activity.ageRange.min}-${activity.ageRange.max} tahun',
                  color: Colors.blue,
                ),
                const Divider(),
                _buildInfoItem(
                  icon: Icons.person,
                  title: 'Dibuat Oleh',
                  value: activity.createdBy,
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsSection(ActivityModel activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Langkah-langkah Aktivitas'),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                activity.customSteps.isEmpty
                    ? const Center(
                      child: Text(
                        'Tidak ada langkah khusus untuk aktivitas ini.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          activity.customSteps.map((customStep) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dari guru ${customStep.teacherId}:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...customStep.steps.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final step = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryContainer,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  AppTheme.onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text(step)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                if (customStep != activity.customSteps.last)
                                  const Divider(height: 24),
                              ],
                            );
                          }).toList(),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSection(PlannedActivity plannedActivity) {
    final date = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(plannedActivity.scheduledDate.toDate());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Jadwal'),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInfoItem(
                  icon: Icons.event,
                  title: 'Tanggal',
                  value: date,
                  color: AppTheme.primary,
                ),
                if (plannedActivity.scheduledTime != null) ...[
                  const Divider(),
                  _buildInfoItem(
                    icon: Icons.access_time,
                    title: 'Waktu',
                    value: plannedActivity.scheduledTime!,
                    color: AppTheme.primary,
                  ),
                ],
                const Divider(),
                _buildInfoItem(
                  icon: Icons.notifications,
                  title: 'Pengingat',
                  value: plannedActivity.reminder ? 'Aktif' : 'Tidak aktif',
                  color: plannedActivity.reminder ? Colors.green : Colors.grey,
                ),
              ],
            ),
          ),
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
        _buildSectionTitle('Status'),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color:
                            plannedActivity.completed
                                ? AppTheme.success.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        plannedActivity.completed ? Icons.check : Icons.pending,
                        size: 16,
                        color:
                            plannedActivity.completed
                                ? AppTheme.success
                                : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      plannedActivity.completed ? 'Selesai' : 'Belum Selesai',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            plannedActivity.completed
                                ? AppTheme.success
                                : Colors.orange,
                      ),
                    ),
                  ],
                ),
                // Di sini bisa ditambahkan informasi tambahan seperti
                // siapa yang menyelesaikan, kapan diselesaikan, dll.
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection(
    BuildContext context,
    PlannedActivity plannedActivity,
    ActivityModel activity,
    PlanningProvider planningProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tindakan'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    plannedActivity.completed
                        ? null
                        : () => _markAsCompleted(
                          context,
                          plannedActivity,
                          planningProvider,
                        ),
                icon: Icon(
                  plannedActivity.completed
                      ? Icons.check
                      : Icons.assignment_turned_in,
                ),
                label: Text(
                  plannedActivity.completed
                      ? 'Sudah Selesai'
                      : 'Tandai Selesai',
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.success.withOpacity(0.6),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<ChecklistProvider>(
          builder: (context, checklistProvider, _) {
            return OutlinedButton.icon(
              onPressed: () {
                // Implementasi menambahkan ke checklist
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Menambahkan ke Checklist akan diimplementasikan',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.assignment_add),
              label: const Text('Tambahkan ke Checklist'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.tertiary,
                side: BorderSide(color: AppTheme.tertiary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _markAsCompleted(
    BuildContext context,
    PlannedActivity plannedActivity,
    PlanningProvider planningProvider,
  ) async {
    try {
      await planningProvider.markActivityAsCompleted(
        planId: plannedActivity.planId ?? '',
        activityId: plannedActivity.activityId,
        scheduledDate: plannedActivity.scheduledDate,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktivitas berhasil ditandai selesai'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
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

  IconData _getEnvironmentIcon(String environment) {
    switch (environment) {
      case 'Home':
        return Icons.home;
      case 'School':
        return Icons.school;
      case 'Both':
        return Icons.location_on;
      default:
        return Icons.help_outline;
    }
  }
}
