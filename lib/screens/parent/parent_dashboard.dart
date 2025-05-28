import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/assignment_provider.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({Key? key}) : super(key: key);

  @override
  _ParentDashboardState createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isParent && authProvider.user != null) {
      final parentId = authProvider.user!.uid;

      // Load children for parent
      Provider.of<ChildProvider>(
        context,
        listen: false,
      ).loadChildrenForParent(parentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final childProvider = Provider.of<ChildProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Orangtua'),
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
                    const SizedBox(height: 16),

                    // Children List
                    Text(
                      'Anak Anda:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),

                    // Loading state
                    if (childProvider.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (childProvider.children.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Tidak ada anak yang terdaftar. Silakan hubungi guru untuk mendaftarkan anak Anda.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    // Children list
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: childProvider.children.length,
                          itemBuilder: (context, index) {
                            final child = childProvider.children[index];
                            return _buildChildCard(context, child);
                          },
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _buildChildCard(BuildContext context, dynamic child) {
    // Ideally, this would be ChildModel type, but for testing we'll use dynamic
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Load assignments for this child
          final childId = child.id;

          Provider.of<AssignmentProvider>(
            context,
            listen: false,
          ).loadAssignmentsForChild(childId);

          // TODO: Navigate to child detail screen
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(child.avatarUrl),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('${child.age} tahun'),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios),
            ],
          ),
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
