import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/activity_provider.dart';
import '../../models/activity_model.dart';
import 'add_activity_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _searchController = TextEditingController();
  String _selectedEnvironment = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActivities();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadActivities() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      Provider.of<ActivityProvider>(
        context,
        listen: false,
      ).loadActivities(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityProvider = Provider.of<ActivityProvider>(context);
    final activities = activityProvider.activities;

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Aktivitas')),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari aktivitas...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    activityProvider.setSearchQuery(value);
                  },
                ),
                const SizedBox(height: 8),

                // Filter by Environment
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Filter Lingkungan: '),
                      const SizedBox(width: 8),
                      _buildFilterChip('Semua', ''),
                      _buildFilterChip('Rumah', 'home'),
                      _buildFilterChip('Sekolah', 'school'),
                      _buildFilterChip('Keduanya', 'both'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Activity List
          Expanded(
            child:
                activityProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : activities.isEmpty
                    ? const Center(
                      child: Text(
                        'Belum ada aktivitas. Tambahkan aktivitas baru.',
                      ),
                    )
                    : ListView.builder(
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        return _buildActivityCard(context, activity);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddActivityScreen()),
          ).then((_) => _loadActivities());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final activityProvider = Provider.of<ActivityProvider>(context);
    final isSelected = _selectedEnvironment == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedEnvironment = selected ? value : '';
          });
          activityProvider.setEnvironmentFilter(selected ? value : '');
        },
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, ActivityModel activity) {
    // Fungsi untuk mendapatkan label environment
    String getEnvironmentLabel(String env) {
      switch (env) {
        case 'home':
          return 'Rumah';
        case 'school':
          return 'Sekolah';
        case 'both':
          return 'Rumah & Sekolah';
        default:
          return 'Tidak diketahui';
      }
    }

    // Fungsi untuk mendapatkan label tingkat kesulitan
    String getDifficultyLabel(String difficulty) {
      switch (difficulty) {
        case 'easy':
          return 'Mudah';
        case 'medium':
          return 'Sedang';
        case 'hard':
          return 'Sulit';
        default:
          return 'Tidak diketahui';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(activity.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lingkungan: ${getEnvironmentLabel(activity.environment)}'),
            Text(
              'Tingkat Kesulitan: ${getDifficultyLabel(activity.difficulty)}',
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              // TODO: Navigate to edit screen
            } else if (value == 'delete') {
              _confirmDelete(context, activity);
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
        ),
        onTap: () {
          // TODO: Show activity details
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ActivityModel activity,
  ) async {
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text(
              'Apakah Anda yakin ingin menghapus aktivitas "${activity.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (result == true) {
      await activityProvider.deleteActivity(activity.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aktivitas "${activity.title}" berhasil dihapus'),
          ),
        );
      }
    }
  }
}
