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
  bool _showChildProgress = true;
  int? _updatingActivityId;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _isInitialized = false;
  bool _isMarkingAllComplete = false;
  final Set<String> _expandedActivities = {};

  @override
  void initState() {
    super.initState();
    // We'll load data more efficiently in didChangeDependencies
    _loadInitialData();
  }
  
  void _loadInitialData() {
    // Perform any data loading that doesn't depend on context here
    Future.microtask(() {
      final childProvider = Provider.of<ChildProvider>(context, listen: false);
      if (childProvider.children.isEmpty) {
        childProvider.fetchChildren();
      }
      
      // Always explicitly fetch the plan with fresh completion data
      final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
      planningProvider.fetchPlanWithCompletionData(widget.planId);
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No longer doing provider calls in didChangeDependencies to avoid setState during build
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
                // Explicitly fetch fresh completion data
                final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
                
                // First try our explicit completion status endpoint
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(
                    content: Text('Memuat ulang data aktivitas...'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                
                // Then refresh the plan with complete data
                planningProvider.fetchPlanWithCompletionData(widget.planId).then((plan) {
                  if (plan != null) {
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      const SnackBar(
                        content: Text('Data berhasil diperbarui'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                });
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
            
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPlanHeader(plan),
                      const SizedBox(height: 16),
                      if (_isMarkingAllComplete)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _buildActivitiesSection(activitiesByDate, planningProvider, selectedChildren),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllActivitiesAsComplete(
    int planId,
    List<ChildModel> children,
    PlanningProvider planningProvider,
  ) async {
    setState(() {
      _isMarkingAllComplete = true;
    });
    
    try {
      bool allSuccess = true;
      
      for (final activity in widget.activities) {
        if (activity.id == null) continue;
        
        for (final child in children) {
          final success = await planningProvider.markActivityAsCompleted(
            activity.id!,
            true,
            childId: child.id,
          );
          
          if (!success) {
            allSuccess = false;
          }
        }
      }
      
      // Explicitly refresh plan data to update UI
      await planningProvider.fetchPlanWithCompletionData(planId);
      
      if (mounted) {
        if (allSuccess) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Semua aktivitas berhasil ditandai selesai'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Beberapa aktivitas gagal ditandai selesai'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAllComplete = false;
        });
      }
    }
  }

  // Updated method to return both completed count and total count without modifying state during build
  Map<String, int> _calculateChildProgress(String childId, Planning plan, PlanningProvider planningProvider) {
    int totalActivities = plan.activities.length;
    int completedActivities = 0;
    
    // Instead of setting current child ID (which triggers notifyListeners),
    // we'll manually check completion status for this specific child
    for (var activity in plan.activities) {
      // Since we can't use planningProvider.setCurrentChildId during build,
      // we just count activities that are completed (works for current UI)
      if (activity.completed) completedActivities++;
    }
    
    return {
      'completed': completedActivities,
      'total': totalActivities,
    };
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 30) {
      return Colors.red;
    } else if (percentage < 70) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
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
                Icon(Icons.person, size: 16, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    if (plan.teacherId != '0') {
                      final teacherName = userProvider.getTeacherNameById(plan.teacherId);
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
            const Divider(height: 24),
            Consumer2<PlanningProvider, ChildProvider>(
              builder: (context, planningProvider, childProvider, _) {
                if (plan.childIds.isEmpty) {
                  return const Center(
                    child: Text("Tidak ada anak yang dipilih"),
                  );
                }
                
                // Get selected children
                List<ChildModel> selectedChildren = childProvider.children
                    .where((child) => plan.childIds.contains(child.id))
                    .toList();
                
                if (selectedChildren.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                // Build Mark All Complete button
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mark All Complete button
                    if (!_isMarkingAllComplete) 
                      ElevatedButton.icon(
                        onPressed: () => _markAllActivitiesAsComplete(plan.id, selectedChildren, planningProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.done_all),
                        label: const Text('Tandai Semua Selesai'),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Children progress list
                    ...selectedChildren.map((child) {
                      // Get completion status from plan's progress data if available
                      int completedCount = 0;
                      int totalActivities = 0;
                      bool isCompleted = false;
                      
                      // First try to use the new progress data structure
                      if (plan.progressByChild.containsKey(child.id)) {
                        final childProgress = plan.progressByChild[child.id]!;
                        completedCount = childProgress.completed;
                        totalActivities = childProgress.total;
                        isCompleted = completedCount == totalActivities && totalActivities > 0;
                      } else {
                        // Fallback to provider method
                      final completedInfo = planningProvider.getChildProgress(child.id, plan.id);
                        completedCount = completedInfo['completed'] as int;
                        totalActivities = completedInfo['total'] as int;
                        isCompleted = completedCount == totalActivities && totalActivities > 0;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isCompleted,
                              onChanged: (value) {
                                // Mark all activities for this child as complete or incomplete
                                _markChildActivitiesAsComplete(
                                  plan.id, 
                                  child.id, 
                                  value ?? false, 
                                  planningProvider
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryContainer,
                              radius: 16,
                              child: Text(
                                child.name.substring(0, 1),
                                style: TextStyle(
                                  color: AppTheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                child.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '$completedCount/$totalActivities',
                              style: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to mark all activities for a specific child
  Future<void> _markChildActivitiesAsComplete(
    int planId,
    String childId,
    bool isCompleted,
    PlanningProvider planningProvider,
  ) async {
    setState(() {
      _isMarkingAllComplete = true;
    });
    
    try {
      bool allSuccess = true;
      
      for (final activity in widget.activities) {
        if (activity.id == null) continue;
        
        final success = await planningProvider.markActivityAsCompleted(
          activity.id!,
          isCompleted,
          childId: childId,
        );
        
        if (!success) {
          allSuccess = false;
        }
      }
      
      // Explicitly refresh plan data to update UI
      await planningProvider.fetchPlanWithCompletionData(planId);
      
      if (mounted) {
        if (allSuccess) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(
                isCompleted 
                    ? 'Semua aktivitas berhasil ditandai selesai' 
                    : 'Semua aktivitas berhasil ditandai belum selesai'
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Beberapa aktivitas gagal diperbarui'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAllComplete = false;
        });
      }
    }
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
  
  Widget _buildActivitiesSection(
    Map<String, List<PlannedActivity>> activitiesByDate,
    PlanningProvider planningProvider,
    List<ChildModel> children,
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
                            final activityDetails = activityProvider.getActivityById(
                              activity.activityId.toString()
                            );
                            
                            if (activityDetails == null) {
                              return const ListTile(
                                title: Text('Detail aktivitas tidak ditemukan'),
                              );
                            }
                            
                            return _buildActivityCard(
                              activity,
                              activityDetails,
                              planningProvider,
                              children
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
  
  // New method to build activity card with collapsible children section
  Widget _buildActivityCard(
    PlannedActivity activity,
    ActivityModel activityDetails,
    PlanningProvider planningProvider,
    List<ChildModel> children,
  ) {
    // Local state for expanded/collapsed
    final String activityKey = 'activity_${activity.id}';
    bool isExpanded = _expandedActivities.contains(activityKey);
    
    // Count completed children for this activity directly from completionByChild
    int completedCount = 0;
    if (activity.id != null) {
      for (final child in children) {
        if (activity.isCompletedByChild(child.id)) {
          completedCount++;
        }
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Activity header with expand/collapse
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedActivities.remove(activityKey);
                } else {
                  _expandedActivities.add(activityKey);
                }
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activityDetails.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getEnvironmentColor(
                            activityDetails.environment,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
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
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$completedCount/${children.length} selesai',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: completedCount == children.length 
                              ? Colors.green 
                              : AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Collapsible children completion section
          if (isExpanded) ...[
            const Divider(height: 1),
            _buildActivityChildCompletion(activity, planningProvider, children),
          ],
        ],
      ),
    );
  }

  // Updated method to build child completion status for a specific activity
  Widget _buildActivityChildCompletion(
    PlannedActivity activity,
    PlanningProvider planningProvider,
    List<ChildModel> children,
  ) {
    if (children.isEmpty || activity.id == null) {
      return const SizedBox.shrink();
    }
    
    final bool isUpdating = _updatingActivityId == activity.id;
    
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status Anak',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (children.length > 1)
                TextButton.icon(
                  onPressed: isUpdating 
                    ? null
                    : () async {
                        if (activity.id == null) return;
                        
                        // Check if all children have completed this activity
                        final bool allCompleted = children.every((child) => 
                          activity.isCompletedByChild(child.id));
                        
                        // If all are completed, we'll uncomplete them, otherwise complete all
                        final bool newStatus = !allCompleted;
                        
                        try {
                          setState(() {
                            _updatingActivityId = activity.id;
                          });
                          
                          await planningProvider.markActivityAsCompletedForAllChildren(
                            activity.id!,
                            newStatus,
                          );
                          
                          // Refresh plan data to update UI
                          await planningProvider.fetchPlanWithCompletionData(widget.planId);
                          
                          if (mounted) {
                            setState(() {
                              _updatingActivityId = null;
                            });
                            
                            _scaffoldMessengerKey.currentState?.showSnackBar(
                              SnackBar(
                                content: Text(newStatus 
                                  ? 'Semua anak ditandai selesai' 
                                  : 'Semua anak ditandai belum selesai'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
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
                        }
                      },
                  icon: isUpdating 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.done_all, size: 16),
                  label: Text(
                    'Semua',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size(0, 24),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Show all children with their completion status for this activity
          ...children.map((child) {
            // Get completion status for this child directly from the activity
            final bool isCompleted = activity.isCompletedByChild(child.id);
            
            return Card(
              elevation: 0,
              color: Colors.grey.shade50,
              margin: EdgeInsets.only(bottom: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  children: [
                    Checkbox(
                      value: isCompleted,
                      onChanged: isUpdating
                        ? null
                        : (value) async {
                          if (activity.id == null) return;
                          
                          try {
                            setState(() {
                              _updatingActivityId = activity.id;
                            });
                            
                            final success = await planningProvider.markActivityAsCompleted(
                              activity.id!,
                              value ?? false,
                              childId: child.id,
                            );
                            
                            // Explicitly refresh plan data instead of just relying on the UI state
                            if (success) {
                              await planningProvider.fetchPlanWithCompletionData(widget.planId);
                            }
                            
                            if (mounted) {
                              setState(() {
                                _updatingActivityId = null;
                              });
                              
                              if (!success) {
                                _scaffoldMessengerKey.currentState?.showSnackBar(
                                  const SnackBar(
                                    content: Text('Gagal mengubah status aktivitas'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
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
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryContainer,
                      radius: 14,
                      child: Text(
                        child.name.substring(0, 1),
                        style: TextStyle(
                          color: AppTheme.onPrimaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        child.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isCompleted ? 'Selesai' : 'Belum',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showActivityDetails(
    PlannedActivity plannedActivity,
    ActivityModel activity,
    PlanningProvider planningProvider,
  ) {
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
                      Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDetailRow(
                        'Deskripsi',
                        activity.description,
                        multiLine: true,
                      ),
                      const Divider(height: 24),
                      
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
                                    setState(() {});
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