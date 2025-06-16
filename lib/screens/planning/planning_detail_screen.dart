import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '/laravel_api/models/planning_model.dart';
import '/laravel_api/models/activity_model.dart';
import '/laravel_api/models/child_model.dart';
import '/laravel_api/providers/activity_provider.dart';
import '/laravel_api/providers/planning_provider.dart';
import '/laravel_api/providers/child_provider.dart';
import '/lib/theme/app_theme.dart';
import '/laravel_api/providers/user_provider.dart';

class PlanningDetailScreen extends StatefulWidget {
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
  State<PlanningDetailScreen> createState() => _PlanningDetailScreenState();
}

class _PlanningDetailScreenState extends State<PlanningDetailScreen> {
  bool _showActivities = true;
  bool _showChildren = false;
  int? _updatingActivityId;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // We'll load data more efficiently in didChangeDependencies
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Only fetch data once when the widget builds for the first time
    if (!_isInitialized) {
      _isInitialized = true;
      
      // Fetch children data which is needed for the UI
      final childProvider = Provider.of<ChildProvider>(context, listen: false);
      if (childProvider.children.isEmpty) {
        childProvider.fetchChildren();
      }
      
      // We'll avoid loading all teachers immediately to improve performance
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detail Perencanaan'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () {
                // Selective refresh to avoid excessive data loading
                final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
                planningProvider.fetchPlans();
                
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(
                    content: Text('Memuat ulang data...'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer2<PlanningProvider, ChildProvider>(
          builder: (context, planningProvider, childProvider, _) {
            // Ambil detail plan
            final plan = planningProvider.plans.firstWhere(
              (p) => p.id == widget.planId, 
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

            if (widget.activities.isEmpty) {
              return const Center(
                child: Text('Tidak ada aktivitas dalam perencanaan'),
              );
            }

            // Get children names
            List<ChildModel> selectedChildren = [];
            if (plan.childIds.isNotEmpty) {
              selectedChildren = childProvider.children
                  .where((child) => plan.childIds.contains(child.id))
                  .toList();
            }

            // Group activities by date
            final Map<String, List<PlannedActivity>> activitiesByDate = {};
            for (var activity in widget.activities) {
              final dateKey = DateFormat('yyyy-MM-dd').format(activity.scheduledDate);
              if (!activitiesByDate.containsKey(dateKey)) {
                activitiesByDate[dateKey] = [];
              }
              activitiesByDate[dateKey]!.add(activity);
            }
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlanHeader(plan),
                  const SizedBox(height: 16),
                  _buildChildrenSection(selectedChildren),
                  const SizedBox(height: 16),
                  _buildActivitiesSection(activitiesByDate, planningProvider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlanHeader(Planning plan) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    plan.type == 'daily' ? 'Harian' : 'Mingguan',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                // Only load teacher info if needed, with a separate Consumer
                // This avoids making a request for all teachers
                Icon(Icons.person, size: 16, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    // Only fetch this specific teacher if needed
                    if (plan.teacherId != '0') {
                      final teacherName = userProvider.getTeacherNameById(plan.teacherId);
                      // If teacher name is null, fetch it - but avoid fetching all teachers
                      if (teacherName == null) {
                        Future.microtask(() => userProvider.getUserById(plan.teacherId));
                        return const Text('Memuat...', style: TextStyle(fontSize: 14, color: Colors.grey));
                      }
                      return Text(
                        'Dibuat oleh $teacherName',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      );
                    }
                    return Text(
                      'Dibuat oleh Guru',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Periode Perencanaan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            if (plan.type == 'daily')
              _buildDateRow(plan.startDate)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateRow(plan.startDate, label: 'Mulai:'),
                  const SizedBox(height: 4),
                  _buildDateRow(
                    plan.startDate.add(const Duration(days: 6)),
                    label: 'Selesai:'
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.playlist_add_check,
                  color: AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.activities.length} aktivitas dijadwalkan',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.activities.where((a) => a.completed).length} aktivitas selesai',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDateRow(DateTime date, {String? label}) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 20,
          color: AppTheme.primary,
        ),
        const SizedBox(width: 8),
        if (label != null) 
          Text(
            label,
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        if (label != null) const SizedBox(width: 4),
        Text(
          DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildChildrenSection(List<ChildModel> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showChildren = !_showChildren;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.people_alt,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Anak',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          children.isEmpty
                              ? 'Semua anak'
                              : '${children.length} anak dipilih',
                          style: TextStyle(color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showChildren ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_showChildren) const Divider(height: 1),
          if (_showChildren)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: children.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.groups,
                            color: AppTheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Perencanaan ini dibuat untuk semua anak',
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: children.map((child) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryContainer,
                            child: Text(
                              child.name.substring(0, 1),
                              style: TextStyle(
                                color: AppTheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(child.name),
                          subtitle: Text('${child.age} tahun'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildActivitiesSection(
    Map<String, List<PlannedActivity>> activitiesByDate,
    PlanningProvider planningProvider,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showActivities = !_showActivities;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.event_note,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aktivitas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.activities.length} aktivitas dijadwalkan',
                          style: TextStyle(color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showActivities ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_showActivities) const Divider(height: 1),
          if (_showActivities)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: activitiesByDate.entries.map((entry) {
                  final dateKey = entry.key;
                  final activitiesForDate = entry.value;
                  final date = DateFormat('yyyy-MM-dd').parse(dateKey);
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...activitiesForDate.map((activity) {
                        return Consumer<ActivityProvider>(
                          builder: (context, activityProvider, child) {
                            return _buildActivityItem(
                              activity,
                              activityProvider,
                              planningProvider,
                            );
                          },
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildActivityItem(
    PlannedActivity activity, 
    ActivityProvider activityProvider, 
    PlanningProvider planningProvider
  ) {
    final activityDetails = activityProvider.getActivityById(
      activity.activityId.toString()
    );
    
    final bool isUpdating = _updatingActivityId == activity.id;
    
    if (activityDetails == null) {
      return const ListTile(
        title: Text('Detail aktivitas tidak ditemukan'),
      );
    }
    
    return InkWell(
      onTap: () {
        _showActivityDetails(activity, activityDetails, planningProvider);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: activity.completed 
              ? Colors.green.shade50 
              : AppTheme.surfaceVariant.withOpacity(0.3),
          border: Border.all(
            color: activity.completed 
                ? Colors.green.withOpacity(0.5) 
                : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: activity.completed ? Colors.green : AppTheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activityDetails.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: activity.completed 
                          ? TextDecoration.lineThrough 
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activity.scheduledTime ?? 'Tidak diatur',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        _getEnvironmentIcon(activityDetails.environment),
                        size: 14,
                        color: _getEnvironmentColor(activityDetails.environment),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _translateEnvironmentToIndonesian(activityDetails.environment),
                        style: TextStyle(
                          color: _getEnvironmentColor(activityDetails.environment),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Checkbox(
              value: activity.completed,
              onChanged: isUpdating 
                  ? null // Disable while updating
                  : (value) async {
                if (activity.id == null) return;
                
                try {
                  setState(() {
                    _updatingActivityId = activity.id;
                  });
                  
                  await planningProvider.markActivityAsCompleted(
                    activity.id!,
                    value ?? false,
                  );
                  
                  if (mounted) {
                    setState(() {
                      _updatingActivityId = null;
                    });
                  }
                } catch (e) {
                  if (!mounted) return;
                  setState(() {
                    _updatingActivityId = null;
                  });
                  _scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: Text('Gagal mengubah status: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showActivityDetails(
    PlannedActivity plannedActivity,
    ActivityModel activity,
    PlanningProvider planningProvider,
  ) {
    // Add loading state variable
    bool isUpdating = false;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Header
                      Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Overview
                      _buildDetailRow(
                        'Deskripsi',
                        activity.description,
                        multiLine: true,
                      ),
                      const Divider(height: 24),
                      
                      // Info row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailInfo(
                              'Lingkungan',
                              _translateEnvironmentToIndonesian(activity.environment),
                              _getEnvironmentIcon(activity.environment),
                              _getEnvironmentColor(activity.environment),
                            ),
                          ),
                          Expanded(
                            child: _buildDetailInfo(
                              'Kesulitan',
                              _translateDifficultyToIndonesian(activity.difficulty),
                              _getDifficultyIcon(activity.difficulty),
                              _getDifficultyColor(activity.difficulty),
                            ),
                          ),
                          Expanded(
                            child: _buildDetailInfo(
                              'Usia',
                              '${activity.minAge}-${activity.maxAge}',
                              Icons.child_care,
                              AppTheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                      
                      const Divider(height: 24),
                      
                      // Jadwal
                      _buildDetailRow(
                        'Tanggal',
                        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(plannedActivity.scheduledDate),
                        icon: Icons.calendar_today,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Waktu',
                        plannedActivity.scheduledTime ?? 'Tidak diatur',
                        icon: Icons.access_time,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Pengingat',
                        plannedActivity.reminder ? 'Aktif' : 'Nonaktif',
                        icon: Icons.notifications,
                      ),
                      
                      const Divider(height: 24),
                      
                      // Langkah-langkah
                      const Text(
                        'Langkah-langkah Aktivitas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (activity.activitySteps.isEmpty || activity.activitySteps.first.steps.isEmpty)
                        const Text('Tidak ada langkah-langkah untuk aktivitas ini',
                            style: TextStyle(fontStyle: FontStyle.italic))
                      else
                        ...activity.activitySteps.first.steps.asMap().entries.map((entry) {
                          final index = entry.key;
                          final step = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppTheme.primaryContainer,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: AppTheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(step)),
                              ],
                            ),
                          );
                        }),
                      
                      const SizedBox(height: 24),
                      
                      // Action button
                      ElevatedButton.icon(
                        onPressed: plannedActivity.completed || isUpdating
                            ? null
                            : () async {
                                if (plannedActivity.id == null) return;
                                
                                try {
                                  setModalState(() {
                                    isUpdating = true;
                                  });
                                  
                                  await planningProvider.markActivityAsCompleted(
                                    plannedActivity.id!,
                                    true,
                                  );
                                  if (mounted) {
                                    Navigator.pop(context);
                                    setState(() {}); // Refresh parent widget
                                  }
                                } catch (e) {
                                  setModalState(() {
                                    isUpdating = false;
                                  });
                                  
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                  _scaffoldMessengerKey.currentState?.showSnackBar(
                                    SnackBar(
                                      content: Text('Gagal menandai aktivitas: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        icon: isUpdating
                            ? Container(
                                width: 24,
                                height: 24,
                                padding: const EdgeInsets.all(2.0),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Icon(
                                plannedActivity.completed
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                              ),
                        label: Text(
                          isUpdating
                              ? 'Memproses...'
                              : (plannedActivity.completed
                                  ? 'Sudah Selesai'
                                  : 'Tandai Selesai'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: plannedActivity.completed
                              ? Colors.green.withOpacity(0.7)
                              : AppTheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.green.withOpacity(0.7),
                          disabledForegroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  
  Widget _buildDetailRow(String label, String value, {IconData? icon, bool multiLine = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailInfo(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  
  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Icons.sentiment_satisfied;
      case 'Medium':
        return Icons.sentiment_neutral;
      case 'Hard':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.category;
    }
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