import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/child_model.dart';
import '/providers/auth_provider.dart';
import '/providers/child_provider.dart';
import '/providers/checklist_provider.dart';
import '/screens/checklist/parent_checklist_screen.dart';
import '/screens/planning/parent_planning_screen.dart';
import '/screens/profile/profile_screen.dart';
import '/lib/theme/app_theme.dart';
import '/widgets/home/child_avatar.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _selectedIndex = 0;
  late ChildProvider _childProvider;

  @override
  void initState() {
    super.initState();
    _childProvider = Provider.of<ChildProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _childProvider.fetchChildren();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ParentDashboardTab(),
      const ParentPlanningScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
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
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Jadwal',
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

class ParentDashboardTab extends StatelessWidget {
  const ParentDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final childProvider = Provider.of<ChildProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => authProvider.signOut(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body:
          childProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : childProvider.children.isEmpty
              ? _buildEmptyState()
              : _buildChildrenGrid(context, childProvider.children),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.child_care,
            size: 80,
            color: AppTheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No children found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please contact your teacher to add your children',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenGrid(BuildContext context, List<ChildModel> children) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) {
          return _buildChildCard(context, children[index])
              .animate()
              .fadeIn(
                duration: const Duration(milliseconds: 500),
                delay: Duration(milliseconds: 100 * index),
              )
              .slideY(begin: 0.2, end: 0);
        },
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, ChildModel child) {
    return GestureDetector(
      onTap: () {
        // Load checklist items for this child
        Provider.of<ChecklistProvider>(
          context,
          listen: false,
        ).fetchChecklistItems(child.id);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ParentChecklistScreen(child: child),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ChildAvatar(child: child, size: 70),
              const SizedBox(height: 8),
              Text(
                child.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${child.age} years old',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'View Activities',
                  style: TextStyle(
                    color: AppTheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
