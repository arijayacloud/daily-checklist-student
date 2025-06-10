import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/config.dart';
import '/laravel_api/providers/child_provider.dart';
import '/laravel_api/providers/checklist_provider.dart';
import '/laravel_api/providers/activity_provider.dart';
import '/laravel_api/models/checklist_item_model.dart';
import '/laravel_api/models/child_model.dart';
import '/widgets/progress/child_progress_card.dart';
import '/widgets/progress/progress_filter.dart';
import '/widgets/common/loading_indicator.dart';
import '/lib/theme/app_theme.dart';

class ProgressDashboard extends StatefulWidget {
  static const routeName = '/progress-dashboard';

  const ProgressDashboard({Key? key}) : super(key: key);

  @override
  State<ProgressDashboard> createState() => _ProgressDashboardState();
}

class _ProgressDashboardState extends State<ProgressDashboard> {
  bool _isInit = true;
  String _filterType = 'all'; // 'all', 'pending', 'completed', 'overdue'

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _loadData();
      _isInit = false;
    }
  }

  Future<void> _loadData() async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    final checklistProvider = Provider.of<ChecklistProvider>(
      context,
      listen: false,
    );

    // Pastikan data anak-anak sudah diambil
    await childProvider.fetchChildren();

    // Ambil data checklist untuk setiap anak
    for (final child in childProvider.children) {
      await checklistProvider.fetchChecklistItems(child.id);
    }
  }

  void _setFilterType(String filterType) {
    setState(() {
      _filterType = filterType;
    });
  }

  List<ChecklistItemModel> _getFilteredChecklistItems(
    List<ChecklistItemModel> items,
  ) {
    switch (_filterType) {
      case 'pending':
        return items
            .where((item) => !item.completed && false)
            .toList();
      case 'completed':
        return items.where((item) => item.completed).toList();
      case 'overdue':
        return items.where((item) => false).toList();
      default:
        return items;
    }
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context);
    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final activityProvider = Provider.of<ActivityProvider>(context);

    if (childProvider.isLoading) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    final children = childProvider.children;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perkembangan Peserta Didik'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          ProgressFilter(
            currentFilter: _filterType,
            onFilterChanged: _setFilterType,
          ),

          // Stats summary
          _buildStatsSummary(children, checklistProvider),

          // Child progress cards
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child:
                  children.isEmpty
                      ? const Center(
                        child: Text('Belum ada peserta didik yang terdaftar'),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: children.length,
                        itemBuilder: (ctx, index) {
                          final child = children[index];
                          final allItems = checklistProvider.items;
                          final childItems = allItems.where((item) => 
                            item.childId == child.id).toList();
                          final filteredItems = _getFilteredChecklistItems(childItems);

                          final completedCount = childItems.where((item) => 
                            item.completed).length;
                          final totalCount = childItems.length;

                          return ChildProgressCard(
                            child: child,
                            completedCount: completedCount,
                            totalCount: totalCount,
                            onTap: () {
                              // Navigate to child detail screen
                            },
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(
    List<ChildModel> children,
    ChecklistProvider checklistProvider,
  ) {
    final allItems = checklistProvider.items;
    
    final int totalActivities = allItems.length;
    final int completedActivities = allItems.where((item) => 
      item.completed).length;
    final int overdueActivities = 0;
    
    final double completionRate =
        totalActivities > 0 ? completedActivities / totalActivities : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Text(
            'Ringkasan Perkembangan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          // Custom progress indicator
          Stack(
            children: [
              // Background
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Progress
              FractionallySizedBox(
                widthFactor: completionRate,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // Percentage text
              Center(
                child: Container(
                  height: 20,
                  alignment: Alignment.center,
                  child: Text(
                    '${(completionRate * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color:
                          completionRate > 0.5
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                'Total Aktivitas',
                totalActivities.toString(),
                Icons.checklist,
              ),
              _buildStatItem(
                context,
                'Sudah Selesai',
                completedActivities.toString(),
                Icons.check_circle,
                color: Colors.green,
              ),
              _buildStatItem(
                context,
                'Terlambat',
                overdueActivities.toString(),
                Icons.warning,
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
