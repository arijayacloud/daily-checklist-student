import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '/laravel_api/models/planning_model.dart';
import '/laravel_api/models/user_model.dart';
import '/laravel_api/providers/activity_provider.dart';
import '/laravel_api/providers/planning_provider.dart';
import '/laravel_api/providers/user_provider.dart';
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
      final userProvider = Provider.of<UserProvider>(
        context,
        listen: false,
      );
      
      // Find the plan by ID
      final plan = planningProvider.plans.firstWhere(
        (p) => p.id.toString() == widget.planId,
        orElse: () => Planning(
          id: 0,
          type: 'daily',
          teacherId: '0',
          childId: null,
          startDate: DateTime.now(),
          activities: [],
        ),
      );

      if (plan.id != 0) {
        // Get teacher data
        await userProvider.fetchTeachers();
        final teacherName = userProvider.getTeacherNameById(plan.teacherId);
        if (teacherName != null) {
          setState(() {
            _teacher = UserModel(
              id: plan.teacherId,
              name: teacherName,
              email: '',
              role: 'teacher'
            );
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
          // Find the plan by ID
          final plan = planningProvider.plans.firstWhere(
            (p) => p.id.toString() == widget.planId,
            orElse: () => Planning(
              id: 0,
              type: 'daily',
              teacherId: '0',
              childId: null,
              startDate: DateTime.now(),
              activities: [],
            ),
          );

          if (plan.id == 0) {
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

  Widget _buildPlanningHeader(Planning plan) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
    final startDate = plan.startDate;

    // Calculate end date (7 days after startDate for weekly plan)
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

  Widget _buildActivityList(Planning plan, ActivityProvider activityProvider) {
    if (plan.activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Tidak ada aktivitas dalam perencanaan ini',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Daftar Aktivitas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: plan.activities.length,
          itemBuilder: (context, index) {
            final activity = plan.activities[index];
            final activityDetails = activityProvider.getActivityById(
              activity.activityId.toString()
            );
            
            return _buildActivityItem(activity, activityDetails?.title ?? 'Aktivitas Tidak Ditemukan');
          },
        ),
      ],
    );
  }

  Widget _buildActivityItem(PlannedActivity activity, String title) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
    final formattedDate = dateFormat.format(activity.scheduledDate);
    final formattedTime = activity.scheduledTime ?? 'Tidak diatur';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
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
                    color: activity.completed
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    activity.completed ? 'Selesai' : 'Belum Selesai',
                    style: TextStyle(
                      color: activity.completed ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(formattedDate),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(formattedTime),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  activity.reminder ? Icons.notifications_active : Icons.notifications_off,
                  size: 16,
                  color: activity.reminder ? AppTheme.primary : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  activity.reminder ? 'Pengingat aktif' : 'Pengingat tidak aktif',
                  style: TextStyle(
                    color: activity.reminder ? AppTheme.onSurface : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
