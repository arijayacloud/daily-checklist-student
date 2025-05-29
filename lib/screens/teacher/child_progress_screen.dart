import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/checklist_item_model.dart';
import '../../models/child_model.dart';
import '../../models/activity_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/checklist_provider.dart';
import '../../providers/activity_provider.dart';
import '../../screens/teacher/activity_management_screen.dart';
import '../../screens/teacher/teacher_activity_detail_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/checklist_item_card.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/progress_bar.dart';

class ChildProgressScreen extends StatefulWidget {
  final ChildModel child;

  const ChildProgressScreen({super.key, required this.child});

  @override
  State<ChildProgressScreen> createState() => _ChildProgressScreenState();
}

class _ChildProgressScreenState extends State<ChildProgressScreen> {
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final checklistProvider = Provider.of<ChecklistProvider>(
      context,
      listen: false,
    );
    await checklistProvider.fetchChecklistItems(widget.child.id);
  }

  @override
  Widget build(BuildContext context) {
    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Filter checklist items based on selected filter
    List<ChecklistItemModel> filteredItems = [];

    if (_filterStatus == 'all') {
      filteredItems = checklistProvider.checklistItems;
    } else if (_filterStatus == 'pending') {
      filteredItems = checklistProvider.getPendingItems();
    } else if (_filterStatus == 'completed') {
      filteredItems = checklistProvider.getCompletedItems();
    } else if (_filterStatus == 'partial') {
      filteredItems = checklistProvider.getPartialItems();
    } else if (_filterStatus == 'overdue') {
      filteredItems = checklistProvider.getOverdueItems();
    }

    // Calculate progress
    final totalItems = checklistProvider.checklistItems.length;
    final completedItems = checklistProvider.getCompletedItems().length;
    final progress = totalItems > 0 ? completedItems / totalItems : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.child.name),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ActivityManagementScreen(),
                ),
              );
            },
            tooltip: 'Assign Activity',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: Column(
            children: [
              // Child info and progress
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ChildAvatar(
                          avatarUrl: widget.child.avatarUrl,
                          radius: 30,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.child.name,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Usia: ${widget.child.age}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ProgressBar(
                      total: totalItems,
                      completed: completedItems,
                      showPercentage: true,
                    ),

                    // Home vs School progress
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildProgressCard(
                            'Home',
                            checklistProvider.checklistItems
                                .where((item) => item.homeStatus.completed)
                                .length,
                            totalItems,
                            AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildProgressCard(
                            'School',
                            checklistProvider.checklistItems
                                .where((item) => item.schoolStatus.completed)
                                .length,
                            totalItems,
                            AppTheme.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter options
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Semua'),
                    const SizedBox(width: 8),
                    _buildFilterChip('pending', 'Tertunda'),
                    const SizedBox(width: 8),
                    _buildFilterChip('partial', 'Proses'),
                    const SizedBox(width: 8),
                    _buildFilterChip('completed', 'Selesai'),
                    const SizedBox(width: 8),
                    _buildFilterChip('overdue', 'Terlambat'),
                  ],
                ),
              ),

              // Checklist items
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (checklistProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (checklistProvider.error != null) {
                      return Center(
                        child: Text(
                          'Error: ${checklistProvider.error}',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    if (filteredItems.isEmpty) {
                      String message;

                      if (checklistProvider.checklistItems.isEmpty) {
                        message = 'Belum ada aktivitas yang ditugaskan.';
                      } else {
                        message =
                            'Tidak ada aktivitas yang sesuai dengan filter yang dipilih.';
                      }

                      return EmptyState(
                        icon: Icons.assignment,
                        title: 'Tidak Ada Aktivitas',
                        message: message,
                        actionLabel: 'Tambah Aktivitas',
                        onAction: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ActivityManagementScreen(),
                            ),
                          );
                        },
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final activity = checklistProvider
                            .findActivityForChecklistItem(item.activityId);

                        if (activity == null) {
                          return Card(
                            child: ListTile(
                              title: Text('Aktivitas tidak ditemukan'),
                              subtitle: Text('ID: ${item.activityId}'),
                              leading: Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                            ),
                          );
                        }

                        return ChecklistItemCard.teacher(
                          checklistItem: item,
                          activity: activity,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => TeacherActivityDetailScreen(
                                      checklistItem: item,
                                      child: widget.child,
                                    ),
                              ),
                            );
                          },
                          onStatusUpdate: (environment, itemId) async {
                            await checklistProvider.updateCompletionStatus(
                              checklistItemId: itemId,
                              environment: environment,
                              userId: authProvider.userModel?.id ?? '',
                            );
                          },
                          userId: authProvider.userModel?.id ?? '',
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to activity assignment
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ActivityManagementScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProgressCard(
    String title,
    int completed,
    int total,
    Color color,
  ) {
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          Text(
            '$completed dari $total',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterStatus == value;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color:
            isSelected ? Theme.of(context).colorScheme.primary : Colors.black,
      ),
    );
  }
}
