// class DashboardPage extends StatefulWidget {
//   const DashboardPage({Key? key}) : super(key: key);

//   @override
//   State<DashboardPage> createState() => _DashboardPageState();
// }

// class _DashboardPageState extends State<DashboardPage> {
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     setState(() {
//       _isLoading = true;
//     });

//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final childProvider = Provider.of<ChildProvider>(context, listen: false);
    
//     try {
//       // Load data based on user role
//       if (authProvider.isTeacher) {
//         await childProvider.getAllChildren();
//       } else {
//         // For parent users
//         final user = authProvider.currentUser;
//         if (user != null && user.childrenIds != null && user.childrenIds!.isNotEmpty) {
//           await childProvider.getChildrenByParent(user.id);
//         }
//       }
//     } catch (e) {
//       // Handle any errors
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading data: $e')),
//         );
//       }
//     }

//     if (mounted) {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final authProvider = Provider.of<AuthProvider>(context);
//     final childProvider = Provider.of<ChildProvider>(context);
    
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Dashboard'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadData,
//           ),
//         ],
//       ),
//       body: LoadingOverlay(
//         isLoading: _isLoading,
//         child: RefreshIndicator(
//           onRefresh: _loadData,
//           child: SingleChildScrollView(
//             physics: const AlwaysScrollableScrollPhysics(),
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Welcome message
//                   _buildWelcomeSection(theme, authProvider),
//                   const SizedBox(height: 24),
                  
//                   // Quick stats
//                   _buildStatsSection(theme, childProvider),
//                   const SizedBox(height: 24),
                  
//                   // Recent activities
//                   _buildRecentActivitiesSection(theme),
//                   const SizedBox(height: 24),
                  
//                   // Upcoming events
//                   _buildUpcomingEventsSection(theme),
//                   const SizedBox(height(24),
                  
//                   // Quick actions
//                   authProvider.isTeacher
//                       ? _buildTeacherQuickActions(theme)
//                       : _buildParentQuickActions(theme),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
  
//   Widget _buildWelcomeSection(ThemeData theme, AuthProvider authProvider) {
//     final user = authProvider.currentUser;
//     final greeting = _getGreeting();
    
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             theme.colorScheme.primary,
//             theme.colorScheme.primaryContainer,
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: theme.colorScheme.primary.withOpacity(0.3),
//             blurRadius: 10,
//             spreadRadius: 1,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               CircleAvatar(
//                 radius: 30,
//                 backgroundColor: Colors.white.withOpacity(0.3),
//                 child: Icon(
//                   Icons.person,
//                   size: 36,
//                   color: Colors.white,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       greeting,
//                       style: theme.textTheme.bodyLarge?.copyWith(
//                         color: Colors.white.withOpacity(0.9),
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       user?.name ?? 'User',
//                       style: theme.textTheme.headlineMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   authProvider.isTeacher
//                       ? Icons.school
//                       : Icons.family_restroom,
//                   size: 20,
//                   color: Colors.white,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   authProvider.isTeacher ? 'Guru' : 'Orang Tua',
//                   style: theme.textTheme.bodyMedium?.copyWith(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
  
//   Widget _buildStatsSection(ThemeData theme, ChildProvider childProvider) {
//     final children = childProvider.children;
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Statistik Cepat',
//           style: theme.textTheme.titleLarge?.copyWith(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),
//         Row(
//           children: [
//             _buildStatCard(
//               theme,
//               icon: Icons.child_care,
//               title: 'Anak',
//               value: children.length.toString(),
//               color: theme.colorScheme.primary,
//             ),
//             const SizedBox(width: 16),
//             _buildStatCard(
//               theme,
//               icon: Icons.assignment_turned_in,
//               title: 'Aktivitas Selesai',
//               value: '0',
//               color: theme.colorScheme.secondary,
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         Row(
//           children: [
//             _buildStatCard(
//               theme,
//               icon: Icons.assignment,
//               title: 'Aktivitas',
//               value: '0',
//               color: theme.colorScheme.tertiary,
//             ),
//             const SizedBox(width: 16),
//             _buildStatCard(
//               theme,
//               icon: Icons.pending_actions,
//               title: 'Dalam Proses',
//               value: '0',
//               color: Colors.orange,
//             ),
//           ],
//         ),
//       ],
//     );
//   }
  
//   Widget _buildStatCard(
//     ThemeData theme, {
//     required IconData icon,
//     required String title,
//     required String value,
//     required Color color,
//   }) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.1),
//               blurRadius: 5,
//               spreadRadius: 1,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(
//                 icon,
//                 size: 24,
//                 color: color,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               value,
//               style: theme.textTheme.headlineMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: theme.colorScheme.onSurface,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               title,
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color: Colors.grey,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildRecentActivitiesSection(ThemeData theme) {
//     // Placeholder for recent activities
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Aktivitas Terbaru',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 // Navigate to activities page
//               },
//               child: Text(
//                 'Lihat Semua',
//                 style: TextStyle(
//                   color: theme.colorScheme.primary,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         Card(
//           margin: EdgeInsets.zero,
//           child: ListView.separated(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: 3, // Placeholder count
//             separatorBuilder: (context, index) => const Divider(),
//             itemBuilder: (context, index) {
//               return _buildActivityListItem(theme, index);
//             },
//           ),
//         ),
//       ],
//     );
//   }
  
//   Widget _buildActivityListItem(ThemeData theme, int index) {
//     // Placeholder data
//     final titles = [
//       'Menggambar Bentuk Geometri',
//       'Menyusun Puzzle Sederhana',
//       'Membaca Cerita Pendek',
//     ];
    
//     final categories = [
//       'Kognitif',
//       'Motorik',
//       'Bahasa',
//     ];
    
//     final colors = [
//       Colors.blue,
//       Colors.green,
//       Colors.purple,
//     ];
    
//     return ListTile(
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       leading: Container(
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: colors[index].withOpacity(0.1),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Icon(
//           Icons.assignment,
//           color: colors[index],
//         ),
//       ),
//       title: Text(
//         titles[index],
//         style: theme.textTheme.titleMedium?.copyWith(
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//       subtitle: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             margin: const EdgeInsets.only(top: 4),
//             decoration: BoxDecoration(
//               color: colors[index].withOpacity(0.1),
//               borderRadius: BorderRadius.circular(4),
//             ),
//             child: Text(
//               categories[index],
//               style: theme.textTheme.bodySmall?.copyWith(
//                 color: colors[index],
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Text(
//             '2 hari yang lalu',
//             style: theme.textTheme.bodySmall?.copyWith(
//               color: Colors.grey,
//             ),
//           ),
//         ],
//       ),
//       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//       onTap: () {
//         // Navigate to activity details
//       },
//     );
//   }
  
//   Widget _buildUpcomingEventsSection(ThemeData theme) {
//     // Placeholder for upcoming events
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Kegiatan Mendatang',
//           style: theme.textTheme.titleLarge?.copyWith(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),
//         Card(
//           margin: EdgeInsets.zero,
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 _buildEventItem(
//                   theme,
//                   date: 'Senin, 12 Jun',
//                   title: 'Aktivitas Melukis dengan Jari',
//                   time: '09:00 - 10:30',
//                   color: theme.colorScheme.primary,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildEventItem(
//                   theme,
//                   date: 'Rabu, 14 Jun',
//                   title: 'Belajar Mengenal Angka',
//                   time: '08:30 - 09:30',
//                   color: theme.colorScheme.secondary,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
  
//   Widget _buildEventItem(
//     ThemeData theme, {
//     required String date,
//     required String title,
//     required String time,
//     required Color color,
//   }) {
//     return Row(
//       children: [
//         Container(
//           width: 4,
//           height: 50,
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(4),
//           ),
//         ),
//         const SizedBox(width: 16),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               date,
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color: Colors.grey,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               title,
//               style: theme.textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//         const Spacer(),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(4),
//           ),
//           child: Text(
//             time,
//             style: theme.textTheme.bodySmall?.copyWith(
//               color: color,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
  
//   Widget _buildTeacherQuickActions(ThemeData theme) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Aksi Cepat',
//           style: theme.textTheme.titleLarge?.copyWith(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             _buildQuickActionItem(
//               theme,
//               icon: Icons.add_circle_outline,
//               label: 'Tambah Anak',
//               color: theme.colorScheme.primary,
//               onTap: () {
//                 // Navigate to add child page
//               },
//             ),
//             _buildQuickActionItem(
//               theme,
//               icon: Icons.assignment_outlined,
//               label: 'Tambah Aktivitas',
//               color: theme.colorScheme.secondary,
//               onTap: () {
//                 // Navigate to add activity page
//               },
//             ),
//             _buildQuickActionItem(
//               theme,
//               icon: Icons.assessment_outlined,
//               label: 'Laporan',
//               color: theme.colorScheme.tertiary,
//               onTap: () {
//                 // Navigate to reports page
//               },
//             ),
//             _buildQuickActionItem(
//               theme,
//               icon: Icons.calendar_today_outlined,
//               label: 'Jadwal',
//               color: Colors.orange,
//               onTap: () {
//                 // Navigate to schedule page
//               },
//             ),
//           ],
//         ),
//       ],
//     );
//   }
  
//   Widget _buildParentQuickActions(ThemeData theme) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Aksi Cepat',
//           style: theme.textTheme.titleLarge?.copyWith(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             _buildQuickActionItem(
//               theme,
//               icon: Icons.child_care,
//               label: 'Profil Anak',
//               color: theme.colorScheme.primary,
//               onTap: () {
//                 // Navigate to children page
//               },
//             ),
//             _buildQuickActionItem(
//               theme,
//               icon: Icons.assessment_outlined,
//               label: 'Perkembangan',
//               color: theme.colorScheme.secondary,
//               onTap: () {
//                 // Navigate to progress page
//               },
//             ),
//             _buildQuickActionItem(
//               theme,
//               icon: Icons.message_outlined,
//               label: 'Pesan',
//               color: theme.colorScheme.tertiary,
//               onTap: () {
//                 // Navigate to messages page
//               },
//             ),
//             _buildQuickActionItem(
//               theme,
//               icon: Icons.calendar_today_outlined,
//               label: 'Jadwal',
//               color: Colors.orange,
//               onTap: () {
//                 // Navigate to schedule page
//               },
//             ),
//           ],
//         ),
//       ],
//     );
//   }
  
//   Widget _buildQuickActionItem(
//     ThemeData theme, {
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(
//               icon,
//               size: 28,
//               color: color,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             style: theme.textTheme.bodyMedium,
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
  
//   String _getGreeting() {
//     final hour = DateTime.now().hour;
//     if (hour < 12) {
//       return 'Selamat Pagi,';
//     } else if (hour < 17) {
//       return 'Selamat Siang,';
//     } else {
//       return 'Selamat Malam,';
//     }
//   }
// }