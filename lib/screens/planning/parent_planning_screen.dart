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
import '/providers/auth_provider.dart';
import '/lib/theme/app_theme.dart';
import '/screens/planning/planning_detail_screen.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final planningProvider = Provider.of<PlanningProvider>(
        context,
        listen: false,
      );
      planningProvider.fetchPlans();

      // Buat notifikasi pengingat aktivitas untuk hari ini
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        planningProvider.createActivityReminderNotification(
          childId: authProvider.user!.id,
          date: DateTime.now(),
        );
      }
    });
  }

  // Fungsi untuk menandai aktivitas sebagai selesai
  Future<void> _markAsCompleted(
    BuildContext context,
    PlannedActivity plannedActivity,
    PlanningProvider planningProvider,
  ) async {
    // Tambahkan dialog konfirmasi untuk mencegah klik yang tidak disengaja
    final bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Konfirmasi'),
                content: const Text(
                  'Apakah Anda yakin akan menandai aktivitas ini sebagai selesai?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Ya, Selesaikan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    try {
      // Tampilkan loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Memproses..."),
                ],
              ),
            ),
          );
        },
      );

      await planningProvider.markActivityAsCompleted(
        planId: plannedActivity.planId ?? '',
        activityId: plannedActivity.activityId,
        scheduledDate: plannedActivity.scheduledDate,
      );

      // Tutup dialog loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      // Force refresh UI
      setState(() {});

      // Paksa reload data dari server
      await planningProvider.fetchPlans();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktivitas berhasil ditandai selesai'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      // Tutup dialog loading jika terjadi error
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
    }
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
        children: [
          _buildCalendar(),
          _buildActivitySummary(),
          Expanded(child: _buildDailySchedule()),
        ],
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
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;

    if (userId == null) return eventDates;

    for (final plan in provider.plans) {
      if (plan.childId == null || plan.childId == userId) {
        for (final activity in plan.activities) {
          final date = activity.scheduledDate.toDate();
          final key = _dateToKey(date);
          eventDates[key] = true;
        }
      }
    }

    return eventDates;
  }

  Widget _buildActivitySummary() {
    return Consumer<PlanningProvider>(
      builder: (context, planningProvider, child) {
        // Hitung total aktivitas untuk hari ini
        final todayActivities = planningProvider.getActivitiesForDate(
          DateTime.now(),
        );
        final userId =
            Provider.of<AuthProvider>(context, listen: false).user?.id;

        if (userId == null) return const SizedBox.shrink();

        // Filter aktivitas untuk anak dari orangtua ini saja
        final filteredActivities =
            todayActivities.where((activity) {
              final plan = planningProvider.getPlanById(activity.planId ?? '');
              return plan?.childId == null || plan?.childId == userId;
            }).toList();

        final completedCount =
            filteredActivities.where((a) => a.completed).length;
        final pendingCount = filteredActivities.length - completedCount;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aktivitas Hari Ini',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        filteredActivities.length.toString(),
                        'Total',
                        AppTheme.primary,
                      ),
                      _buildStatItem(
                        completedCount.toString(),
                        'Selesai',
                        AppTheme.success,
                      ),
                      _buildStatItem(
                        pendingCount.toString(),
                        'Belum',
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Bantuan Jadwal Aktivitas'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpItem(
                  'Melihat Aktivitas',
                  'Pilih tanggal pada kalender untuk melihat aktivitas yang dijadwalkan.',
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  'Detail Aktivitas',
                  'Tekan tombol "Detail" untuk melihat informasi lengkap dan langkah-langkah aktivitas.',
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  'Menyelesaikan Aktivitas',
                  'Tekan tombol "Selesaikan" setelah aktivitas dilakukan di rumah.',
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  'Statistik',
                  'Lihat ringkasan aktivitas hari ini di bagian atas layar.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tutup'),
              ),
            ],
          ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(description),
      ],
    );
  }

  Widget _buildDailySchedule() {
    return Consumer2<PlanningProvider, ActivityProvider>(
      builder: (context, planningProvider, activityProvider, child) {
        if (planningProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final userId =
            Provider.of<AuthProvider>(context, listen: false).user?.id;
        if (userId == null) {
          return const Center(child: Text('Silakan login terlebih dahulu'));
        }

        // Filter aktivitas untuk anak dari orangtua ini saja
        final activitiesForDate =
            planningProvider.getActivitiesForDate(_selectedDay).where((
              activity,
            ) {
              final plan = planningProvider.getPlanById(activity.planId ?? '');
              return plan?.childId == null || plan?.childId == userId;
            }).toList();

        if (activitiesForDate.isEmpty) {
          return _buildEmptySchedule();
        }

        return _buildScheduleList(
          activitiesForDate,
          activityProvider.activities,
          planningProvider,
        );
      },
    );
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
        ],
      ),
    );
  }

  Widget _buildScheduleList(
    List<PlannedActivity> activities,
    List<ActivityModel> allActivities,
    PlanningProvider planningProvider,
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
                      title: 'Aktivitas Tidak Dikenal',
                      description: '',
                      environment: 'Both',
                      difficulty: 'Medium',
                      ageRange: AgeRange(min: 3, max: 6),
                      customSteps: [],
                      createdAt: Timestamp.now(),
                      createdBy: '',
                    ),
              );

              return _buildScheduleItem(
                activity,
                plannedActivity,
                planningProvider,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(
    ActivityModel activity,
    PlannedActivity plannedActivity,
    PlanningProvider planningProvider,
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
                    _getTranslatedDifficulty(activity.difficulty),
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
                    _getTranslatedEnvironment(activity.environment),
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
            if (activity.customSteps.isEmpty)
              const Text('Tidak ada langkah khusus untuk aktivitas ini.')
            else
              ...activity.customSteps.map((customStep) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Langkah-langkah dari guru ${customStep.teacherId}:',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...customStep.steps.map((stepText) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(stepText)),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                  ],
                );
              }).toList(),
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
                            : () => _markAsCompleted(
                              context,
                              plannedActivity,
                              planningProvider,
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
          ],
        ),
      ),
    );
  }

  String _getTranslatedDifficulty(String difficulty) {
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

  String _getTranslatedEnvironment(String environment) {
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
