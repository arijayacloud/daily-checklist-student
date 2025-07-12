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
import '/laravel_api/providers/auth_provider.dart';
import '/laravel_api/models/observation_model.dart';
import '/screens/planning/parent_observation_screen.dart';
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
    
    // Use post-frame callback to ensure we're not in build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingPlan = true;
      _errorMessage = null;
    });

    try {
      // Load plan data first
      await _loadPlanData();
      
      // Set current child ID in provider after plan data is loaded (not during build)
      if (_selectedChildId != null) {
        final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
        planningProvider.setCurrentChildId(_selectedChildId!);
      }
      
      // Safely try to load teacher data, but don't block UI if it fails
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.fetchTeachers();
        
        // If we have a plan with a teacher ID, directly fetch that specific teacher
        if (_currentPlan != null && _currentPlan!.teacherId.isNotEmpty) {
          await userProvider.getUserById(_currentPlan!.teacherId);
        }
      } catch (teacherError) {
        // Just log the error but don't block the UI rendering
        debugPrint('Non-critical error loading teacher data: $teacherError');
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
        throw Exception('ID rencana tidak valid');
      }
      
      // If we have a childId, use it to fetch plans for that child specifically
      if (_selectedChildId != null) {
        await planningProvider.fetchPlans(childId: _selectedChildId).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint("DetailScreen: Timeout fetching plans");
            return;
          },
        );
      } else {
        await planningProvider.fetchPlans().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint("DetailScreen: Timeout fetching plans");
            return;
          },
        );
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
        // Try to fetch this specific plan directly
        debugPrint('Plan not found in cached data, trying direct fetch');
        final fetchedPlan = await planningProvider.fetchPlanWithCompletionData(planId);
        if (fetchedPlan != null) {
          _currentPlan = fetchedPlan;
        } else {
          throw Exception('Rencana dengan ID $planId tidak ditemukan');
        }
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
    
    // Use post-frame callback to ensure we're not doing this during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set current child ID in provider
      final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
      planningProvider.setCurrentChildId(childId);
      
      // Reload data for this child
      _loadData();
    });
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
              onPressed: () async {
                final planId = int.tryParse(widget.planId);
                if (planId != null) {
                  // Show loading indicator
                  _scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(
                      content: Text('Memuat ulang data...'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  
                  try {
                    // Fetch only this specific plan instead of all plans
                    final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
                    await planningProvider.fetchPlanWithCompletionData(planId);
                    
                    // Update the local variable
                    setState(() {
                      _currentPlan = planningProvider.plans.firstWhere(
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
                    });
                    
                    // Also refresh teacher data if needed
                    _fetchTeacherData();
                  } catch (e) {
                    if (mounted) {
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text('Gagal memuat data: ${e.toString()}'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  // Fallback to full reload if plan ID is invalid
                  _loadData();
                }
              },
            ),
          ],
        ),
        body: _errorMessage != null 
          ? _buildErrorView()
          : (_isLoadingPlan 
              ? _buildLoadingView() 
              : _buildContentView()),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ParentObservationScreen(
                  planId: widget.planId,
                  planTitle: 'Perencanaan ${widget.planId}',
                  childId: widget.childId,
                ),
              ),
            );
          },
          icon: const Icon(Icons.psychology),
          label: const Text('Observasi'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
        ),
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
            child: const Icon(Icons.person, color: Colors.white, size: 28),
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
                    String displayName = 'Guru';
                    if (_currentPlan != null) {
                      if (_currentPlan!.teacherId.isEmpty) {
                        displayName = 'Tidak diketahui';
                      } else {
                        final teacherName = userProvider.getTeacherNameById(_currentPlan!.teacherId);
                        // teacherName will now be a default string instead of null thanks to our UserProvider fix
                        displayName = teacherName ?? 'Guru';
                      }
                    }
                    
                    return Text(
                      displayName,
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
    
    // Calculate progress for the current child
    final String? childId = _selectedChildId;
    Map<String, int> progress = {'completed': 0, 'total': 0};
    double progressPercentage = 0.0;
    
    if (childId != null && plan.progressByChild.containsKey(childId)) {
      final childProgress = plan.progressByChild[childId]!;
      progress = {'completed': childProgress.completed, 'total': childProgress.total};
      progressPercentage = childProgress.percentage / 100; // Convert to 0-1 range
    } else {
      // Fallback to calculate from activities if API doesn't provide progress data
      final totalActivities = plan.activities.length;
      int completedCount = 0;
      
      if (childId != null) {
        for (final activity in plan.activities) {
          if (activity.isCompletedByChild(childId)) {
            completedCount++;
          }
        }
      } else {
        completedCount = plan.activities.where((a) => a.completed).length;
      }
      
      progress = {'completed': completedCount, 'total': totalActivities};
      progressPercentage = totalActivities > 0 ? completedCount / totalActivities : 0;
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: plan.type == 'weekly'
                ? [Colors.blue.withOpacity(0.05), Colors.blue.withOpacity(0.1)]
                : [Colors.green.withOpacity(0.05), Colors.green.withOpacity(0.1)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with plan type and date icon
            Row(
              children: [
                Icon(
                  plan.type == 'weekly' ? Icons.date_range : Icons.today,
                  color: plan.type == 'weekly' ? Colors.blue : Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.type == 'weekly'
                            ? 'Perencanaan Mingguan'
                            : 'Perencanaan Harian',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: plan.type == 'weekly' ? Colors.blue.shade700 : Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Plan ID for reference
                      Text(
                        'ID: ${plan.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Date range container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month, 
                    size: 18,
                    color: plan.type == 'weekly' ? Colors.blue : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Periode:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.type == 'weekly'
                              ? '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}'
                              : dateFormat.format(startDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: plan.type == 'weekly' ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: plan.type == 'weekly' ? Colors.blue.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      plan.type == 'weekly' ? '7 Hari' : '1 Hari',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: plan.type == 'weekly' ? Colors.blue.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Progress section
            Text(
              'Progress Aktivitas:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            
            // Progress bar with completion indicator
            Stack(
              children: [
                // Background
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                
                // Progress fill
                FractionallySizedBox(
                  widthFactor: progressPercentage.clamp(0.0, 1.0),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          plan.type == 'weekly' ? Colors.blue : Colors.green,
                          plan.type == 'weekly' ? Colors.lightBlue : Colors.lightGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                
                // Progress percentage text in the center
                if (progressPercentage > 0)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        '${(progressPercentage * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: progressPercentage > 0.4 ? Colors.white : Colors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Completion count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${progress['total']} aktivitas',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Selesai: ${progress['completed']}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            
            // Completion status label
            const SizedBox(height: 12),
            _buildCompletionStatusLabel(progressPercentage),
          ],
        ),
      ),
    );
  }
  
  // Helper to generate completion status label
  Widget _buildCompletionStatusLabel(double progressPercentage) {
    String label;
    Color color;
    IconData icon;
    
    if (progressPercentage >= 1.0) {
      label = 'Semua Aktivitas Selesai';
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (progressPercentage >= 0.75) {
      label = 'Hampir Selesai';
      color = Colors.lightGreen;
      icon = Icons.trending_up;
    } else if (progressPercentage >= 0.5) {
      label = 'Setengah Jalan';
      color = Colors.amber;
      icon = Icons.horizontal_rule;
    } else if (progressPercentage > 0) {
      label = 'Masih Dalam Progress';
      color = Colors.orange;
      icon = Icons.trending_down;
    } else {
      label = 'Belum Ada Aktivitas Selesai';
      color = Colors.grey;
      icon = Icons.radio_button_unchecked;
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
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
    
    // Get completion status for current selected child
    final String? childId = _selectedChildId;
    final bool childCompleted = childId != null && activity.completionByChild.containsKey(childId)
        ? activity.completionByChild[childId]!
        : activity.completed;

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
                    color: childCompleted
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    childCompleted ? 'Selesai' : 'Belum Selesai',
                    style: TextStyle(
                      color: childCompleted ? Colors.green : Colors.orange,
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
            
            // Environment indicator for activity 
            if (activityDetails != null) ... [
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _getEnvironmentIcon(activityDetails.environment),
                    size: 16, 
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getEnvironmentLabel(activityDetails.environment),
                    style: TextStyle(
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
            
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
                        value: childCompleted,
                        activeColor: Colors.green,
                        onChanged: (value) async {
                          if (activity.id != null) {
                            setState(() {
                              _updatingActivityId = activity.id;
                            });
                            
                            // Check if this plan belongs to the child of current parent
                            final success = await planningProvider.markActivityAsCompleted(
                              activity.id!,
                              value,
                              childId: _selectedChildId,
                            );
                            
                            if (mounted) {
                              setState(() {
                                _updatingActivityId = null;
                              });
                              
                              if (success && mounted) {
                                _scaffoldMessengerKey.currentState?.showSnackBar(
                                  SnackBar(
                                    content: Text(value 
                                      ? 'Aktivitas berhasil ditandai selesai' 
                                      : 'Aktivitas ditandai belum selesai'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                _scaffoldMessengerKey.currentState?.showSnackBar(
                                  const SnackBar(
                                    content: Text('Gagal mengubah status aktivitas'),
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
  
  // Helper to get environment icon
  IconData _getEnvironmentIcon(String environment) {
    switch (environment) {
      case 'Home':
        return Icons.home_outlined;
      case 'School':
        return Icons.school_outlined;  
      case 'Both':
        return Icons.compare_arrows_outlined;
      default:
        return Icons.help_outline;
    }
  }
  
  // Helper to get environment label in Indonesian
  String _getEnvironmentLabel(String environment) {
    switch (environment) {
      case 'Home':
        return 'Dilakukan di Rumah';
      case 'School':
        return 'Dilakukan di Sekolah';
      case 'Both':
        return 'Dilakukan di Rumah & Sekolah';
      default:
        return 'Lingkungan tidak diketahui';
    }
  }
}
