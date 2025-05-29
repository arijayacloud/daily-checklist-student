import 'package:daily_checklist_student/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/locale/id_timeago.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/child_provider.dart';
import 'providers/assignment_provider.dart';
import 'providers/checklist_provider.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/teacher/teacher_dashboard.dart';
import 'screens/parent/parent_dashboard.dart';
import 'firebase_test_page.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inisialisasi locale timeago
  initializeTimeagoLocales();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => ChildProvider()),
        ChangeNotifierProvider(create: (_) => AssignmentProvider()),
        ChangeNotifierProvider(create: (_) => ChecklistProvider()),
      ],
      child: MaterialApp(
        title: 'TK Activity Tracker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // Default ke light theme
        initialRoute: '/splash',
        routes: {
          '/': (context) => const AuthCheck(),
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/teacher': (context) => const TeacherDashboard(),
          '/parent': (context) => const ParentDashboard(),
        },
      ),
    );
  }
}

// Kelas untuk mengecek status autentikasi
class AuthCheck extends StatefulWidget {
  const AuthCheck({Key? key}) : super(key: key);

  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Gunakan addPostFrameCallback untuk navigasi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initializeAuth();

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (authProvider.isLoggedIn) {
        if (authProvider.isTeacher) {
          Navigator.pushReplacementNamed(context, '/teacher');
        } else if (authProvider.isParent) {
          Navigator.pushReplacementNamed(context, '/parent');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:
            _isLoading
                ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Memuat aplikasi...'),
                  ],
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Mengarahkan ke halaman login...'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/splash');
                      },
                      child: const Text('Buka Halaman Test Firebase'),
                    ),
                  ],
                ),
      ),
    );
  }
}
