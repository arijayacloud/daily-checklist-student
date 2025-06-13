import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Laravel API providers
import '/laravel_api/providers/auth_provider.dart';
import '/laravel_api/providers/child_provider.dart';
import '/laravel_api/providers/activity_provider.dart';
import '/laravel_api/providers/notification_provider.dart';

// Screens
import '/screens/activities/teacher_activities_screen.dart';
import '/screens/activities/add_activity_screen.dart';
import '/screens/children/teacher_children_screen.dart';
import '/screens/children/add_child_screen.dart';
import '/screens/planning/teacher_planning_screen.dart';
import '/screens/parents/parents_screen.dart';
import '/screens/profile/profile_screen.dart';
import '/screens/notification/notification_screen.dart';
import '/screens/progress/progress_dashboard.dart';
import '/lib/theme/app_theme.dart';
import '/widgets/notification_badge.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  final List<Widget> _screens = const [
    TeacherChildrenScreen(),
    TeacherActivitiesScreen(),
    ParentsScreen(),
    TeacherPlanningScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });

    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Laravel API providers
      final childProvider = Provider.of<ChildProvider>(context, listen: false);
      final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      
      childProvider.fetchChildren();
      activityProvider.fetchActivities();
      notificationProvider.fetchNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _tabController.animateTo(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          _selectedIndex == 4
              ? null
              : AppBar(
                elevation: 0,
                scrolledUnderElevation: 3,
                title: _getAppBarTitle(),
                centerTitle: true,
                actions: [
                  const NotificationBadge(),
                  const SizedBox(width: 10),
                ],
              ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.child_care_outlined),
              activeIcon: Icon(Icons.child_care),
              label: 'Peserta Didik',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Aktivitas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Orang Tua',
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
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          showUnselectedLabels: true,
          elevation: 0,
        ),
      ),
      floatingActionButton:
          _selectedIndex == 0 || _selectedIndex == 1
              ? FloatingActionButton(
                heroTag: 'teacher_home_fab',
                onPressed: () {
                  // Navigasi ke halaman tambah sesuai dengan tab yang dipilih
                  if (_selectedIndex == 0) {
                    // Navigasi ke halaman tambah anak
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddChildScreen(),
                      ),
                    );
                  } else if (_selectedIndex == 1) {
                    // Navigasi ke halaman tambah aktivitas
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddActivityScreen(),
                      ),
                    );
                  }
                },
                child: const Icon(Icons.add),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ).animate().scale(
                curve: Curves.easeOutBack,
                duration: const Duration(milliseconds: 500),
              )
              : null,
    );
  }

  Widget _getAppBarTitle() {
    final titles = [
      'Daftar Peserta Didik',
      'Daftar Aktivitas',
      'Data Orang Tua',
      'Jadwal Kegiatan',
      'Profil',
    ];

    return Text(
          titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        )
        .animate(key: ValueKey(_selectedIndex))
        .fadeIn(duration: const Duration(milliseconds: 200))
        .slideY(
          begin: 0.2,
          end: 0,
          duration: const Duration(milliseconds: 200),
        );
  }
}
