import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../parent/child_checklist_screen.dart';
import '../parent/parent_profile_screen.dart';
import '../../core/theme/app_colors_compat.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/empty_state.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboard();
}

class _ParentDashboard extends State<ParentDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final childProvider = Provider.of<ChildProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      childProvider.loadChildrenForParent(authProvider.userModel!.id);
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
      const ParentProfileScreen(),
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
    final authProvider = Provider.of<AuthProvider>(context);
    final childProvider = Provider.of<ChildProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Anak Saya'), centerTitle: false),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (authProvider.userModel != null) {
              childProvider.loadChildrenForParent(authProvider.userModel!.id);
            }
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
                    style: TextStyle(color: AppColors.error),
                  ),
                );
              }

              if (childProvider.children.isEmpty) {
                return const EmptyState(
                  icon: Icons.child_care,
                  title: 'Tidak Ada Anak',
                  message:
                      'Silakan hubungi guru untuk menambahkan anak ke akun Anda.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: childProvider.children.length,
                itemBuilder: (context, index) {
                  final child = childProvider.children[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChildChecklistScreen(child: child),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            ChildAvatar(avatarUrl: child.avatarUrl, radius: 30),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    child.name,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Usia: ${child.age}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
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
