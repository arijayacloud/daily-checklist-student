import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import '/providers/auth_provider.dart';
import '/providers/activity_provider.dart';
import '/providers/checklist_provider.dart';
import '/providers/child_provider.dart';
import '/providers/planning_provider.dart';
import '/providers/notification_provider.dart';
import '/providers/user_provider.dart';
import '/screens/auth/login_screen.dart';
import '/screens/auth/teacher_register_screen.dart';
import '/screens/parents/add_parent_screen.dart';
import '/screens/splash_screen.dart';
import '/screens/progress/progress_dashboard.dart';
import '/screens/progress/child_checklist_screen.dart';
import '/lib/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ChildProvider>(
          create: (_) => ChildProvider(),
          update: (_, auth, previous) => previous!..update(auth.user),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ActivityProvider>(
          create: (_) => ActivityProvider(),
          update: (_, auth, previous) => previous!..update(auth.user),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ChecklistProvider>(
          create: (_) => ChecklistProvider(),
          update: (_, auth, previous) => previous!..update(auth.user),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PlanningProvider>(
          create: (_) => PlanningProvider(),
          update: (_, auth, previous) => previous!..update(auth.user),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, auth, previous) => previous!..update(auth.user),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'TK Activity Checklist',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/add-parent': (context) => const AddParentScreen(),
          TeacherRegisterScreen.routeName:
              (context) => const TeacherRegisterScreen(),
          ProgressDashboard.routeName: (context) => const ProgressDashboard(),
          ChildChecklistScreen.routeName:
              (context) => const ChildChecklistScreen(),
        },
      ),
    );
  }
}
