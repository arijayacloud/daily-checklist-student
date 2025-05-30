import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/models/activity_model.dart';
import '/models/checklist_item_model.dart';
import '/models/child_model.dart';
import '/providers/activity_provider.dart';
import '/providers/checklist_provider.dart';
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

class _ParentChecklistScreenState extends State<ParentChecklistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    setState(() {
      _isLoading = true;
    });

    // Fetch checklist items for this child
    await checklistProvider.fetchChecklistItems(widget.child.id);

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
      appBar: AppBar(
        title: const Text('Activities'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Pending'), Tab(text: 'Completed')],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildChildHeader(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildPendingList(), _buildCompletedList()],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildChildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryContainer.withOpacity(0.3),
      child: Row(
        children: [
          ChildAvatar(child: widget.child, size: 60),
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
                  '${widget.child.age} years old',
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
    );
  }

  Widget _buildPendingList() {
    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final activityProvider = Provider.of<ActivityProvider>(context);

    final pendingItems = checklistProvider.getPendingChecklistItems(
      widget.child.id,
    );

    if (pendingItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: AppTheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'All activities completed!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new activities',
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
        itemCount: pendingItems.length,
        itemBuilder: (context, index) {
          final item = pendingItems[index];
          final activity = activityProvider.getActivityById(item.activityId);

          if (activity == null) {
            return const SizedBox.shrink();
          }

          return _buildChecklistItem(context, item, activity)
              .animate()
              .fadeIn(
                duration: const Duration(milliseconds: 500),
                delay: Duration(milliseconds: 100 * index),
              )
              .slideY(begin: 0.2, end: 0);
        },
      ),
    );
  }

  Widget _buildCompletedList() {
    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final activityProvider = Provider.of<ActivityProvider>(context);

    final completedItems = checklistProvider.getCompletedChecklistItems(
      widget.child.id,
    );

    if (completedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: AppTheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No completed activities yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete activities to see them here',
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
        itemCount: completedItems.length,
        itemBuilder: (context, index) {
          final item = completedItems[index];
          final activity = activityProvider.getActivityById(item.activityId);

          if (activity == null) {
            return const SizedBox.shrink();
          }

          return _buildCompletedItem(context, item, activity)
              .animate()
              .fadeIn(
                duration: const Duration(milliseconds: 500),
                delay: Duration(milliseconds: 100 * index),
              )
              .slideY(begin: 0.2, end: 0);
        },
      ),
    );
  }

  Widget _buildChecklistItem(
    BuildContext context,
    ChecklistItemModel item,
    ActivityModel activity,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(
                      activity.difficulty,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getEnvironmentColor(
                      activity.environment,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
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
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(item.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        item.statusIcon,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(item.status),
                        style: TextStyle(
                          color: _getStatusColor(item.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            Text(
              'Instructions:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...activity
                .getStepsForTeacher(
                  item.customStepsUsed.isNotEmpty
                      ? item.customStepsUsed.first
                      : '',
                )
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              color: AppTheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(child: Text(entry.value)),
                      ],
                    ),
                  ),
                )
                .toList(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ObservationFormScreen(
                          child: widget.child,
                          item: item,
                          activity: activity,
                          isTeacher: false,
                        ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: const Text('Mark as Completed'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedItem(
    BuildContext context,
    ChecklistItemModel item,
    ActivityModel activity,
  ) {
    final observation =
        item.homeObservation.completed
            ? item.homeObservation
            : item.schoolObservation;

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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text('✓', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (observation.completedAt != null)
                  Text(
                    'Completed on ${_formatDate(observation.completedAt!.toDate())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
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
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Observation Notes:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            if (observation.duration != null)
              _buildInfoRow('Duration:', '${observation.duration} minutes'),
            if (observation.engagement != null)
              _buildInfoRow(
                'Engagement:',
                _getStarRating(observation.engagement!),
              ),
            if (observation.notes != null && observation.notes!.isNotEmpty)
              _buildInfoRow('Notes:', observation.notes!),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder:
                      (context) =>
                          ActivityDetailCard(activity: activity, item: item),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getStarRating(int rating) {
    return List.filled(rating, '⭐').join(' ');
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

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'in-progress':
        return 'In Progress';
      case 'pending':
        return 'Pending';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
