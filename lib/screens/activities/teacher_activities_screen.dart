import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/models/activity_model.dart';
import '/providers/activity_provider.dart';
import '/screens/activities/add_activity_screen.dart';
import '/screens/activities/activity_detail_screen.dart';
import '/lib/theme/app_theme.dart';

class TeacherActivitiesScreen extends StatefulWidget {
  const TeacherActivitiesScreen({super.key});

  @override
  State<TeacherActivitiesScreen> createState() =>
      _TeacherActivitiesScreenState();
}

class _TeacherActivitiesScreenState extends State<TeacherActivitiesScreen> {
  String _searchQuery = '';
  String _difficultyFilter = 'Semua';
  int _minAgeFilter = 3;
  int _maxAgeFilter = 6;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ActivityProvider>(context, listen: false).fetchActivities();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ActivityModel> _getFilteredActivities(List<ActivityModel> activities) {
    return activities.where((activity) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final title = activity.title.toLowerCase();
        final description = activity.description.toLowerCase();
        final query = _searchQuery.toLowerCase();

        if (!title.contains(query) && !description.contains(query)) {
          return false;
        }
      }

      // Difficulty filter
      if (_difficultyFilter != 'Semua' &&
          activity.difficulty !=
              _translateDifficultyToEnglish(_difficultyFilter)) {
        return false;
      }

      // Age range filter
      if (activity.ageRange.max < _minAgeFilter ||
          activity.ageRange.min > _maxAgeFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  String _translateDifficultyToEnglish(String difficulty) {
    switch (difficulty) {
      case 'Mudah':
        return 'Easy';
      case 'Sedang':
        return 'Medium';
      case 'Sulit':
        return 'Hard';
      default:
        return difficulty;
    }
  }

  String _translateDifficultyToIndonesian(String difficulty) {
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

  String _translateEnvironmentToIndonesian(String environment) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [_buildSearchBar(), Expanded(child: _buildActivityList())],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddActivityScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari aktivitas...',
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
    );
  }

  Widget _buildActivityList() {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        if (activityProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (activityProvider.activities.isEmpty) {
          return _buildEmptyState();
        }

        final filteredActivities = _getFilteredActivities(
          activityProvider.activities,
        );

        if (filteredActivities.isEmpty) {
          return _buildNoResultsState();
        }

        return RefreshIndicator(
          onRefresh: () => activityProvider.fetchActivities(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredActivities.length,
            itemBuilder: (context, index) {
              final activity = filteredActivities[index];
              return _buildActivityCard(context, activity, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
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
            'Belum ada aktivitas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Buat aktivitas pertama Anda dengan menekan tombol +',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppTheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada aktivitas yang sesuai',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah pencarian atau filter Anda',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _difficultyFilter = 'Semua';
                _minAgeFilter = 3;
                _maxAgeFilter = 6;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus Filter'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    ActivityModel activity,
    int index,
  ) {
    return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ActivityDetailScreen(activity: activity),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
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
                          _translateDifficultyToIndonesian(activity.difficulty),
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
                          _translateEnvironmentToIndonesian(
                            activity.environment,
                          ),
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
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${activity.ageRange.min}-${activity.ageRange.max} thn',
                          style: TextStyle(
                            color: AppTheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        activity.customSteps.isNotEmpty
                            ? '${activity.customSteps.first.steps.length} langkah'
                            : 'Tidak ada langkah',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Lihat Detail',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppTheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 500),
          delay: Duration(milliseconds: 100 * index),
        )
        .slideY(begin: 0.2, end: 0);
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Filter Aktivitas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _difficultyFilter = 'Semua';
                            _minAgeFilter = 3;
                            _maxAgeFilter = 6;
                          });
                        },
                        child: const Text('Atur Ulang'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Difficulty filter
                  const Text(
                    'Tingkat Kesulitan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Semua',
                          isSelected: _difficultyFilter == 'Semua',
                          onSelected: (selected) {
                            setState(() {
                              _difficultyFilter = 'Semua';
                            });
                          },
                        ),
                        _buildFilterChip(
                          label: 'Mudah',
                          isSelected: _difficultyFilter == 'Mudah',
                          onSelected: (selected) {
                            setState(() {
                              _difficultyFilter = 'Mudah';
                            });
                          },
                        ),
                        _buildFilterChip(
                          label: 'Sedang',
                          isSelected: _difficultyFilter == 'Sedang',
                          onSelected: (selected) {
                            setState(() {
                              _difficultyFilter = 'Sedang';
                            });
                          },
                        ),
                        _buildFilterChip(
                          label: 'Sulit',
                          isSelected: _difficultyFilter == 'Sulit',
                          onSelected: (selected) {
                            setState(() {
                              _difficultyFilter = 'Sulit';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Age range filter
                  const Text(
                    'Rentang Usia',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: RangeValues(
                      _minAgeFilter.toDouble(),
                      _maxAgeFilter.toDouble(),
                    ),
                    min: 3,
                    max: 6,
                    divisions: 3,
                    labels: RangeLabels(
                      _minAgeFilter.toString(),
                      _maxAgeFilter.toString(),
                    ),
                    onChanged: (values) {
                      setState(() {
                        _minAgeFilter = values.start.round();
                        _maxAgeFilter = values.end.round();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '3 tahun',
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                      Text(
                        '6 tahun',
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Apply button
                  ElevatedButton(
                    onPressed: () {
                      this.setState(() {
                        // Update the parent state
                        this._difficultyFilter = _difficultyFilter;
                        this._minAgeFilter = _minAgeFilter;
                        this._maxAgeFilter = _maxAgeFilter;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'Terapkan Filter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: onSelected,
        selectedColor: AppTheme.primaryContainer,
        checkmarkColor: AppTheme.onPrimaryContainer,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.onPrimaryContainer : AppTheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
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
