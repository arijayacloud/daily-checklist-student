import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/providers/auth_provider.dart';
import '/screens/auth/login_screen.dart';
import '/screens/home/parent_home_screen.dart';
import '/screens/home/teacher_home_screen.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    Future.delayed(const Duration(seconds: 2), () {
      if (authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) =>
                    authProvider.userRole == 'teacher'
                        ? const TeacherHomeScreen()
                        : const ParentHomeScreen(),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
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
            ).animate().scale(
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
            ),
            const SizedBox(height: 32),
            Text(
                  'TK Activity Checklist',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
                .animate()
                .fadeIn(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 400),
                )
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),
            Text(
                  'Learning Together',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppTheme.secondary),
                )
                .animate()
                .fadeIn(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 600),
                )
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: 80),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 800),
              delay: const Duration(milliseconds: 800),
            ),
          ],
        ),
      ),
    );
  }
}
