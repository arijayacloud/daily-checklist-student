import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/assignment_provider.dart';
import 'activity_screen.dart';
import 'child_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isTeacher && authProvider.user != null) {
      final teacherId = authProvider.user!.uid;

      // Load activities
      Provider.of<ActivityProvider>(
        context,
        listen: false,
      ).loadActivities(teacherId);

      // Load children
      Provider.of<ChildProvider>(
        context,
        listen: false,
      ).loadChildrenForTeacher(teacherId);

      // Load assignments
      Provider.of<AssignmentProvider>(
        context,
        listen: false,
      ).loadAssignmentsForTeacher(teacherId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Guru'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body:
          authProvider.userModel == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Text(
                      'Selamat datang, ${authProvider.userModel!.name}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),

                    // Dashboard Menus
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildDashboardCard(
                            context,
                            'Aktivitas',
                            Icons.assignment,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ActivityScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDashboardCard(
                            context,
                            'Kelola Siswa',
                            Icons.people,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChildScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDashboardCard(
                            context,
                            'Penugasan',
                            Icons.task_alt,
                            () {
                              // TODO: Navigate to assignments
                            },
                          ),
                          _buildDashboardCard(
                            context,
                            'Progres',
                            Icons.trending_up,
                            () {
                              // TODO: Navigate to progress tracking
                            },
                          ),
                          _buildDashboardCard(
                            context,
                            'Orangtua',
                            Icons.family_restroom,
                            () {
                              // TODO: Navigate to parent management
                            },
                          ),
                          _buildDashboardCard(
                            context,
                            'Pengaturan',
                            Icons.settings,
                            () {
                              // TODO: Navigate to settings
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}
