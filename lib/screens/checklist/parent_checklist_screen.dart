import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '/models/activity_model.dart';
import '/models/checklist_item_model.dart';
import '/models/child_model.dart';
import '/models/planning_model.dart';
import '/models/user_model.dart';
import '/providers/activity_provider.dart';
import '/providers/auth_provider.dart';
import '/providers/checklist_provider.dart';
import '/providers/planning_provider.dart';
import '/providers/user_provider.dart';
import '/screens/checklist/observation_form_screen.dart';
import '/lib/theme/app_theme.dart';
import '/widgets/home/child_avatar.dart';
import '/widgets/checklist/activity_detail_card.dart';

class ParentChecklistScreen extends StatefulWidget {
  final ChildModel child;

  const ParentChecklistScreen({super.key, required this.child});

  @override
  State<ParentChecklistScreen> createState() => _ParentChecklistScreenState();
}

class _ParentChecklistScreenState extends State<ParentChecklistScreen> {
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();
  List<DateTime> _months = [];
  List<int> _expandedDays = [];
  UserModel? _currentParent;

  @override
  void initState() {
    super.initState();

    // Inisialisasi locale data untuk format tanggal bahasa Indonesia
    initializeDateFormatting('id_ID', null);

    // Generate list of months (last 6 months)
    final now = DateTime.now();
    for (int i = 0; i < 6; i++) {
      _months.add(DateTime(now.year, now.month - i, 1));
    }

    // Menggunakan addPostFrameCallback untuk memastikan _loadData dipanggil
    // setelah proses build selesai
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();

      // Dapatkan informasi orang tua dari AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        setState(() {
          _currentParent = authProvider.user;
        });
      }

      // Muat data pengguna untuk mendapatkan informasi guru dan orang tua
      Provider.of<UserProvider>(context, listen: false).fetchParents();
    });
  }

  Future<void> _loadData() async {
    final checklistProvider = Provider.of<ChecklistProvider>(
      context,
      listen: false,
    );
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );
    final planningProvider = Provider.of<PlanningProvider>(
      context,
      listen: false,
    );

    setState(() {
      _isLoading = true;
    });

    // Fetch checklist items for this child
    await checklistProvider.fetchChecklistItems(widget.child.id);

    // Fetch planning data for this child
    await planningProvider.fetchPlansForParent(widget.child.id);

    // Make sure activities are loaded
    if (activityProvider.activities.isEmpty) {
      await activityProvider.fetchActivities();
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Aktivitas')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildChildHeader(),
                  _buildMonthSelector(),
                  Expanded(child: _buildCalendarActivities()),
                ],
              ),
    );
  }

  Widget _buildChildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryContainer.withOpacity(0.3),
      child: Column(
        children: [
          Row(
            children: [
              Hero(
                tag: 'child_avatar_${widget.child.id}',
                child: ChildAvatar(child: widget.child, size: 60),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.child.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.child.age} tahun',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_currentParent != null) ...[
            const SizedBox(height: 12),
            Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                // Dapatkan nama orang tua yang sebenarnya
                final parentName =
                    userProvider.getParentNameById(_currentParent!.id) ??
                    _currentParent!.name;

                return Row(
                  children: [
                    Icon(Icons.person, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Orang tua: $parentName',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _months.length,
        itemBuilder: (context, index) {
          final month = _months[index];
          final isSelected =
              month.year == _selectedMonth.year &&
              month.month == _selectedMonth.month;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(DateFormat('MMMM yyyy', 'id_ID').format(month)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedMonth = month;
                  });
                }
              },
              backgroundColor: AppTheme.surfaceVariant,
              selectedColor: AppTheme.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color:
                    isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarActivities() {
    return Consumer2<PlanningProvider, ActivityProvider>(
      builder: (context, planningProvider, activityProvider, child) {
        // Get all days in selected month
        final daysInMonth = _getDaysInMonth(_selectedMonth);

        // Filter days that have activities
        final daysWithActivities =
            daysInMonth.where((day) {
              final activitiesForDate = planningProvider.getActivitiesForDate(
                day,
              );
              return activitiesForDate.isNotEmpty;
            }).toList();

        if (daysWithActivities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 80,
                  color: AppTheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada aktivitas untuk bulan ini',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Coba pilih bulan lain atau hubungi guru',
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: daysWithActivities.length,
            itemBuilder: (context, index) {
              final day = daysWithActivities[index];
              final activitiesForDate = planningProvider.getActivitiesForDate(
                day,
              );
              final dayKey = day.day;
              final isExpanded = _expandedDays.contains(dayKey);

              return _buildDayActivitiesDropdown(
                day,
                activitiesForDate,
                activityProvider,
                isExpanded,
                dayKey,
              ).animate().fadeIn(
                duration: const Duration(milliseconds: 500),
                delay: Duration(milliseconds: 50 * index),
              );
            },
          ),
        );
      },
    );
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final List<DateTime> days = [];
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      days.add(DateTime(month.year, month.month, i));
    }

    return days;
  }

  Widget _buildDayActivitiesDropdown(
    DateTime day,
    List<PlannedActivity> activities,
    ActivityProvider activityProvider,
    bool isExpanded,
    int dayKey,
  ) {
    // Count completed activities
    final completedCount = activities.where((a) => a.completed).length;
    final completionPercentage =
        activities.isNotEmpty
            ? (completedCount / activities.length * 100).toInt()
            : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedDays.remove(dayKey);
                } else {
                  _expandedDays.add(dayKey);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(day),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${activities.length} aktivitas',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppTheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value:
                          activities.isNotEmpty
                              ? completedCount / activities.length
                              : 0,
                      backgroundColor: AppTheme.primaryContainer,
                      minHeight: 8,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completionPercentage == 100
                            ? AppTheme.success
                            : AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Penyelesaian: $completedCount/${activities.length} ($completionPercentage%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children:
                    activities.map((activity) {
                      final activityData = activityProvider.getActivityById(
                        activity.activityId,
                      );
                      if (activityData == null) {
                        return const SizedBox.shrink();
                      }

                      return _buildActivityItem(activity, activityData);
                    }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    PlannedActivity plannedActivity,
    ActivityModel activityData,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        margin: EdgeInsets.zero,
        color: AppTheme.surfaceVariant.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          plannedActivity.completed
                              ? AppTheme.success.withOpacity(0.2)
                              : AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      plannedActivity.completed
                          ? Icons.check_circle_outline
                          : Icons.pending_actions,
                      color:
                          plannedActivity.completed
                              ? AppTheme.success
                              : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activityData.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration:
                                plannedActivity.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activityData.description,
                          style: TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildEnvironmentChip(activityData.environment),
                  _buildDifficultyChip(activityData.difficulty),
                  if (plannedActivity.scheduledTime != null)
                    _buildTimeChip(plannedActivity.scheduledTime!),
                  _buildStatusChip(plannedActivity.completed),
                ],
              ),
              if (!plannedActivity.completed) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    // Tampilkan dialog konfirmasi atau langsung tandai sebagai selesai
                    _showMarkCompletedDialog(
                      context,
                      plannedActivity.activityId,
                      activityData,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 36),
                  ),
                  child: const Text('Tandai Selesai'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showMarkCompletedDialog(
    BuildContext context,
    String activityId,
    ActivityModel activity,
  ) {
    // Implementasi dialog konfirmasi untuk menandai aktivitas sebagai selesai
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tandai Aktivitas Selesai'),
            content: Text(
              'Apakah Anda yakin ingin menandai aktivitas "${activity.title}" sebagai selesai?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('BATAL'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Implementasi logika untuk menandai aktivitas sebagai selesai
                  // dan menambahkan observasi
                  _markActivityAsCompleted(context, activityId, activity);
                },
                child: const Text('TANDAI SELESAI'),
              ),
            ],
          ),
    );
  }

  void _markActivityAsCompleted(
    BuildContext context,
    String activityId,
    ActivityModel activity,
  ) {
    // Cari checklist item yang sesuai
    final checklistProvider = Provider.of<ChecklistProvider>(
      context,
      listen: false,
    );

    // Dapatkan semua checklist item untuk anak ini dan filter berdasarkan activityId
    final allItems = checklistProvider.getChecklistItemsForChild(
      widget.child.id,
    );
    final items =
        allItems.where((item) => item.activityId == activityId).toList();

    if (items.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ObservationFormScreen(
                child: widget.child,
                item: items.first,
                activity: activity,
                isTeacher: false,
              ),
        ),
      );
    } else {
      // Jika tidak ada checklist item, tampilkan snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak dapat menemukan item checklist untuk aktivitas ini',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEnvironmentChip(String environment) {
    String label;
    switch (environment) {
      case 'Home':
        label = 'Rumah';
        break;
      case 'School':
        label = 'Sekolah';
        break;
      case 'Both':
        label = 'Keduanya';
        break;
      default:
        label = environment;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getEnvironmentColor(environment).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _getEnvironmentColor(environment),
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    String label;
    switch (difficulty) {
      case 'Easy':
        label = 'Mudah';
        break;
      case 'Medium':
        label = 'Sedang';
        break;
      case 'Hard':
        label = 'Sulit';
        break;
      default:
        label = difficulty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getDifficultyColor(difficulty).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _getDifficultyColor(difficulty),
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildTimeChip(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.tertiary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        time,
        style: TextStyle(
          color: AppTheme.tertiary,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isCompleted ? AppTheme.success : Colors.orange).withOpacity(
          0.2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isCompleted ? 'Selesai' : 'Belum Selesai',
        style: TextStyle(
          color: isCompleted ? AppTheme.success : Colors.orange,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.success;
      case 'in-progress':
        return AppTheme.info;
      case 'pending':
        return AppTheme.secondary;
      default:
        return AppTheme.warning;
    }
  }
}
