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
  String? _selectedChildId;
  
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
      await _loadChildrenAndPlans();
      
      // Pre-fetch activities for better user experience
      await Provider.of<ActivityProvider>(context, listen: false).fetchActivities();
    });
  }

  Future<void> _loadChildrenAndPlans() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final childProvider = Provider.of<ChildProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Make sure we have the latest user data
      if (authProvider.user == null) {
        debugPrint("ParentPlanningScreen: No authenticated user found");
        return;
      }
      
      if (!authProvider.user!.isParent) {
        debugPrint("ParentPlanningScreen: Current user is not a parent");
        return;
      }
      
      // Ensure teacher data is loaded for displaying teacher names
      userProvider.fetchTeachers();
      
      // Fetch children first
      await childProvider.fetchChildren();
      
      if (childProvider.children.isEmpty) {
        debugPrint("ParentPlanningScreen: No children found for this parent");
        
        // Show message
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('No child data found for this account'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      
      // Set the selected child ID if not already set
      if (_selectedChildId == null) {
        _selectedChildId = childProvider.children.first.id;
      }
      
      // Load plans for the selected child
      await _loadPlansForSelectedChild();
      
    } catch (e) {
      debugPrint("ParentPlanningScreen: Error loading data - $e");
      
      // Show error message if mounted
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Failed to load data: ${e.toString()}'),
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
  
  Future<void> _loadPlansForSelectedChild() async {
    if (_selectedChildId == null) return;
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
      
      // Use the new specialized parent API endpoint
      await planningProvider.fetchParentPlans(_selectedChildId!);
      
      // Set the current child ID in the provider to ensure it's used for activity completion
      planningProvider.setCurrentChildId(_selectedChildId!);
      
    } catch (e) {
      debugPrint("ParentPlanningScreen: Error loading plans - $e");
      
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Failed to load plans: ${e.toString()}'),
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
  
  void _onChildChanged(String newChildId) {
    setState(() {
      _selectedChildId = newChildId;
    });
    
    // Load plans for the newly selected child
    _loadPlansForSelectedChild();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity Planning'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadChildrenAndPlans,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => _showHelpDialog(context),
              tooltip: 'Help',
            ),
          ],
        ),
        body: Column(
          children: [
            // Child selector dropdown
            _buildChildSelector(),
            _buildCalendar(), 
            Expanded(child: _buildDailySchedule())
          ],
        ),
      ),
    );
  }
  
  Widget _buildChildSelector() {
    return Consumer<ChildProvider>(
      builder: (context, childProvider, _) {
        if (childProvider.children.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant.withOpacity(0.3),
          ),
          child: Row(
            children: [
              const Icon(Icons.child_care, size: 20),
              const SizedBox(width: 8),
              const Text('Child:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedChildId,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: childProvider.children.map((child) {
                    return DropdownMenuItem<String>(
                      value: child.id,
                      child: Text(child.name),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      _onChildChanged(value);
                    }
                  },
                ),
              ),
            ],
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
  List<PlannedActivityWithPlan> _getActivitiesForSelectedDay(PlanningProvider provider) {
    final result = <PlannedActivityWithPlan>[];
    
    for (final plan in provider.plans) {
      for (final activity in plan.activities) {
        if (isSameDay(activity.scheduledDate, _selectedDay)) {
          result.add(PlannedActivityWithPlan(
            activity: activity, 
            planId: plan.id,
            planStartDate: plan.startDate,
            planType: plan.type
          ));
        }
      }
    }
    
    // Sort activities by time
    result.sort((a, b) {
      // First by time
      if (a.activity.scheduledTime == null && b.activity.scheduledTime == null) {
        // If both have no time, sort by plan ID to separate activities with same date
        return a.planId.compareTo(b.planId);
      }
      if (a.activity.scheduledTime == null) {
        return 1;
      }
      if (b.activity.scheduledTime == null) {
        return -1;
      }
      int timeComparison = a.activity.scheduledTime!.compareTo(b.activity.scheduledTime!);
      if (timeComparison != 0) {
        return timeComparison;
      }
      // If time is the same, sort by plan ID
      return a.planId.compareTo(b.planId);
    });
    
    return result;
  }

  Widget _buildDailySchedule() {
    return Consumer2<PlanningProvider, ActivityProvider>(
      builder: (context, planningProvider, activityProvider, child) {
        // Show loading indicator if either provider is loading
        if (planningProvider.isLoading || _isLoading) {
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
                  onPressed: _loadPlansForSelectedChild,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        // Check if activities data is loaded
        if (activityProvider.activities.isEmpty) {
          // Try to load activities if not already loading
          if (!activityProvider.isLoading) {
            Future.microtask(() => activityProvider.fetchActivities());
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
                        'Could not load activity data. Please try again.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => activityProvider.fetchActivities(),
                        child: const Text('Load Activities'),
                      ),
                    ],
                  ),
          );
        }

        // Get activities for selected day
        final activitiesWithPlan = _getActivitiesForSelectedDay(planningProvider);

        if (activitiesWithPlan.isEmpty) {
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
                itemCount: activitiesWithPlan.length,
                itemBuilder: (context, index) {
                  final item = activitiesWithPlan[index];
                  
                  // Add divider between different plans with the same date
                  final needsDivider = index > 0 && 
                      item.planId != activitiesWithPlan[index - 1].planId;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (needsDivider) 
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.grey.shade300,
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  'Plan #${item.planId}', 
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.grey.shade300,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      _buildActivityItem(
                        context,
                        item.activity,
                        planningProvider,
                        activityProvider,
                      ),
                    ],
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
      message = 'No activities scheduled for today';
      icon = Icons.event_note;
    } else if (isFuture) {
      message = 'No activities scheduled for this date';
      icon = Icons.event_available;
    } else {
      message = 'No activities scheduled for this date';
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
    final formattedTime = activity.scheduledTime ?? 'Not Set';
    final bool isUpdating = _updatingActivityId == activity.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Store a reference to the provider before navigation
          final provider = planningProvider;
          
          // Navigate to detail view with plan ID and child ID
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ParentPlanningDetailScreen(
                planId: activity.planId.toString(),
                childId: _selectedChildId,
              ),
            ),
          ).then((_) {
            // Use stored provider reference instead of accessing through context
            if (mounted) {
              // Refresh plans for selected child
              if (_selectedChildId != null) {
                provider.fetchParentPlans(_selectedChildId!);
              }
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
                  // Show checkbox only for Home or Both activities
                  if (_canParentUpdateActivity(activityDetails))
                    isUpdating 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2)
                        )
                      : Checkbox(
                      value: activity.completed,
                      onChanged: (value) async {
                        if (mounted && _selectedChildId != null) {
                          setState(() {
                            _updatingActivityId = activity.id;
                          });
                          
                          try {
                            // Store the current child ID as a local variable before API call
                            final childId = _selectedChildId!;
                            
                            // Use the parent-specific API endpoint
                            final success = await planningProvider.parentUpdateActivityStatus(
                              activity.id!,
                              value ?? false,
                              childId
                            );
                            
                            if (mounted) {
                              setState(() {
                                _updatingActivityId = null;
                              });
                              
                              if (success) {
                                _scaffoldMessengerKey.currentState?.showSnackBar(
                                  SnackBar(
                                    content: Text(value == true 
                                      ? 'Activity marked as completed' 
                                      : 'Activity marked as incomplete'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
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
                    )
                  else if (activity.completed)
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
                        'Completed',
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
                        'Not Completed',
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
                activityDetails?.title ?? 'Activity Not Found',
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
                if (activityDetails.environment == 'School')
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.school, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          const Text(
                            'School Activity',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
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
            const Text('Help'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Child Activity Schedule',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'This feature shows your child\'s activity schedule planned by the teacher.',
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
                const Text('Dots on the calendar indicate scheduled activities'),
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
                    'Completed',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Activity has been completed'),
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
                    'Not Completed',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Activity is not completed yet'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: You can only update the status of Home and Both activities. School activities can only be updated by teachers.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: TextStyle(color: AppTheme.primary)),
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

// Helper class to store an activity with its plan information
class PlannedActivityWithPlan {
  final PlannedActivity activity;
  final int planId;
  final DateTime planStartDate;
  final String planType;
  
  PlannedActivityWithPlan({
    required this.activity,
    required this.planId,
    required this.planStartDate,
    required this.planType,
  });
}
