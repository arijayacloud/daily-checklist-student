import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/checklist_item_model.dart';
import '../../models/child_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/checklist_provider.dart';
import '../../screens/parent/activity_detail_screen.dart';
import '../../core/theme/app_colors_compat.dart';
import '../../widgets/checklist_item_card.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/progress_bar.dart';

class ChildChecklistScreen extends StatefulWidget {
  final ChildModel child;

  const ChildChecklistScreen({super.key, required this.child});

  @override
  State<ChildChecklistScreen> createState() => _ChildChecklistScreenState();
}

class _ChildChecklistScreenState extends State<ChildChecklistScreen> {
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
    final partialItems = checklistProvider.getPartialItems().length;

    return Scaffold(
      appBar: AppBar(title: Text(widget.child.name), centerTitle: false),
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
                                style: Theme.of(context).textTheme.titleLarge,
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
                      partial: partialItems,
                      height: 12.0,
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
                    _buildFilterChip('pending', 'Belum'),
                    const SizedBox(width: 8),
                    _buildFilterChip('partial', 'Sebagian'),
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
                          style: TextStyle(color: AppColors.error),
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
                          // Handle case when activity not found
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Aktivitas tidak ditemukan - ID: ${item.activityId}',
                              ),
                            ),
                          );
                        }

                        return ChecklistItemCard.parent(
                          checklistItem: item,
                          activity: activity,
                          userId: authProvider.userModel!.id,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => ActivityDetailScreen(
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
                              userId: authProvider.userModel!.id,
                            );
                          },
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
    );
  }
}
