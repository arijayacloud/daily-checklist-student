import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/laravel_api/providers/auth_provider.dart';
import '/laravel_api/providers/api_provider.dart';
import '/services/fcm_service.dart';
import '/screens/auth/login_screen.dart';
import '/screens/home/teacher_home_screen.dart';
import '/screens/home/parent_home_screen.dart';
import '/screens/auth/password_check_screen.dart';
import '/lib/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize FCM Service
      await Provider.of<FCMService>(context, listen: false).init();
    } catch (e) {
      print('Error initializing FCM service: $e');
    }
    
    // Check authentication status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final apiProvider = Provider.of<ApiProvider>(context, listen: false);
    
    // Wait at least 2 seconds to show splash screen
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      // If token exists, check user role and navigate to appropriate screen
      if (apiProvider.isAuthenticated) {
        debugPrint('SplashScreen: Token exists, proceeding to role check');
        if (!mounted) return;
        
        // Try to force refresh user data
        await authProvider.refreshUserData();
        
        // Try to get user data if available
        if (authProvider.user != null) {
          // Access role directly from the user model to ensure accuracy
          final userRole = authProvider.user!.role;
          debugPrint('SplashScreen: User role confirmed from model: $userRole');
          
          // Check if user has a temporary password first
          if (authProvider.user!.isTempPassword == true) {
            debugPrint('SplashScreen: User has temporary password, going to password check');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const PasswordCheckScreen()),
            );
            return;
          }
          
          // Navigate based on role
          debugPrint('SplashScreen: Navigating based on role: $userRole');
          if (userRole == 'teacher') {
            debugPrint('SplashScreen: Going to teacher home');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const TeacherHomeScreen()),
            );
          } else {
            debugPrint('SplashScreen: Going to parent home');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ParentHomeScreen()),
            );
          }
        } else {
          // User data not available yet, use PasswordCheckScreen as intermediate
          debugPrint('SplashScreen: No user data available, going to password check screen');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const PasswordCheckScreen()),
          );
        }
      } else {
        debugPrint('SplashScreen: No auth token found, going to login');
        if (!mounted) return;
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('SplashScreen: Error during auth check: $e');
      // On error, go to login
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 80,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
                  'Daftar Kegiatan TK',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
                  'Belajar Bersama',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppTheme.secondary),
            ),
            const SizedBox(height: 80),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
