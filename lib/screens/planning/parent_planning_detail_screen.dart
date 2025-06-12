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
  bool _isLoadingPlan = true;
  Planning? _currentPlan;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingPlan = true;
      _errorMessage = null;
    });

    try {
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
        throw Exception('ID rencana tidak valid');
      }
      
      // Try to find the plan in existing data first
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
        // If plan not found in cache, trigger a refresh
        await planningProvider.fetchPlans();
        
        // Try to find it again after refresh
        final refreshedPlan = planningProvider.plans.firstWhere(
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
        
        if (refreshedPlan.id != 0) {
          _currentPlan = refreshedPlan;
          debugPrint('Found plan with ID ${refreshedPlan.id} after refresh');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              
              ScaffoldMessenger.of(context).showSnackBar(
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
            child: _isLoadingPlan
                ? const Center(child: CircularProgressIndicator())
                : Consumer<UserProvider>(
                    builder: (context, userProvider, _) {
                      // Get teacher name based on teacherId from planning
                      final String teacherId = _currentPlan?.teacherId ?? '';
                      
                      if (teacherId.isEmpty) {
                        return _buildTeacherDetails('Guru', true);
                      }
                      
                      // Check if name is in cache
                      final teacherName = userProvider.getTeacherNameById(teacherId);
                      
                      // If we have a name, show it
                      if (teacherName != null) {
                        return _buildTeacherDetails(teacherName, false);
                      }
                      
                      // If name not in cache, trigger a direct fetch and show loading
                      _fetchTeacherData();
                      return _buildTeacherDetails('Memuat data guru...', false);
                    }
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTeacherDetails(String name, bool showMissingData) {
    return Column(
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
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        if (showMissingData) 
          const Text(
            '(Data guru tidak tersedia)',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.orange,
            ),
          ),
      ],
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
