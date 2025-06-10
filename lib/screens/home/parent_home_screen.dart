import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Laravel API providers and models
import '/laravel_api/models/child_model.dart';
import '/laravel_api/providers/auth_provider.dart';
import '/laravel_api/providers/child_provider.dart';
import '/laravel_api/providers/activity_provider.dart';
import '/laravel_api/providers/notification_provider.dart';
import '/laravel_api/providers/planning_provider.dart';

// Screens and widgets
import '/screens/checklist/parent_checklist_screen.dart';
import '/screens/planning/parent_planning_screen.dart';
import '/screens/profile/profile_screen.dart';
import '/screens/notification/notification_screen.dart';
import '/screens/children/parent_children_screen.dart';
import '/lib/theme/app_theme.dart';
import '/widgets/home/child_avatar.dart';
import '/widgets/notification_badge.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    
    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Laravel providers
      final childProvider = Provider.of<ChildProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(
        context, 
        listen: false
      );
      final planningProvider = Provider.of<PlanningProvider>(
        context, 
        listen: false
      );
      
      childProvider.fetchChildren();
      notificationProvider.fetchNotifications();
      
      // TODO: Implement daily reminder for Laravel when ready
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
      const ParentChildrenScreen(),
      const ParentPlanningScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar:
          _selectedIndex != 2
              ? AppBar(
                title: Text(
                  _selectedIndex == 0 ? 'Anak Saya' : 'Jadwal Aktivitas',
                ),
                actions: [const NotificationBadge()],
              )
              : null,
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
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
