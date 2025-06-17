import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '/laravel_api/models/planning_model.dart';
import '/laravel_api/models/activity_model.dart';
import '/laravel_api/models/user_model.dart';
import '/laravel_api/models/child_model.dart';
import '/laravel_api/providers/activity_provider.dart';
import '/laravel_api/providers/planning_provider.dart';
import '/laravel_api/providers/user_provider.dart';
import '/laravel_api/providers/child_provider.dart';
import '/lib/theme/app_theme.dart';

class ParentPlanningDetailScreen extends StatefulWidget {
  final String planId;
  final String? childId; // Add childId parameter
  static const routeName = '/parent-planning-detail';

  const ParentPlanningDetailScreen({Key? key, required this.planId, this.childId})
    : super(key: key);

  @override
  State<ParentPlanningDetailScreen> createState() =>
      _ParentPlanningDetailScreenState();
}

class _ParentPlanningDetailScreenState
    extends State<ParentPlanningDetailScreen> {
  bool _isLoadingPlan = true;
  Planning? _currentPlan;
  String? _errorMessage;
  int? _updatingActivityId; // Track which activity is being updated
  String? _selectedChildId; // Track selected child for completion status
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  
  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.childId;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingPlan = true;
      _errorMessage = null;
    });

    try {
      // Set current child ID in provider if available
      if (_selectedChildId != null) {
        final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
        planningProvider.setCurrentChildId(_selectedChildId!);
      }
      
      // Load plan data
      await _loadPlanData();
      
      // Immediately fetch the teachers list to populate cache
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchTeachers();
      
      // If we have a plan with a teacher ID, directly fetch that specific teacher
      if (_currentPlan != null && _currentPlan!.teacherId.isNotEmpty) {
        final teacherName = userProvider.getTeacherNameById(_currentPlan!.teacherId);
        if (teacherName == null) {
          // Only fetch if not in cache
          await userProvider.getUserById(_currentPlan!.teacherId);
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _errorMessage = 'Terjadi kesalahan saat memuat data: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPlan = false;
        });
      }
    }
  }

  Future<void> _loadPlanData() async {
    final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
    
    try {
      // Find the plan by ID - parse as int to ensure correct comparison
      final planId = int.tryParse(widget.planId);
      if (planId == null) {
        throw Exception('Invalid plan ID');
      }
      
      // If we have a childId, use parent-specific API method
      if (_selectedChildId != null) {
        // Store the current child ID in provider to use it for activity updates
        planningProvider.setCurrentChildId(_selectedChildId!);
        
        // Use the specialized parent API endpoint
        await planningProvider.fetchParentPlanDetail(planId, _selectedChildId);
      } else {
        // First fetch all plans (for backward compatibility)
        await planningProvider.fetchPlans();
      }
      
      // Try to find the plan in existing data
      final existingPlan = planningProvider.plans.firstWhere(
        (p) => p.id == planId,
        orElse: () => Planning(
          id: 0, 
          type: 'daily',
          teacherId: '0',
          childId: null,
          startDate: DateTime.now(),
          activities: [],
        ),
      );
      
      // If plan is found, use it
      if (existingPlan.id != 0) {
        _currentPlan = existingPlan;
        debugPrint('Found plan with ID ${existingPlan.id} in cached data');
      } else {
        throw Exception('Plan with ID $planId not found');
      }
    } catch (e) {
      debugPrint('Error loading plan: $e');
      rethrow;
    }
  }

  // Add this method to specifically fetch the teacher data
  Future<void> _fetchTeacherData() async {
    if (_currentPlan != null && _currentPlan!.teacherId.isNotEmpty) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      try {
        await userProvider.getUserById(_currentPlan!.teacherId);
        // No need to setState since the Consumer will rebuild when notified
      } catch (e) {
        debugPrint('Error fetching teacher data: $e');
      }
    }
  }

  void _onChildChanged(String childId) {
    setState(() {
      _selectedChildId = childId;
    });
    
    // Set current child ID in provider
    final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
    planningProvider.setCurrentChildId(childId);
    
    // Reload data for this child
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detail Perencanaan'), 
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () {
                // Refresh all data
                _loadData();
                
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
        body: _errorMessage != null 
          ? _buildErrorView()
          : (_isLoadingPlan 
              ? _buildLoadingView() 
              : _buildContentView()),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Terjadi kesalahan. Silakan coba lagi.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Coba Lagi'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Memuat data...'),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    final plan = _currentPlan;
    if (plan == null) {
      return _buildErrorView();
    }
    
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, _) {
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
      }
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dibuat oleh:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer<UserProvider>(
                  builder: (context, userProvider, _) {
                    final teacherName = _currentPlan != null 
                        ? userProvider.getTeacherNameById(_currentPlan!.teacherId) ?? 'Memuat...'
                        : 'Tidak Diketahui';
                    return Text(
                      teacherName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
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
    final bool isUpdating = _updatingActivityId == activity.id;
    
    // Get activity details to check if parent can update it
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    final activityDetails = activityProvider.getActivityById(activity.activityId.toString());
    final canParentUpdate = _canParentUpdateActivity(activityDetails);

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
            
            // Add status update section for 'Home' or 'Both' activities
            if (canParentUpdate) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Status Aktivitas:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Consumer<PlanningProvider>(
                    builder: (context, planningProvider, _) {
                      return isUpdating 
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2)
                            ) 
                          : Switch(
                        value: activity.completed,
                        onChanged: (value) async {
                          if (activity.id != null) {
                            setState(() {
                              _updatingActivityId = activity.id;
                            });
                            
                            try {
                              // Make sure we have a child ID
                              final childId = _selectedChildId ?? planningProvider.currentChildId;
                              if (childId == null || childId.isEmpty) {
                                throw Exception('Cannot determine child ID');
                              }
                              
                              // Store a local reference to the provider to avoid context issues
                              final provider = planningProvider;
                              
                              // Use the parent-specific API endpoint
                              final success = await provider.parentUpdateActivityStatus(
                                activity.id!,
                                value,
                                childId
                              );
                              
                              if (mounted) {
                                setState(() {
                                  _updatingActivityId = null;
                                });
                                
                                if (success) {
                                  // Update local state optimistically
                                  setState(() {
                                    // Cannot directly set activity.completed as it may be final
                                    // We'll rely on the refresh to update the state
                                  });
                                  
                                  _scaffoldMessengerKey.currentState?.showSnackBar(
                                    SnackBar(
                                      content: Text(value 
                                        ? 'Activity successfully marked as completed' 
                                        : 'Activity marked as incomplete'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  
                                  // Refresh the plan data if we're still mounted
                                  if (mounted) {
                                    // Use the stored provider reference
                                    await provider.fetchParentPlanDetail(
                                      int.parse(widget.planId),
                                      childId
                                    );
                                  }
                                } else {
                                  _scaffoldMessengerKey.currentState?.showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to update activity status'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(() {
                                  _updatingActivityId = null;
                                });
                                
                                _scaffoldMessengerKey.currentState?.showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      );
                    }
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // Helper to check if parent can update activity
  bool _canParentUpdateActivity(ActivityModel? activity) {
    if (activity == null) return false;
    
    // Parents can update activities with environment 'Home' or 'Both'
    return activity.environment == 'Home' || activity.environment == 'Both';
  }
}
