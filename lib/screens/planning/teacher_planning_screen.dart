import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import '/config.dart';
import '/laravel_api/models/activity_model.dart';
import '/laravel_api/models/planning_model.dart';
import '/laravel_api/models/child_model.dart';
import '/laravel_api/providers/activity_provider.dart';
import '/laravel_api/providers/planning_provider.dart';
import '/laravel_api/providers/api_provider.dart';
import '/laravel_api/providers/auth_provider.dart';
import '/laravel_api/providers/child_provider.dart';
import '/screens/planning/add_plan_screen.dart';
import '/lib/theme/app_theme.dart';
import '/screens/planning/planning_detail_screen.dart';
import '/screens/planning/edit_plan_screen.dart';

class TeacherPlanningScreen extends StatefulWidget {
  const TeacherPlanningScreen({super.key});

  @override
  State<TeacherPlanningScreen> createState() => _TeacherPlanningScreenState();
}

class _TeacherPlanningScreenState extends State<TeacherPlanningScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();

    // Inisialisasi locale data untuk format tanggal bahasa Indonesia
    initializeDateFormatting('id_ID', null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlanningProvider>(context, listen: false).fetchPlans();
      Provider.of<ChildProvider>(context, listen: false).fetchChildren();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Perencanaan Aktivitas'),
        ),
        body: Column(
          children: [
            _buildCalendar(),
            Expanded(child: _buildPlansList())
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'planning_fab',
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddPlanScreen(selectedDate: _selectedDay),
              ),
            );
            
            // Refresh plans when returning from add plan screen
            if (result == true && mounted) {
              Provider.of<PlanningProvider>(context, listen: false).fetchPlans();
            }
          },
          child: const Icon(Icons.add),
        ),
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
            // Dapatkan tanggal-tanggal yang memiliki rencana
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
                  // Tampilkan marker jika ada rencana pada tanggal tersebut
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

  // Mendapatkan tanggal-tanggal yang memiliki rencana
  Map<String, bool> _getEventDates(PlanningProvider planningProvider) {
    final Map<String, bool> result = {};
    
    for (final plan in planningProvider.plans) {
      // Tandai tanggal mulai dari plan
      final key = _dateToKey(plan.startDate);
      result[key] = true;
      
      // Jika tipe weekly, tandai juga tanggal-tanggal berikutnya selama 7 hari
      if (plan.type == 'weekly') {
        for (int i = 1; i < 7; i++) {
          final nextDay = plan.startDate.add(Duration(days: i));
          final nextKey = _dateToKey(nextDay);
          result[nextKey] = true;
        }
      }
    }
    
    return result;
  }
  
  Widget _buildPlansList() {
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

        // Filter rencana berdasarkan tanggal yang dipilih
        final plansForSelectedDate = planningProvider.plans.where((plan) {
          if (plan.type == 'daily') {
            return isSameDay(plan.startDate, _selectedDay);
          } else if (plan.type == 'weekly') {
            // Untuk plan mingguan, cek apakah tanggal yang dipilih berada dalam rentang 7 hari
            final endDate = plan.startDate.add(const Duration(days: 6));
            return !_selectedDay.isBefore(plan.startDate) && 
                   !_selectedDay.isAfter(endDate);
          }
          return false;
        }).toList();
        
        if (plansForSelectedDate.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: plansForSelectedDate.length,
          itemBuilder: (context, index) {
            return _buildPlanItem(context, plansForSelectedDate[index], planningProvider);
          },
        );
      },
    );
  }
  
  Widget _buildPlanItem(
    BuildContext context, 
    Planning plan, 
    PlanningProvider planningProvider,
  ) {
    // Calculate completion stats
    int totalActivities = plan.activities.length;
    int completedActivities = plan.activities.where((a) => a.completed).length;

    // Get child count
    final childCount = plan.childIds.isEmpty 
        ? 'Semua murid' 
        : '${plan.childIds.length} murid';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Store reference to provider before navigation
          final provider = planningProvider;
          
          // Navigate to detail screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PlanningDetailScreen(
                planId: plan.id,
                activities: plan.activities,
                selectedDate: _selectedDay,
              ),
            ),
          ).then((_) {
            // Use the stored provider reference instead of Provider.of
            if (mounted) {
              // Fetch plans without using context
              provider.fetchPlans();
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editPlan(context, plan, planningProvider),
                    tooltip: 'Edit Rencana',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeletePlan(context, plan.id, planningProvider),
                    tooltip: 'Hapus Rencana',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (plan.type == 'weekly') 
                Text(
                  '${DateFormat('d MMM', 'id_ID').format(plan.startDate)} - ${DateFormat('d MMM yyyy', 'id_ID').format(plan.startDate.add(const Duration(days: 6)))}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              else
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(plan.startDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoBadge(Icons.assignment, '$totalActivities aktivitas', AppTheme.tertiary),
                  const SizedBox(width: 8),
                  _buildInfoBadge(Icons.people, childCount, AppTheme.secondary),
                ],
              ),
              
              // Show per-child progress
              if (plan.childIds.isNotEmpty)
                Consumer<ChildProvider>(
                  builder: (context, childProvider, _) {
                    final children = childProvider.children
                        .where((child) => plan.childIds.contains(child.id))
                        .toList();
                    
                    if (children.isEmpty) {
                      return const SizedBox(height: 12);
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        const Text(
                          'Progress Anak',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...children.map((child) {
                          // Use the progress data from the plan if available
                          int childCompletedCount = 0;
                          int childTotalCount = 0;
                          double percentage = 0;
                          
                          if (plan.progressByChild.containsKey(child.id)) {
                            final progress = plan.progressByChild[child.id]!;
                            childCompletedCount = progress.completed;
                            childTotalCount = progress.total;
                            percentage = progress.percentage / 100; // Convert to 0-1 range for progress bar
                          } else {
                            // Fallback to calculating progress
                            final childProgress = planningProvider.getChildProgress(child.id, plan.id);
                            childCompletedCount = childProgress['completed'] ?? 0;
                            childTotalCount = childProgress['total'] ?? 0;
                            percentage = childTotalCount > 0 
                                ? childCompletedCount / childTotalCount 
                                : 0.0;
                          }
                            
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppTheme.primaryContainer,
                                      radius: 12,
                                      child: Text(
                                        child.name.substring(0, 1),
                                        style: TextStyle(
                                          color: AppTheme.onPrimaryContainer,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      child.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getProgressColor(percentage * 100).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$childCompletedCount/$childTotalCount',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _getProgressColor(percentage * 100),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(percentage * 100)),
                                    minHeight: 4,
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
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk warna progress
  Color _getProgressColor(double percentage) {
    if (percentage < 30) {
      return Colors.red;
    } else if (percentage < 70) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
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
      message = 'Tidak ada rencana aktivitas untuk hari ini';
      icon = Icons.event_note;
    } else if (isFuture) {
      message = 'Tidak ada rencana aktivitas untuk tanggal ini';
      icon = Icons.event_available;
    } else {
      message = 'Tidak ada rencana aktivitas pada tanggal ini';
      icon = Icons.event_busy;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
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
            label: const Text('Tambah Rencana'),
          ),
        ],
      ),
    );
  }

  void _editPlan(
    BuildContext context,
    Planning plan,
    PlanningProvider planningProvider,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPlanScreen(plan: plan),
      ),
    ).then((_) {
      // Refresh plans when returning
      if (mounted) {
        planningProvider.fetchPlans();
      }
    });
  }

  void _confirmDeletePlan(
    BuildContext context,
    int planId,
    PlanningProvider planningProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Rencana'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus rencana ini? Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('BATAL'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final result = await planningProvider.deletePlan(planId);
                  if (result && mounted) {
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      const SnackBar(
                        content: Text('Rencana berhasil dihapus'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus rencana: $e'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('HAPUS'),
            ),
          ],
        );
      },
    );
  }
}

