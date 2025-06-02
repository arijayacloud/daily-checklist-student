import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/providers/child_provider.dart';
import '/providers/activity_provider.dart';
import '/providers/notification_provider.dart';
import '/screens/activities/teacher_activities_screen.dart';
import '/screens/children/teacher_children_screen.dart';
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

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch initial data
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      childProvider.fetchChildren();
      activityProvider.fetchActivities();
      notificationProvider.fetchNotifications();
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
      const TeacherChildrenScreen(),
      const TeacherActivitiesScreen(),
      const ParentsScreen(),
      const TeacherPlanningScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar:
          _selectedIndex == 4
              ? null
              : AppBar(
                title: _getAppBarTitle(),
                actions: [
                  // // Progress Dashboard button
                  // IconButton(
                  //   icon: const Icon(Icons.dashboard),
                  //   tooltip: 'Dashboard Perkembangan Peserta Didik',
                  //   onPressed: () {
                  //     Navigator.of(
                  //       context,
                  //     ).pushNamed(ProgressDashboard.routeName);
                  //   },
                  // ),
                  const NotificationBadge(),
                  IconButton(
                    icon: const Icon(Icons.add_alert),
                    tooltip: 'Tambah Notifikasi Uji Coba',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
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
      ),
    );
  }

  Widget _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return const Text('Daftar Peserta Didik');
      case 1:
        return const Text('Daftar Aktivitas');
      case 2:
        return const Text('Data Orang Tua');
      case 3:
        return const Text('Jadwal Kegiatan');
      default:
        return const Text('Aplikasi Daftar Kegiatan TK');
    }
  }
}
