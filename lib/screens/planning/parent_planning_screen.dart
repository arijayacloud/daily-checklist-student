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
  bool _isLoading = false;
  int? _updatingActivityId; // Track which activity is being updated
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  
  // Mapping for day of week names in Indonesian
  final Map<int, String> _weekdayNames = {
    1: 'Sen',
    2: 'Sel',
    3: 'Rab',
    4: 'Kam',
    5: 'Jum',
    6: 'Sab',
    7: 'Min',
  };
  
  // Mapping for month names in Indonesian
  final Map<int, String> _monthNames = {
    1: 'Januari',
    2: 'Februari',
    3: 'Maret',
    4: 'April',
    5: 'Mei',
    6: 'Juni',
    7: 'Juli',
    8: 'Agustus',
    9: 'September',
    10: 'Oktober',
    11: 'November',
    12: 'Desember',
  };

  @override
  void initState() {
    super.initState();

    // Inisialisasi locale data untuk format tanggal bahasa Indonesia
    initializeDateFormatting('id_ID', null);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadPlans();
      
      // Pre-fetch activities for better user experience
      await Provider.of<ActivityProvider>(context, listen: false).fetchActivities();
    });
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
      final childProvider = Provider.of<ChildProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Make sure we have the latest user data
      if (authProvider.user == null) {
        debugPrint("ParentPlanningScreen: Tidak ditemukan pengguna yang terautentikasi");
        return;
      }
      
      debugPrint("ParentPlanningScreen: Memuat rencana untuk peran pengguna: ${authProvider.user!.role}");
      
      // Try to load teacher data in the background but don't block if it fails
      try {
        userProvider.fetchTeachers();
      } catch (teacherError) {
        debugPrint("ParentPlanningScreen: Tidak dapat memuat data guru: $teacherError");
        // Continue with the rest of the method - teacher data is not critical
      }
      
      if (authProvider.user!.isParent) {
        // Fetch children first
        await childProvider.fetchChildren();
        
        if (childProvider.children.isEmpty) {
          debugPrint("ParentPlanningScreen: Tidak ditemukan anak untuk orang tua ini");
          
          // Show message
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Tidak ditemukan data anak untuk akun ini'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
        
        debugPrint("ParentPlanningScreen: Ditemukan ${childProvider.children.length} anak, memuat rencana untuk anak pertama");
        
        // Get the first child associated with this parent and fetch their plans
        final childId = childProvider.children.first.id;
        
        // Use the new unified fetchPlans method with childId parameter
        // Add a timeout to prevent infinite loading
        await planningProvider.fetchPlans(childId: childId).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint("ParentPlanningScreen: Timeout fetching plans");
            return;
          },
        );
        
        debugPrint("ParentPlanningScreen: Berhasil memuat ${planningProvider.plans.length} rencana untuk anak dengan ID $childId");
      } else {
        // For other roles like teachers, fetch all plans
        await planningProvider.fetchPlans().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint("ParentPlanningScreen: Timeout fetching plans");
            return;
          },
        );
      }
    } catch (e) {
      debugPrint("ParentPlanningScreen: Error memuat rencana - $e");
      
      // Show error message if mounted
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        body: Column(
          children: [
            _buildChildSelector(),
            _buildCalendar(), 
            Expanded(child: _buildDailySchedule())
          ],
        ),
      ),
    );
  }

  Widget _buildChildSelector() {
    return Consumer2<ChildProvider, PlanningProvider>(
      builder: (context, childProvider, planningProvider, _) {
        // If there's only one child or no children, don't show the selector
        if (childProvider.children.length <= 1) {
          return const SizedBox.shrink();
        }
        
        // Get current child ID or use the first available child
        final currentChildId = planningProvider.currentChildId ?? childProvider.children.first.id;
        
        // Find the current child
        final currentChild = childProvider.children.firstWhere(
          (child) => child.id == currentChildId,
          orElse: () => childProvider.children.first,
        );
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.child_care, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Anak:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: currentChildId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down),
                      items: childProvider.children.map((child) {
                        return DropdownMenuItem<String>(
                          value: child.id,
                          child: Text(
                            child.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (childId) {
                        if (childId != null && childId != planningProvider.currentChildId) {
                          // Set the selected child
                          planningProvider.setCurrentChildId(childId);
                          
                          // Fetch plans for the selected child
                          planningProvider.fetchPlans(childId: childId);
                          
                          // Reset selected day to today when changing child
                          setState(() {
                            _selectedDay = DateTime.now();
                            _focusedDay = DateTime.now();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
              locale: 'id_ID',
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
                formatButtonTextStyle: TextStyle(color: AppTheme.onPrimaryContainer),
                formatButtonDecoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                formatButtonVisible: true,
                titleCentered: true,
                titleTextFormatter: (date, locale) {
                  // Custom formatter for month-year in the header
                  final monthName = _monthNames[date.month] ?? '';
                  return '$monthName ${date.year}';
                },
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: AppTheme.onSurface),
                weekendStyle: TextStyle(color: AppTheme.primary),
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
                dowBuilder: (context, day) {
                  // Custom day of week labels (Mon, Tue, etc)
                  final weekdayName = _weekdayNames[day.weekday] ?? '';
                  final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
                  
                  return Center(
                    child: Text(
                      weekdayName,
                      style: TextStyle(
                        color: isWeekend ? AppTheme.primary : AppTheme.onSurface,
                      ),
                    ),
                  );
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
        // Only use local loading state to avoid infinite loading from provider states
        // Show loading indicator during initial loading only
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error message if there's an error
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
                  onPressed: _loadPlans,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        // Check if activities data is loaded
        if (activityProvider.activities.isEmpty) {
          // Try to load activities if not already loading
          if (!activityProvider.isLoading) {
            Future.microtask(() => activityProvider.fetchActivities().timeout(
              const Duration(seconds: 5),
              onTimeout: () => null,
            ));
          }
          
          // Show loading indicator or empty state
          return Center(
            child: activityProvider.isLoading
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text(
                        'Tidak dapat memuat data aktivitas. Silakan coba lagi.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => activityProvider.fetchActivities(),
                        child: const Text('Muat Aktivitas'),
                      ),
                    ],
                  ),
          );
        }

        // Get activities for selected day
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
    final bool isUpdating = _updatingActivityId == activity.id;

    // Get current plan for this activity to show more details
    final plan = planningProvider.plans.firstWhere(
      (p) => p.id == activity.planId,
      orElse: () => Planning(
        id: activity.planId, 
        type: 'daily',
        teacherId: '',
        startDate: activity.scheduledDate,
        activities: [],
      ),
    );
    
    // Get completion status for current child if available
    final String? childId = planningProvider.currentChildId;
    final bool isCompletedByChild = childId != null ? 
      activity.isCompletedByChild(childId) : activity.completed;
    
    // Get background color based on plan type for visual distinction
    final Color planColor = plan.type == 'weekly' ? 
      Colors.blue.withOpacity(0.05) : Colors.green.withOpacity(0.05);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          // Navigate to detail view
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ParentPlanningDetailScreen(
                planId: activity.planId.toString(),
                childId: childId,
              ),
            ),
          );
          
          // Refresh data when coming back from detail screen, but without full reload
          // Use Future.delayed to make sure this doesn't run during build
          if (mounted) {
            Future.delayed(Duration.zero, () {
              setState(() {
                // Refresh but don't show loading indicator
                final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
                planningProvider.fetchPlanWithCompletionData(activity.planId);
              });
            });
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: planColor,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with time and status indicators
              Row(
                children: [
                  // Time container
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
                  
                  // Plan type indicator
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: plan.type == 'weekly' ? 
                        Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: plan.type == 'weekly' ? Colors.blue : Colors.green,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      plan.type == 'weekly' ? 'Mingguan' : 'Harian',
                      style: TextStyle(
                        fontSize: 10,
                        color: plan.type == 'weekly' ? Colors.blue : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  // Show checkbox for Home or Both activities
                  if (_canParentUpdateActivity(activityDetails))
                    isUpdating 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2)
                        )
                      : Checkbox(
                      value: isCompletedByChild,
                      onChanged: (value) async {
                        if (mounted) {
                          setState(() {
                            _updatingActivityId = activity.id;
                          });
                          
                          try {
                            // Store the current child ID as a local variable before API call
                            final childId = planningProvider.currentChildId;
                            if (childId == null || childId.isEmpty) {
                              throw Exception('Tidak dapat menentukan ID anak');
                            }
                            
                            final success = await planningProvider.markActivityAsCompleted(
                              activity.id!,
                              value ?? false,
                              childId: childId
                            );
                            
                            // If successful, refresh data
                            if (success) {
                              // Refresh the specific plan instead of all plans for better performance
                              await planningProvider.fetchPlanWithCompletionData(activity.planId);
                            }
                            
                            if (mounted) {
                              setState(() {
                                _updatingActivityId = null;
                              });
                              
                              if (success) {
                                _scaffoldMessengerKey.currentState?.showSnackBar(
                                  SnackBar(
                                    content: Text(value == true 
                                      ? 'Aktivitas ditandai selesai' 
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
                    )
                  else if (isCompletedByChild)
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
              const SizedBox(height: 8),
              // Add a subtle plan identifier
              Row(
                children: [
                  Icon(
                    Icons.account_tree_outlined, 
                    size: 12, 
                    color: AppTheme.onSurfaceVariant.withOpacity(0.5)
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Plan #${activity.planId}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                  if (_canParentUpdateActivity(activityDetails)) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.home_outlined, 
                      size: 12, 
                      color: Colors.green.withOpacity(0.6)
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Dapat diselesaikan di rumah',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.withOpacity(0.6),
                      ),
                    ),
                  ]
                ],
              ),
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

  // Helper to check if parent can update activity
  bool _canParentUpdateActivity(ActivityModel? activity) {
    if (activity == null) return false;
    
    // Parents can update activities with environment 'Home' or 'Both'
    return activity.environment == 'Home' || activity.environment == 'Both';
  }
}
