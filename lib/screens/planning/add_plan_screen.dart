import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/activity_model.dart';
import '/models/child_model.dart';
import '/models/planning_model.dart';
import '/providers/activity_provider.dart';
import '/providers/child_provider.dart';
import '/providers/planning_provider.dart';
import '/lib/theme/app_theme.dart';

class AddPlanScreen extends StatefulWidget {
  final DateTime selectedDate;

  const AddPlanScreen({super.key, required this.selectedDate});

  @override
  State<AddPlanScreen> createState() => _AddPlanScreenState();
}

class _AddPlanScreenState extends State<AddPlanScreen> {
  final List<PlannedActivity> _activities = [];
  String? _selectedChildId;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Plan')),
      body: Column(
        children: [
          _buildDateHeader(),
          _buildChildSelector(),
          Expanded(child: _buildActivityList()),
          _buildAddButton(),
        ],
      ),
      bottomNavigationBar: _buildSaveButton(),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryContainer.withOpacity(0.3),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: AppTheme.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Planning for:', style: TextStyle(fontSize: 14)),
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(widget.selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector() {
    return Consumer<ChildProvider>(
      builder: (context, childProvider, child) {
        if (childProvider.children.isEmpty) {
          return const SizedBox.shrink();
        }

        final children = childProvider.children;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Child (Optional):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedChildId,
                decoration: InputDecoration(
                  hintText: 'All Children',
                  filled: true,
                  fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Children'),
                  ),
                  ...children.map((child) {
                    return DropdownMenuItem<String>(
                      value: child.id,
                      child: Text('${child.name} (${child.age} yrs)'),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedChildId = value;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityList() {
    return _activities.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _activities.length,
          itemBuilder: (context, index) {
            return _buildActivityItem(index);
          },
        );
  }

  Widget _buildEmptyState() {
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
            'No activities planned yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add activities to this plan',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(int index) {
    final plannedActivity = _activities[index];

    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        final activity = activityProvider.getActivityById(
          plannedActivity.activityId,
        );

        if (activity == null) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
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
                    IconButton(
                      icon: const Icon(Icons.edit),
                      color: AppTheme.primary,
                      onPressed: () => _editActivity(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      color: AppTheme.error,
                      onPressed: () {
                        setState(() {
                          _activities.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activity.description,
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
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
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      plannedActivity.scheduledTime ?? 'No specific time',
                      style: TextStyle(color: AppTheme.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Switch(
                      value: plannedActivity.reminder,
                      onChanged: (value) {
                        setState(() {
                          _activities[index] = PlannedActivity(
                            activityId: plannedActivity.activityId,
                            scheduledDate: plannedActivity.scheduledDate,
                            scheduledTime: plannedActivity.scheduledTime,
                            reminder: value,
                            completed: plannedActivity.completed,
                          );
                        });
                      },
                      activeColor: AppTheme.primary,
                    ),
                    Text(
                      'Reminder',
                      style: TextStyle(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _addActivity,
        icon: const Icon(Icons.add),
        label: const Text('Add Activity'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppTheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 0),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _activities.isEmpty || _isSubmitting ? null : _savePlan,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppTheme.primary,
          disabledBackgroundColor: AppTheme.primary.withOpacity(0.6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 0),
        ),
        child:
            _isSubmitting
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  'Save Plan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }

  void _addActivity() async {
    final selectedActivity = await showDialog<String>(
      context: context,
      builder: (context) => const ActivitySelectorDialog(),
    );

    if (selectedActivity != null) {
      final timeOfDay = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      setState(() {
        _activities.add(
          PlannedActivity(
            activityId: selectedActivity,
            scheduledDate: Timestamp.fromDate(widget.selectedDate),
            scheduledTime:
                timeOfDay != null
                    ? '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}'
                    : null,
            reminder: true,
          ),
        );
      });
    }
  }

  void _editActivity(int index) async {
    final plannedActivity = _activities[index];

    final timeOfDay = await showTimePicker(
      context: context,
      initialTime:
          plannedActivity.scheduledTime != null
              ? TimeOfDay(
                hour: int.parse(plannedActivity.scheduledTime!.split(':')[0]),
                minute: int.parse(plannedActivity.scheduledTime!.split(':')[1]),
              )
              : TimeOfDay.now(),
    );

    if (timeOfDay != null) {
      setState(() {
        _activities[index] = PlannedActivity(
          activityId: plannedActivity.activityId,
          scheduledDate: plannedActivity.scheduledDate,
          scheduledTime:
              '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}',
          reminder: plannedActivity.reminder,
          completed: plannedActivity.completed,
        );
      });
    }
  }

  Future<void> _savePlan() async {
    if (_activities.isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await Provider.of<PlanningProvider>(
        context,
        listen: false,
      ).createWeeklyPlan(
        startDate: widget.selectedDate,
        childId: _selectedChildId,
        activities: _activities,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan created successfully'),
          backgroundColor: AppTheme.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
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

class ActivitySelectorDialog extends StatefulWidget {
  const ActivitySelectorDialog({super.key});

  @override
  State<ActivitySelectorDialog> createState() => _ActivitySelectorDialogState();
}

class _ActivitySelectorDialogState extends State<ActivitySelectorDialog> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ActivityModel> _getFilteredActivities(List<ActivityModel> activities) {
    if (_searchQuery.isEmpty) {
      return activities;
    }

    final query = _searchQuery.toLowerCase();
    return activities.where((activity) {
      return activity.title.toLowerCase().contains(query) ||
          activity.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          children: [
            const Text(
              'Select an Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search activities...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                filled: true,
                fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<ActivityProvider>(
                builder: (context, activityProvider, child) {
                  if (activityProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (activityProvider.activities.isEmpty) {
                    return Center(
                      child: Text(
                        'No activities found',
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                    );
                  }

                  final filteredActivities = _getFilteredActivities(
                    activityProvider.activities,
                  );

                  if (filteredActivities.isEmpty) {
                    return Center(
                      child: Text(
                        'No matching activities',
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredActivities.length,
                    itemBuilder: (context, index) {
                      final activity = filteredActivities[index];

                      return ListTile(
                        title: Text(
                          activity.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          activity.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.assignment,
                            color: AppTheme.primary,
                          ),
                        ),
                        trailing: Text(
                          '${activity.ageRange.min}-${activity.ageRange.max} yrs',
                          style: TextStyle(color: AppTheme.onSurfaceVariant),
                        ),
                        onTap: () {
                          Navigator.of(context).pop(activity.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.primary),
                ),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
