import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Laravel API models and providers
import '/laravel_api/models/activity_model.dart';
import '/laravel_api/providers/activity_provider.dart';
import '/laravel_api/providers/auth_provider.dart';
import '/laravel_api/providers/api_provider.dart';

import '/screens/activities/add_activity_screen.dart';
import '/screens/activities/activity_detail_screen.dart';
import '/screens/activities/edit_activity_screen.dart';
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
  double _minAgeFilter = 3.0;
  double _maxAgeFilter = 6.0;
  bool _isInitialized = false;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchActivities();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _fetchActivities() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    debugPrint('TeacherActivitiesScreen: Fetching activities');
    
    // Make sure we're initialized only once and user is authenticated
    if (!_isInitialized && authProvider.isAuthenticated) {
      debugPrint('TeacherActivitiesScreen: User authenticated, fetching activities');
      await activityProvider.fetchActivities();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } else if (!authProvider.isAuthenticated) {
      debugPrint('TeacherActivitiesScreen: User not authenticated yet');
    }
  }

  List<ActivityModel> _getFilteredActivities(List<ActivityModel> activities) {
    debugPrint('TeacherActivitiesScreen: Filtering ${activities.length} activities');
    
    if (activities.isEmpty) {
      debugPrint('TeacherActivitiesScreen: No activities to filter');
      return [];
    }
    
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
      // Laravel Model has direct minAge and maxAge properties
      if (activity.maxAge < _minAgeFilter || activity.minAge > _maxAgeFilter) {
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
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildFilterBar(),
            Expanded(child: _buildActivityList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'activities_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddActivityScreen()),
          ).then((_) {
            // Refresh activities after returning from add screen
            Provider.of<ActivityProvider>(context, listen: false).fetchActivities();
          });
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Text(
            'Filter: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label:
                        _difficultyFilter == 'Semua'
                            ? 'Semua Tingkat'
                            : _difficultyFilter,
                    isSelected: _difficultyFilter != 'Semua',
                    onSelected: (_) => _showFilterDialog(),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Usia: ${_formatAgeDisplay(_minAgeFilter)}-${_formatAgeDisplay(_maxAgeFilter)} tahun',
                    isSelected: _minAgeFilter != 3.0 || _maxAgeFilter != 6.0,
                    onSelected: (_) => _showFilterDialog(),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Detail',
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        debugPrint('TeacherActivitiesScreen: Building activity list, loading: ${activityProvider.isLoading}');
        
        if (activityProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (activityProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: ${activityProvider.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => activityProvider.fetchActivities(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }
        
        debugPrint('TeacherActivitiesScreen: Activities count: ${activityProvider.activities.length}');

        if (activityProvider.activities.isEmpty) {
          return _buildEmptyState();
        }

        final filteredActivities = _getFilteredActivities(activityProvider.activities);
        debugPrint('TeacherActivitiesScreen: Filtered activities count: ${filteredActivities.length}');
        
        if (filteredActivities.isEmpty) {
          return _buildNoResultsState();
        }

        return RefreshIndicator(
          onRefresh: () => activityProvider.fetchActivities(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredActivities.length,
            itemBuilder: (context, index) {
              return _buildActivityCard(
                context,
                filteredActivities[index],
                index,
              );
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Tambah Aktivitas Baru'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddActivityScreen()),
              ).then((_) {
                Provider.of<ActivityProvider>(context, listen: false).fetchActivities();
              });
            },
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
                _minAgeFilter = 3.0;
                _maxAgeFilter = 6.0;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityDetailScreen(activity: activity),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActivityIcon(activity.environment),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _buildAgeAndDifficultyText(activity),
                          style: TextStyle(color: AppTheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activity.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${activity.activitySteps.fold<int>(0, (sum, step) => sum + step.steps.length)} langkah',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  _buildEnvironmentChip(activity.environment),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.edit,
                    label: 'Edit',
                    color: AppTheme.primary,
                    onTap: () => _editActivity(activity),
                  ),
                  _buildActionButton(
                    icon: Icons.delete,
                    label: 'Hapus',
                    color: Colors.red,
                    onTap: () => _deleteActivity(activity),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 50.ms * index, duration: 200.ms);
  }
  
  String _buildAgeAndDifficultyText(ActivityModel activity) {
    String ageRangeText = '${activity.minAge}-${activity.maxAge} tahun';
    return '$ageRangeText • ${_translateDifficultyToIndonesian(activity.difficulty)}';
  }

  Widget _buildActivityIcon(String environment) {
    IconData iconData;
    Color iconColor;

    switch (environment) {
      case 'Home':
        iconData = Icons.home_rounded;
        iconColor = Colors.green;
        break;
      case 'School':
        iconData = Icons.school_rounded;
        iconColor = Colors.blue;
        break;
      default: // Both
        iconData = Icons.public_rounded;
        iconColor = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
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
                            _minAgeFilter = 3.0;
                            _maxAgeFilter = 6.0;
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
                      _minAgeFilter,
                      _maxAgeFilter,
                    ),
                    min: 3.0,
                    max: 6.0,
                    divisions: 6, // 6 divisions for 0.5 increments between 3.0 and 6.0
                    labels: RangeLabels(
                      _formatAgeDisplay(_minAgeFilter),
                      _formatAgeDisplay(_maxAgeFilter),
                    ),
                    onChanged: (values) {
                      setState(() {
                        _minAgeFilter = values.start;
                        _maxAgeFilter = values.end;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '3,0 tahun',
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                      Text(
                        '6,0 tahun',
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

  Widget _buildEnvironmentChip(String environment) {
    Color chipColor;
    String chipLabel;

    switch (environment) {
      case 'Home':
        chipColor = Colors.green;
        chipLabel = 'Rumah';
        break;
      case 'School':
        chipColor = Colors.blue;
        chipLabel = 'Sekolah';
        break;
      case 'Both':
        chipColor = Colors.teal;
        chipLabel = 'Keduanya';
        break;
      default:
        chipColor = Colors.grey;
        chipLabel = 'Tidak diketahui';
    }

    return Chip(
      label: Text(
        chipLabel,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: chipColor.withOpacity(0.2),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _editActivity(ActivityModel activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditActivityScreen(activity: activity),
      ),
    ).then((_) {
      // Refresh activities after returning from edit screen
      Provider.of<ActivityProvider>(context, listen: false).fetchActivities();
    });
  }

  void _deleteActivity(ActivityModel activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Aktivitas'),
        content: Text(
          'Anda yakin ingin menghapus aktivitas "${activity.title}"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Get the scaffold messenger and context before closing the dialog
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigatorContext = context;
              
              // Close the dialog first
              Navigator.pop(context);
              
              try {
                setState(() {
                  _isInitialized = false;
                });
                
                final apiProvider = Provider.of<ApiProvider>(navigatorContext, listen: false);
                final activityProvider = Provider.of<ActivityProvider>(navigatorContext, listen: false);
                
                // Use Laravel API to delete the activity
                final result = await apiProvider.delete('activities/${activity.id}');

                if (result != null) {
                  // Refresh the activities list
                  await activityProvider.fetchActivities();
                  
                  // Only show a message if the widget is still mounted
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Aktivitas berhasil dihapus'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                } else {
                  throw Exception('Failed to delete activity');
                }
              } catch (e) {
                // Only show error if the widget is still mounted
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus aktivitas: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isInitialized = true;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // Format age to display half years correctly (3.5 -> "3,5")
  String _formatAgeDisplay(double age) {
    // Convert to string with comma as decimal separator for Indonesian format
    return age.toString().replaceAll('.', ',');
  }
}
