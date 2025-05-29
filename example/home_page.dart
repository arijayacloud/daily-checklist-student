// class HomePage extends StatefulWidget {
//   const HomePage({Key? key}) : super(key: key);

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   int _currentIndex = 0;
//   late final List<Widget> _pages;

//   @override
//   void initState() {
//     super.initState();

//     // Initialize pages based on user role
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);

//     if (authProvider.isTeacher) {
//       _pages = [
//         const DashboardPage(),
//         const ChildrenPage(),
//         const ActivitiesPage(),
//         const ReportsPage(),
//         const ProfilePage(),
//       ];
//     } else {
//       // For parent users, we have a different set of pages
//       _pages = [
//         const DashboardPage(),
//         const ChildrenPage(), // Only shows their children
//         const ReportsPage(), // Only shows reports for their children
//         const ProfilePage(),
//       ];
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final authProvider = Provider.of<AuthProvider>(context);

//     return Scaffold(
//       body: IndexedStack(index: _currentIndex, children: _pages),
//       bottomNavigationBar: _buildBottomNavigationBar(theme, authProvider),
//     );
//   }

//   Widget _buildBottomNavigationBar(ThemeData theme, AuthProvider authProvider) {
//     if (authProvider.isTeacher) {
//       return BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: (index) => setState(() => _currentIndex = index),
//         type: BottomNavigationBarType.fixed,
//         selectedItemColor: theme.colorScheme.primary,
//         unselectedItemColor: Colors.grey,
//         showUnselectedLabels: true,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.dashboard_outlined),
//             activeIcon: Icon(Icons.dashboard),
//             label: 'Dashboard',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.child_care_outlined),
//             activeIcon: Icon(Icons.child_care),
//             label: 'Anak',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.assignment_outlined),
//             activeIcon: Icon(Icons.assignment),
//             label: 'Aktivitas',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.bar_chart_outlined),
//             activeIcon: Icon(Icons.bar_chart),
//             label: 'Laporan',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person_outline),
//             activeIcon: Icon(Icons.person),
//             label: 'Profil',
//           ),
//         ],
//       );
//     } else {
//       // Bottom navigation for parent users
//       return BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: (index) => setState(() => _currentIndex = index),
//         type: BottomNavigationBarType.fixed,
//         selectedItemColor: theme.colorScheme.primary,
//         unselectedItemColor: Colors.grey,
//         showUnselectedLabels: true,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.dashboard_outlined),
//             activeIcon: Icon(Icons.dashboard),
//             label: 'Dashboard',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.child_care_outlined),
//             activeIcon: Icon(Icons.child_care),
//             label: 'Anak Saya',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.bar_chart_outlined),
//             activeIcon: Icon(Icons.bar_chart),
//             label: 'Laporan',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person_outline),
//             activeIcon: Icon(Icons.person),
//             label: 'Profil',
//           ),
//         ],
//       );
//     }
//   }
// }
