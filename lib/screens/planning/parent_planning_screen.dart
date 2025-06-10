import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import '/config.dart';
import '/laravel_api/models/activity_model.dart';
import '/laravel_api/models/planning_model.dart';
import '/laravel_api/providers/activity_provider.dart';
import '/laravel_api/providers/planning_provider.dart';
import '/laravel_api/providers/auth_provider.dart';
import '/laravel_api/providers/user_provider.dart';
import '/laravel_api/providers/child_provider.dart';
import '/lib/theme/app_theme.dart';
import '/screens/planning/parent_planning_detail_screen.dart';

class ParentPlanningScreen extends StatefulWidget {
  const ParentPlanningScreen({super.key});

  @override
  State<ParentPlanningScreen> createState() => _ParentPlanningScreenState();
}

class _ParentPlanningScreenState extends State<ParentPlanningScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();

    // Inisialisasi locale data untuk format tanggal bahasa Indonesia
    initializeDateFormatting('id_ID', null);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final planningProvider = Provider.of<PlanningProvider>(
        context, 
        listen: false
      );
      final childProvider = Provider.of<ChildProvider>(
        context, 
        listen: false
      );
      
      if (authProvider.user != null && authProvider.user!.isParent) {
        // Fetch children to find the parent's child
        await childProvider.fetchChildren();
        
        if (childProvider.children.isNotEmpty) {
          // Get the first child associated with this parent
          final childId = childProvider.children.first.id;
          await planningProvider.fetchPlansForParent(childId);
        } else {
          // Fallback to all plans if no children found
          await planningProvider.fetchPlans();
        }
      } else {
        // For teachers, fetch all plans
        await planningProvider.fetchPlans();
      }
      
      // Load teacher data
      Provider.of<UserProvider>(context, listen: false).fetchTeachers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Aktivitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Bantuan',
            onPressed: () {
              _showHelpDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [_buildCalendar(), Expanded(child: _buildDailySchedule())],
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
            // Get dates that have activities
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
                  // Show marker if there are activities on this date
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

  // Convert DateTime to string key for map
  String _dateToKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  // Get dates that have activities
  Map<String, bool> _getEventDates(PlanningProvider provider) {
    final Map<String, bool> eventDates = {};
    
    for (final plan in provider.plans) {
      for (final activity in plan.activities) {
        final key = _dateToKey(activity.scheduledDate);
        eventDates[key] = true;
      }
    }
    
    return eventDates;
  }

  // Get activities scheduled for the selected day
  List<PlannedActivity> _getActivitiesForSelectedDay(PlanningProvider provider) {
    final activities = <PlannedActivity>[];
    
    for (final plan in provider.plans) {
      for (final activity in plan.activities) {
        if (isSameDay(activity.scheduledDate, _selectedDay)) {
          activities.add(activity);
        }
      }
    }
    
    // Sort activities by time
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
    
    return activities;
  }

  Widget _buildDailySchedule() {
    return Consumer2<PlanningProvider, ActivityProvider>(
      builder: (context, planningProvider, activityProvider, child) {
        if (planningProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (planningProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${planningProvider.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => planningProvider.fetchPlans(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        final activities = _getActivitiesForSelectedDay(planningProvider);

        if (activities.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDay),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  return _buildActivityItem(
                    context, 
                    activities[index], 
                    planningProvider, 
                    activityProvider
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    // Check if the day is today, future or past
    final now = DateTime.now();
    final isToday = isSameDay(_selectedDay, now);
    final isFuture = _selectedDay.isAfter(
      DateTime(now.year, now.month, now.day),
    );

    String message;
    IconData icon;

    if (isToday) {
      message = 'Tidak ada aktivitas yang dijadwalkan untuk hari ini';
      icon = Icons.event_note;
    } else if (isFuture) {
      message = 'Tidak ada aktivitas yang dijadwalkan untuk tanggal ini';
      icon = Icons.event_available;
    } else {
      message = 'Tidak ada aktivitas yang dijadwalkan pada tanggal ini';
      icon = Icons.event_busy;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    PlannedActivity activity,
    PlanningProvider planningProvider,
    ActivityProvider activityProvider,
  ) {
    final activityDetails = activityProvider.getActivityById(activity.activityId.toString());
    final formattedTime = activity.scheduledTime ?? 'Tidak diatur';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to detail view
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ParentPlanningDetailScreen(
                planId: activity.planId.toString(),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      formattedTime,
                      style: TextStyle(
                        color: AppTheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (activity.completed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Selesai',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Belum Selesai',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                activityDetails?.title ?? 'Aktivitas Tidak Ditemukan',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (activityDetails != null) ...[
                const SizedBox(height: 8),
                Text(
                  activityDetails.description,
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppTheme.primary),
            const SizedBox(width: 8),
            const Text('Bantuan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jadwal Aktivitas Anak',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fitur ini menunjukkan jadwal aktivitas anak Anda yang telah direncanakan oleh guru.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppTheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Titik pada kalender menunjukkan ada aktivitas'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Aktivitas sudah diselesaikan'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Belum',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Aktivitas belum diselesaikan'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Tutup', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
