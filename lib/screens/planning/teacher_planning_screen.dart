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
import '/screens/planning/add_plan_screen.dart';
import '/lib/theme/app_theme.dart';
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
      body: Column(
        children: [_buildCalendar(), Expanded(child: _buildDailySchedule())],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'planning_fab',
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

  // Mendapatkan aktivitas yang dijadwalkan pada hari yang dipilih
  Map<String, bool> _getEventDates(PlanningProvider planningProvider) {
    final Map<String, bool> result = {};
    
    for (final plan in planningProvider.plans) {
      for (final activity in plan.activities) {
        final key = _dateToKey(activity.scheduledDate);
        result[key] = true;
      }
    }
    
    return result;
  }
  
  // Mendapatkan semua aktivitas pada hari yang dipilih
  List<PlannedActivity> _getActivitiesForSelectedDay(PlanningProvider planningProvider) {
    final activities = <PlannedActivity>[];
    
    for (final plan in planningProvider.plans) {
      for (final activity in plan.activities) {
        if (isSameDay(activity.scheduledDate, _selectedDay)) {
          activities.add(activity);
        }
      }
    }
    
    // Filter berdasarkan status jika diperlukan
    if (_filterStatus != 'all') {
      return activities.where((activity) {
        return _filterStatus == 'completed' ? activity.completed : !activity.completed;
      }).toList();
    }
    
    return activities;
  }

  Widget _buildDailySchedule() {
    return Consumer<PlanningProvider>(
      builder: (context, planningProvider, child) {
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
            _buildStatusFilter(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  return _buildActivityItem(context, activities[index], planningProvider);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Filter: '),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Semua'),
            selected: _filterStatus == 'all',
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _filterStatus = 'all';
                });
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Selesai'),
            selected: _filterStatus == 'completed',
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _filterStatus = 'completed';
                });
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Belum'),
            selected: _filterStatus == 'pending',
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _filterStatus = 'pending';
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    // Cek apakah hari adalah hari ini, masa depan atau masa lalu
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPlanScreen(selectedDate: _selectedDay),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Jadwal'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, 
    PlannedActivity activity, 
    PlanningProvider planningProvider,
  ) {
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    final activityDetails = activityProvider.getActivityById(activity.activityId.toString());
    final formattedTime = activity.scheduledTime ?? 'Tidak diatur';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to detail screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PlanningDetailScreen(
                planId: activity.planId,
                activities: planningProvider.plans
                    .firstWhere((plan) => plan.id == activity.planId)
                    .activities,
                selectedDate: _selectedDay,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
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
                      activityDetails?.title ?? 'Aktivitas Tidak Ditemukan',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Waktu: $formattedTime',
                      style: TextStyle(
                        color: AppTheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: activity.completed,
                onChanged: (value) {
                  planningProvider.markActivityAsCompleted(
                    activity.id!,
                    value ?? false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
