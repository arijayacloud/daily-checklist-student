import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/planning_model.dart';
import '/models/activity_model.dart';
import '/models/user_model.dart';
import '/providers/activity_provider.dart';
import '/providers/planning_provider.dart';
import '/lib/theme/app_theme.dart';

class ParentPlanningDetailScreen extends StatefulWidget {
  final String planId;
  static const routeName = '/parent-planning-detail';

  const ParentPlanningDetailScreen({Key? key, required this.planId})
    : super(key: key);

  @override
  State<ParentPlanningDetailScreen> createState() =>
      _ParentPlanningDetailScreenState();
}

class _ParentPlanningDetailScreenState
    extends State<ParentPlanningDetailScreen> {
  UserModel? _teacher;
  bool _isLoadingTeacher = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    setState(() {
      _isLoadingTeacher = true;
    });

    try {
      final planningProvider = Provider.of<PlanningProvider>(
        context,
        listen: false,
      );
      final plan = planningProvider.getPlanById(widget.planId);

      if (plan != null) {
        final teacherId = plan.teacherId;
        final teacherSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(teacherId)
                .get();

        if (teacherSnapshot.exists) {
          setState(() {
            _teacher = UserModel.fromJson({
              'id': teacherSnapshot.id,
              ...teacherSnapshot.data() as Map<String, dynamic>,
            });
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading teacher data: $e');
    } finally {
      setState(() {
        _isLoadingTeacher = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Perencanaan'), elevation: 0),
      body: Consumer2<PlanningProvider, ActivityProvider>(
        builder: (context, planningProvider, activityProvider, _) {
          final plan = planningProvider.getPlanById(widget.planId);

          if (plan == null) {
            return const Center(
              child: Text('Data perencanaan tidak ditemukan'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTeacherInfo(),
                _buildPlanningHeader(plan),
                _buildActivityList(plan, activityProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeacherInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primary.withOpacity(0.1),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primary,
            radius: 24,
            child: Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child:
                _isLoadingTeacher
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dibuat oleh:',
                          style: TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _teacher?.name ?? 'Guru',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanningHeader(PlanningModel plan) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
    final startDate = plan.startDate.toDate();

    // Hitung tanggal akhir (7 hari setelah startDate untuk weekly plan)
    final endDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day + (plan.type == 'weekly' ? 6 : 0),
    );

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  plan.type == 'weekly' ? Icons.date_range : Icons.today,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  plan.type == 'weekly'
                      ? 'Perencanaan Mingguan'
                      : 'Perencanaan Harian',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                plan.type == 'weekly'
                    ? '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}'
                    : dateFormat.format(startDate),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Aktivitas: ${plan.activities.length}',
              style: TextStyle(fontSize: 16, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value:
                  plan.activities.isEmpty
                      ? 0
                      : plan.activities
                              .where((activity) => activity.completed)
                              .length /
                          plan.activities.length,
              backgroundColor: AppTheme.surfaceVariant.withOpacity(0.5),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Text(
              'Selesai: ${plan.activities.where((activity) => activity.completed).length} dari ${plan.activities.length}',
              style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(
    PlanningModel plan,
    ActivityProvider activityProvider,
  ) {
    final dateFormat = DateFormat('EEEE, dd MMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm', 'id_ID');

    // Kelompokkan aktivitas berdasarkan tanggal
    final Map<String, List<PlannedActivity>> groupedActivities = {};

    for (final activity in plan.activities) {
      final date = dateFormat.format(activity.scheduledDate.toDate());
      if (!groupedActivities.containsKey(date)) {
        groupedActivities[date] = [];
      }
      groupedActivities[date]!.add(activity);
    }

    // Urutkan tanggal
    final sortedDates =
        groupedActivities.keys.toList()..sort((a, b) {
          final dateA = DateFormat('EEEE, dd MMM yyyy', 'id_ID').parse(a);
          final dateB = DateFormat('EEEE, dd MMM yyyy', 'id_ID').parse(b);
          return dateA.compareTo(dateB);
        });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daftar Aktivitas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...sortedDates.map((date) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    date,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...groupedActivities[date]!.map((plannedActivity) {
                  final activity = activityProvider.getActivityById(
                    plannedActivity.activityId,
                  );

                  if (activity == null) {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activity.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        plannedActivity.completed
                                            ? AppTheme.success
                                            : AppTheme.onSurface,
                                    decoration:
                                        plannedActivity.completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      plannedActivity.completed
                                          ? AppTheme.success.withOpacity(0.2)
                                          : AppTheme.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  plannedActivity.completed
                                      ? 'Selesai'
                                      : 'Belum Selesai',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        plannedActivity.completed
                                            ? AppTheme.success
                                            : AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (plannedActivity.scheduledTime != null &&
                              plannedActivity.scheduledTime!.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  plannedActivity.scheduledTime!,
                                  style: TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Text(
                            activity.description,
                            style: TextStyle(color: AppTheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                _getEnvironmentIcon(activity.environment),
                                size: 16,
                                color: _getEnvironmentColor(
                                  activity.environment,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _translateEnvironmentToIndonesian(
                                  activity.environment,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getEnvironmentColor(
                                    activity.environment,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.bar_chart,
                                size: 16,
                                color: _getDifficultyColor(activity.difficulty),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _translateDifficultyToIndonesian(
                                  activity.difficulty,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getDifficultyColor(
                                    activity.difficulty,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  IconData _getEnvironmentIcon(String environment) {
    switch (environment) {
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'both':
        return Icons.home_work;
      default:
        return Icons.location_on;
    }
  }

  Color _getEnvironmentColor(String environment) {
    switch (environment) {
      case 'home':
        return Colors.green;
      case 'school':
        return Colors.blue;
      case 'both':
        return Colors.purple;
      default:
        return AppTheme.onSurfaceVariant;
    }
  }

  String _translateEnvironmentToIndonesian(String environment) {
    switch (environment) {
      case 'home':
        return 'Rumah';
      case 'school':
        return 'Sekolah';
      case 'both':
        return 'Keduanya';
      default:
        return 'Tidak Diketahui';
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return AppTheme.onSurfaceVariant;
    }
  }

  String _translateDifficultyToIndonesian(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'Mudah';
      case 'medium':
        return 'Sedang';
      case 'hard':
        return 'Sulit';
      default:
        return 'Tidak Diketahui';
    }
  }
}
