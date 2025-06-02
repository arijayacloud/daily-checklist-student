import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/activity_model.dart';
import '/models/planning_model.dart';
import '/providers/activity_provider.dart';
import '/providers/planning_provider.dart';
import '/screens/planning/add_plan_screen.dart';
import '/lib/theme/app_theme.dart';
import '/providers/checklist_provider.dart';
import '/providers/child_provider.dart';
import '/screens/planning/planning_detail_screen.dart';

class TeacherPlanningScreen extends StatefulWidget {
  const TeacherPlanningScreen({super.key});

  @override
  State<TeacherPlanningScreen> createState() => _TeacherPlanningScreenState();
}

class _TeacherPlanningScreenState extends State<TeacherPlanningScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  String _filterStatus = 'all'; // 'all', 'completed', 'pending'

  @override
  void initState() {
    super.initState();

    // Inisialisasi locale data untuk format tanggal bahasa Indonesia
    initializeDateFormatting('id_ID', null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlanningProvider>(context, listen: false).fetchPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perencanaan Mingguan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Ringkasan Mingguan',
            onPressed: () {
              _showWeeklySummary(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [_buildCalendar(), Expanded(child: _buildDailySchedule())],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPlanScreen(selectedDate: _selectedDay),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Consumer<PlanningProvider>(
          builder: (context, planningProvider, child) {
            // Dapatkan tanggal-tanggal yang memiliki aktivitas
            final eventDates = _getEventDates(planningProvider);

            return TableCalendar(
              firstDay: DateTime.utc(2021, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: AppTheme.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                formatButtonDecoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                formatButtonTextStyle: TextStyle(
                  color: AppTheme.onPrimaryContainer,
                ),
                titleCentered: true,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  // Tampilkan marker jika ada aktivitas pada tanggal tersebut
                  if (eventDates[_dateToKey(date)] == true) {
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.tertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // Mengkonversi DateTime menjadi string key untuk map
  String _dateToKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  // Mendapatkan tanggal-tanggal yang memiliki aktivitas
  Map<String, bool> _getEventDates(PlanningProvider provider) {
    final Map<String, bool> eventDates = {};

    for (final plan in provider.plans) {
      for (final activity in plan.activities) {
        final date = activity.scheduledDate.toDate();
        final key = _dateToKey(date);
        eventDates[key] = true;
      }
    }

    return eventDates;
  }

  Widget _buildDailySchedule() {
    return Consumer2<PlanningProvider, ActivityProvider>(
      builder: (context, planningProvider, activityProvider, child) {
        if (planningProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final activitiesForDate = planningProvider.getActivitiesForDate(
          _selectedDay,
        );

        if (activitiesForDate.isEmpty) {
          return _buildEmptySchedule();
        }

        // Filter aktivitas berdasarkan status
        final filteredActivities = _filterActivities(activitiesForDate);

        return Column(
          children: [
            _buildFilterChips(activitiesForDate),
            Expanded(
              child: _buildScheduleList(
                filteredActivities,
                activityProvider.activities,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChips(List<PlannedActivity> allActivities) {
    final completedCount = allActivities.where((a) => a.completed).length;
    final pendingCount = allActivities.length - completedCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              'all',
              'Semua (${allActivities.length})',
              AppTheme.primary,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'completed',
              'Selesai ($completedCount)',
              AppTheme.success,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'pending',
              'Belum Selesai ($pendingCount)',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    final isSelected = _filterStatus == value;

    return FilterChip(
      selected: isSelected,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? color : AppTheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
          width: 1,
        ),
      ),
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
    );
  }

  List<PlannedActivity> _filterActivities(List<PlannedActivity> activities) {
    switch (_filterStatus) {
      case 'completed':
        return activities.where((activity) => activity.completed).toList();
      case 'pending':
        return activities.where((activity) => !activity.completed).toList();
      case 'all':
      default:
        return activities;
    }
  }

  Widget _buildEmptySchedule() {
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
            'Tidak ada aktivitas terjadwal untuk ${DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDay)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap tombol + untuk menambahkan aktivitas pada hari ini',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(
    List<PlannedActivity> activities,
    List<ActivityModel> allActivities,
  ) {
    // Sort activities by time if available
    activities.sort((a, b) {
      if (a.scheduledTime == null && b.scheduledTime == null) {
        return 0;
      }
      if (a.scheduledTime == null) {
        return 1;
      }
      if (b.scheduledTime == null) {
        return -1;
      }
      return a.scheduledTime!.compareTo(b.scheduledTime!);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDay),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final plannedActivity = activities[index];
              final activity = allActivities.firstWhere(
                (a) => a.id == plannedActivity.activityId,
                orElse:
                    () => ActivityModel(
                      id: '',
                      title: 'Unknown Activity',
                      description: '',
                      environment: 'Both',
                      difficulty: 'Medium',
                      ageRange: AgeRange(min: 3, max: 6),
                      customSteps: [],
                      createdAt: Timestamp.now(),
                      createdBy: '',
                    ),
              );

              return _buildScheduleItem(activity, plannedActivity);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(
    ActivityModel activity,
    PlannedActivity plannedActivity,
  ) {
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
                if (plannedActivity.scheduledTime != null)
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
                      plannedActivity.scheduledTime!,
                      style: TextStyle(
                        color: AppTheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Spacer(),
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
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getEnvironmentColor(
                      activity.environment,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    activity.environment,
                    style: TextStyle(
                      color: _getEnvironmentColor(activity.environment),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              activity.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              activity.description,
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => PlanningDetailScreen(
                                planId: plannedActivity.planId ?? '',
                                activityId: plannedActivity.activityId,
                                scheduledDate: plannedActivity.scheduledDate,
                              ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Detail'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        plannedActivity.completed
                            ? null
                            : () => _markActivityAsCompleted(
                              context,
                              plannedActivity,
                            ),
                    icon: Icon(
                      plannedActivity.completed
                          ? Icons.check
                          : Icons.assignment_turned_in,
                    ),
                    label: Text(
                      plannedActivity.completed ? 'Selesai' : 'Selesaikan',
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppTheme.primary,
                      disabledBackgroundColor: AppTheme.success.withOpacity(
                        0.6,
                      ),
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        () => _createChecklistFromActivity(
                          context,
                          plannedActivity,
                          activity,
                        ),
                    icon: const Icon(Icons.assignment_add),
                    label: const Text('Tambahkan ke Checklist'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.tertiary,
                      side: BorderSide(color: AppTheme.tertiary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        () => _showCompletionUsers(
                          context,
                          plannedActivity,
                          activity,
                        ),
                    icon: const Icon(Icons.people),
                    label: const Text('Lihat Progress'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _markActivityAsCompleted(
    BuildContext context,
    PlannedActivity plannedActivity,
  ) async {
    try {
      final planningProvider = Provider.of<PlanningProvider>(
        context,
        listen: false,
      );

      await planningProvider.markActivityAsCompleted(
        planId: plannedActivity.planId ?? '',
        activityId: plannedActivity.activityId,
        scheduledDate: plannedActivity.scheduledDate,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity marked as completed'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  void _createChecklistFromActivity(
    BuildContext context,
    PlannedActivity plannedActivity,
    ActivityModel activity,
  ) async {
    // Verifikasi planId ada dan valid
    final planId = plannedActivity.planId;
    if (planId == null || planId.isEmpty) {
      debugPrint(
        'Error: planId kosong atau null: ${plannedActivity.activityId}',
      );

      // Tampilkan dialog untuk meminta pengguna mencoba lagi atau memilih anak langsung
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Informasi Aktivitas Tidak Lengkap'),
              content: const Text(
                'Data plan tidak lengkap untuk aktivitas ini. Anda dapat memilih anak secara langsung untuk menambahkan aktivitas ke checklist mereka.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Tampilkan dialog pemilihan anak langsung
                    final planningProvider = Provider.of<PlanningProvider>(
                      context,
                      listen: false,
                    );
                    final checklistProvider = Provider.of<ChecklistProvider>(
                      context,
                      listen: false,
                    );
                    _showChildSelectionDialog(
                      context,
                      plannedActivity.activityId,
                      planningProvider,
                      checklistProvider,
                    );
                  },
                  child: const Text('Pilih Anak'),
                ),
              ],
            ),
      );
      return;
    }

    final planningProvider = Provider.of<PlanningProvider>(
      context,
      listen: false,
    );
    final checklistProvider = Provider.of<ChecklistProvider>(
      context,
      listen: false,
    );
    final planData = planningProvider.getPlanById(planId);

    if (planData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat menemukan data perencanaan'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    // Jika plan untuk semua anak, tampilkan dialog untuk memilih anak
    if (planData.childId == null) {
      await _showChildSelectionDialog(
        context,
        plannedActivity.activityId,
        planningProvider,
        checklistProvider,
      );
    } else {
      try {
        await planningProvider.createChecklistFromActivity(
          activityId: plannedActivity.activityId,
          childId: planData.childId!,
          checklistProvider: checklistProvider,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil ditambahkan ke checklist'),
            backgroundColor: AppTheme.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _showChildSelectionDialog(
    BuildContext context,
    String activityId,
    PlanningProvider planningProvider,
    ChecklistProvider checklistProvider,
  ) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Pilih Anak'),
            content: Consumer<ChildProvider>(
              builder: (context, childProvider, child) {
                if (childProvider.children.isEmpty) {
                  return const Text('Tidak ada anak yang tersedia');
                }

                return SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: childProvider.children.length,
                    itemBuilder: (context, index) {
                      final child = childProvider.children[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text(child.name[0])),
                        title: Text(child.name),
                        subtitle: Text('${child.age} tahun'),
                        onTap: () async {
                          Navigator.pop(context);

                          try {
                            await planningProvider.createChecklistFromActivity(
                              activityId: activityId,
                              childId: child.id,
                              checklistProvider: checklistProvider,
                            );

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Berhasil ditambahkan ke checklist',
                                ),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ],
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

  void _showWeeklySummary(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Memungkinkan bottom sheet lebih tinggi
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Consumer2<PlanningProvider, ActivityProvider>(
            builder: (context, planningProvider, activityProvider, child) {
              // Dapatkan tanggal awal minggu (Senin)
              final now = DateTime.now();
              final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

              // Hitung jumlah aktivitas per hari selama seminggu
              final Map<int, int> activitiesPerDay = {};
              for (int i = 0; i < 7; i++) {
                final date = startOfWeek.add(Duration(days: i));
                final activities = planningProvider.getActivitiesForDate(date);
                activitiesPerDay[i] = activities.length;
              }

              // Cari hari dengan aktivitas terbanyak
              int maxActivities = 0;
              for (final count in activitiesPerDay.values) {
                if (count > maxActivities) maxActivities = count;
              }

              return DraggableScrollableSheet(
                initialChildSize: 0.5, // 50% dari layar
                minChildSize: 0.3, // Minimum 30% dari layar
                maxChildSize: 0.85, // Maximum 85% dari layar
                expand: false,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ringkasan Minggu Ini',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 200, // Fixed height untuk grafik
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(7, (index) {
                                final date = startOfWeek.add(
                                  Duration(days: index),
                                );
                                final activityCount =
                                    activitiesPerDay[index] ?? 0;
                                final barHeight =
                                    maxActivities > 0
                                        ? 150 * (activityCount / maxActivities)
                                        : 0.0;

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      activityCount.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 30,
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        color: _getBarColor(index, now),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('E', 'id_ID').format(date),
                                      style: TextStyle(
                                        color: _getBarColor(index, now),
                                        fontWeight:
                                            isSameDay(date, now)
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildWeeklyProgress(planningProvider),
                          const SizedBox(height: 24),
                          _buildDailyActivitiesList(
                            planningProvider,
                            startOfWeek,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
    );
  }

  Widget _buildWeeklyProgress(PlanningProvider provider) {
    // Dapatkan tanggal awal minggu (Senin)
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    // Hitung total aktivitas dan yang sudah selesai minggu ini
    int totalActivities = 0;
    int completedActivities = 0;

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final activities = provider.getActivitiesForDate(date);
      totalActivities += activities.length;
      completedActivities += activities.where((a) => a.completed).length;
    }

    final completionPercentage =
        totalActivities > 0
            ? (completedActivities / totalActivities * 100).toInt()
            : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress Mingguan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            Text(
              '$completionPercentage%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value:
                totalActivities > 0 ? completedActivities / totalActivities : 0,
            minHeight: 10,
            backgroundColor: AppTheme.primaryContainer,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selesai: $completedActivities / $totalActivities aktivitas',
          style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }

  Color _getBarColor(int dayIndex, DateTime now) {
    // Highlight hari ini
    if (now.weekday - 1 == dayIndex) {
      return AppTheme.primary;
    }

    // Warna berbeda untuk weekend
    if (dayIndex >= 5) {
      // Sabtu dan Minggu
      return AppTheme.tertiary;
    }

    return AppTheme.primary.withOpacity(0.6);
  }

  Widget _buildDailyActivitiesList(
    PlanningProvider provider,
    DateTime startOfWeek,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rincian Aktivitas Minggu Ini',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(7, (index) {
          final date = startOfWeek.add(Duration(days: index));
          final activities = provider.getActivitiesForDate(date);

          if (activities.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getBarColor(index, DateTime.now()),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, d MMMM', 'id_ID').format(date),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${activities.length} aktivitas',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ...activities.map((activity) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          activity.completed
                              ? AppTheme.success.withOpacity(0.2)
                              : AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      activity.completed
                          ? Icons.check
                          : Icons.assignment_outlined,
                      color:
                          activity.completed
                              ? AppTheme.success
                              : AppTheme.primary,
                    ),
                  ),
                  title: Text(
                    'Aktivitas ${activity.activityId.substring(0, 6)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration:
                          activity.completed
                              ? TextDecoration.lineThrough
                              : null,
                    ),
                  ),
                  subtitle: Text(
                    activity.scheduledTime ?? 'Waktu tidak ditentukan',
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(
                    Icons.circle,
                    size: 12,
                    color:
                        activity.completed ? AppTheme.success : Colors.orange,
                  ),
                );
              }).toList(),
              const Divider(),
            ],
          );
        }),
      ],
    );
  }

  // Fungsi untuk menampilkan dialog siapa saja yang sudah menyelesaikan aktivitas
  Future<void> _showCompletionUsers(
    BuildContext context,
    PlannedActivity plannedActivity,
    ActivityModel activity,
  ) async {
    final planningProvider = Provider.of<PlanningProvider>(
      context,
      listen: false,
    );

    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("Memuat data..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Ambil data pengguna yang telah menyelesaikan aktivitas
      final completionUsers = await planningProvider.getCompletionUsers(
        plannedActivity.activityId,
        plannedActivity.planId ?? '',
        plannedActivity.scheduledDate,
      );

      // Tutup dialog loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (!context.mounted) return;

      // Tampilkan dialog dengan informasi pengguna
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Progress Aktivitas',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              Text(
                                activity.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (completionUsers.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Belum ada yang menyelesaikan aktivitas ini',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: completionUsers.length,
                          itemBuilder: (context, index) {
                            final user = completionUsers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(user['childName'][0]),
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                                title: Text(
                                  user['childName'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Orangtua: ${user['parentName']}'),
                                    if (user['completedAt'] != null)
                                      Text(
                                        'Diselesaikan pada: ${DateFormat('dd/MM/yyyy HH:mm').format(user['completedAt'].toDate())}',
                                      ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (user['completedAtHome'])
                                      Icon(
                                        Icons.home,
                                        color: AppTheme.success,
                                        size: 20,
                                      ),
                                    if (user['completedAtSchool'])
                                      Icon(
                                        Icons.school,
                                        color: AppTheme.tertiary,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      // Tutup dialog loading jika terjadi error
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
    }
  }
}
