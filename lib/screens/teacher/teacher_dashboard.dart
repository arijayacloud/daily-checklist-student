import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../screens/teacher/activity_management_screen.dart';
import '../../screens/teacher/child_management_screen.dart';
import '../../screens/teacher/child_progress_screen.dart';
import '../../screens/teacher/teacher_profile_screen.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/empty_state.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      childProvider.loadChildrenForTeacher(authProvider.userModel!.id);
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const ChildrenListPage(),
      const ActivityManagementScreen(),
      const TeacherProfileScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Aktivitas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class ChildrenListPage extends StatelessWidget {
  const ChildrenListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Siswa'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ChildManagementScreen(),
                ),
              );
            },
            tooltip: 'Kelola Siswa',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final childProvider = Provider.of<ChildProvider>(
              context,
              listen: false,
            );
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );

            if (authProvider.userModel != null) {
              childProvider.loadChildrenForTeacher(authProvider.userModel!.id);
            }
            // Return completed future untuk RefreshIndicator
            return Future.value();
          },
          child: Builder(
            builder: (context) {
              if (childProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (childProvider.errorMessage.isNotEmpty) {
                return Center(
                  child: Text(
                    'Error: ${childProvider.errorMessage}',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              if (childProvider.children.isEmpty) {
                return const EmptyState(
                  icon: Icons.child_care,
                  title: 'Tidak Ada Siswa',
                  message: 'Tekan tombol + di bawah untuk menambahkan siswa.',
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: childProvider.children.length,
                itemBuilder: (context, index) {
                  final child = childProvider.children[index];

                  return Card(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChildProgressScreen(child: child),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ChildAvatar(avatarUrl: child.avatarUrl, radius: 40),
                            const SizedBox(height: 16),
                            Text(
                              child.name,
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Usia: ${child.age}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (_) =>
                                            ChildProgressScreen(child: child),
                                  ),
                                );
                              },
                              child: const Text('Lihat Progres'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
