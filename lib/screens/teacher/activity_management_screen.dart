import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/activity_model.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/teacher/activity_form_screen.dart';
import '../../screens/teacher/assign_activity_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors_compat.dart';
import '../../widgets/empty_state.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ActivityManagementScreen extends StatefulWidget {
  const ActivityManagementScreen({super.key});

  @override
  State<ActivityManagementScreen> createState() =>
      _ActivityManagementScreenState();
}

class _ActivityManagementScreenState extends State<ActivityManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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

  @override
  Widget build(BuildContext context) {
    final activityProvider = Provider.of<ActivityProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Aktivitas'),
        centerTitle: false,
      ),
      body: SafeArea(
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
                  message: 'Tekan tombol + di bawah untuk membuat aktivitas.',
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
                                    (_) =>
                                        ActivityFormScreen(activity: activity),
                              ),
                            );
                          },
                          backgroundColor: AppTheme.primaryColor,
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
                          backgroundColor: AppTheme.accentColor,
                          foregroundColor: Colors.white,
                          icon: Icons.assignment_ind,
                          label: 'Assign',
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
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildEnvironmentChip(activity.environment),
                                const SizedBox(width: 8),
                                _buildDifficultyIndicator(
                                  int.parse(activity.difficulty),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      AssignActivityScreen(activity: activity),
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

  Widget _buildDifficultyIndicator(int difficulty) {
    return Row(
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < difficulty ? Icons.star : Icons.star_border,
            size: 14,
            color: index < difficulty ? Colors.amber : Colors.grey.shade400,
          );
        }),
      ],
    );
  }
}
