import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/activity_model.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/teacher/activity_form_screen.dart';
import '../../screens/teacher/assign_activity_screen.dart';
import '../../screens/teacher/teacher_activity_detail_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors_compat.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/filter_chip_group.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ActivityManagementScreen extends StatefulWidget {
  const ActivityManagementScreen({super.key});

  @override
  State<ActivityManagementScreen> createState() =>
      _ActivityManagementScreenState();
}

class _ActivityManagementScreenState extends State<ActivityManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  final List<String> _environmentOptions = ['home', 'school', 'both'];
  final List<String> _difficultyOptions = ['easy', 'medium', 'hard'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      activityProvider.loadActivities(authProvider.userModel!.id);
    } else {
      // Handle the case when userModel is null
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelete(ActivityModel activity) async {
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );

    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Aktivitas'),
            content: Text(
              'Apakah Anda yakin ingin menghapus aktivitas "${activity.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      final success = await activityProvider.deleteActivity(activity.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aktivitas berhasil dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityProvider = Provider.of<ActivityProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Aktivitas'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: Icon(
              activityProvider.showAllActivities
                  ? Icons.visibility
                  : Icons.visibility_off,
            ),
            onPressed: () {
              if (authProvider.userModel != null) {
                activityProvider.toggleShowAllActivities(
                  authProvider.userModel!.id,
                );
              }
            },
            tooltip:
                activityProvider.showAllActivities
                    ? 'Tampilkan Semua Aktivitas'
                    : 'Tampilkan Aktivitas Saya',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari aktivitas...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              activityProvider.setSearchQuery('');
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  activityProvider.setSearchQuery(value);
                },
              ),
            ),
            if (_showFilters) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lingkungan',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    FilterChipGroup(
                      options: _environmentOptions,
                      labels: const ['Rumah', 'Sekolah', 'Keduanya'],
                      selectedValue: activityProvider.filterEnvironment,
                      onSelected: (value) {
                        activityProvider.setEnvironmentFilter(value ?? '');
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tingkat Kesulitan',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    FilterChipGroup(
                      options: _difficultyOptions,
                      labels: const ['Mudah', 'Sedang', 'Sulit'],
                      selectedValue: activityProvider.filterDifficulty,
                      onSelected: (value) {
                        activityProvider.setDifficultyFilter(value ?? '');
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Rentang Usia',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    RangeSlider(
                      values:
                          activityProvider.ageRangeFilter ??
                          const RangeValues(3, 6),
                      min: 3,
                      max: 6,
                      divisions: 3,
                      labels: RangeLabels(
                        '${(activityProvider.ageRangeFilter?.start ?? 3).toInt()} tahun',
                        '${(activityProvider.ageRangeFilter?.end ?? 6).toInt()} tahun',
                      ),
                      onChanged: (RangeValues values) {
                        activityProvider.setAgeRangeFilter(values);
                      },
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton.icon(
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Reset Filter'),
                        onPressed: () {
                          activityProvider.resetFilters();
                          _searchController.clear();
                        },
                      ),
                    ),
                    const Divider(),
                  ],
                ),
              ),
            ],
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: Builder(
                  builder: (context) {
                    if (activityProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (activityProvider.errorMessage.isNotEmpty) {
                      return Center(
                        child: Text(
                          'Error: ${activityProvider.errorMessage}',
                          style: TextStyle(color: AppColors.error),
                        ),
                      );
                    }

                    if (activityProvider.activities.isEmpty) {
                      return const EmptyState(
                        icon: Icons.assignment,
                        title: 'Tidak Ada Aktivitas',
                        message:
                            'Tekan tombol + di bawah untuk membuat aktivitas.',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: activityProvider.activities.length,
                      itemBuilder: (context, index) {
                        final activity = activityProvider.activities[index];

                        return Slidable(
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ActivityFormScreen(
                                            activity: activity,
                                          ),
                                    ),
                                  );
                                },
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                icon: Icons.edit,
                                label: 'Edit',
                              ),
                              SlidableAction(
                                onPressed: (context) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (_) => AssignActivityScreen(
                                            activity: activity,
                                          ),
                                    ),
                                  );
                                },
                                backgroundColor: AppColors.accentColor,
                                foregroundColor: Colors.white,
                                icon: Icons.assignment_ind,
                                label: 'Assign',
                              ),
                              SlidableAction(
                                onPressed:
                                    (context) => _confirmDelete(activity),
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Hapus',
                              ),
                            ],
                          ),
                          child: Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                activity.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    activity.description,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildEnvironmentChip(
                                        activity.environment,
                                      ),
                                      _buildDifficultyIndicator(
                                        activity.difficulty,
                                      ),
                                      _buildAgeRangeChip(activity.ageRange),
                                      if (activity.nextActivityId != null)
                                        _buildFollowUpChip(),
                                      if (activity.customSteps.isNotEmpty)
                                        _buildCustomStepsChip(
                                          activity.customSteps.length,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (_) => TeacherActivityDetailScreen(
                                          activity: activity,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ActivityFormScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEnvironmentChip(String environment) {
    Color color;
    String label;

    switch (environment) {
      case 'home':
        color = AppColors.home;
        label = 'Rumah';
        break;
      case 'school':
        color = AppColors.school;
        label = 'Sekolah';
        break;
      case 'both':
        color = AppColors.both;
        label = 'Keduanya';
        break;
      default:
        color = Colors.grey;
        label = 'Tidak Diketahui';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }

  Widget _buildDifficultyIndicator(String difficulty) {
    // Konversi string difficulty ke jumlah bintang
    int stars;
    Color color;

    switch (difficulty) {
      case 'easy':
        stars = 1;
        color = Colors.green;
        break;
      case 'medium':
        stars = 3;
        color = Colors.orange;
        break;
      case 'hard':
        stars = 5;
        color = Colors.red;
        break;
      default:
        // Coba parse sebagai number jika formatnya numeric
        try {
          stars = int.parse(difficulty);
          if (stars <= 2) {
            color = Colors.green;
          } else if (stars <= 4) {
            color = Colors.orange;
          } else {
            color = Colors.red;
          }
        } catch (e) {
          stars = 1; // Default jika tidak bisa diparse
          color = Colors.green;
        }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            stars <= 2 ? 'Mudah' : (stars <= 4 ? 'Sedang' : 'Sulit'),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeRangeChip(AgeRange ageRange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info),
      ),
      child: Text(
        '${ageRange.min}-${ageRange.max} tahun',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.info),
      ),
    );
  }

  Widget _buildFollowUpChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.next_plan, size: 14, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            'Lanjutan',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomStepsChip(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.format_list_numbered, size: 14, color: Colors.purple),
          const SizedBox(width: 4),
          Text(
            '$count Langkah',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.purple),
          ),
        ],
      ),
    );
  }
}
