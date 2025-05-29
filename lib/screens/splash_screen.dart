import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import './auth/login_screen.dart';
import './parent/parent_dashboard.dart';
import './teacher/teacher_dashboard.dart';
import '../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserState();
  }

  Future<void> _checkUserState() async {
    // Lebih singkat, karena auth sudah diinisialisasi di main.dart
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Langsung periksa status login
    if (authProvider.isLoggedIn) {
      if (authProvider.isTeacher) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TeacherDashboard()),
        );
      } else if (authProvider.isParent) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ParentDashboard()),
        );
      } else {
        // Peran pengguna belum ditentukan, coba sekali lagi dengan delay lebih pendek
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        _redirectBasedOnRole(authProvider);
      }
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _redirectBasedOnRole(AuthProvider authProvider) {
    if (authProvider.isTeacher) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TeacherDashboard()),
      );
    } else if (authProvider.isParent) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ParentDashboard()),
      );
    } else {
      // Jika masih tidak dapat menentukan peran, arahkan ke halaman login
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // App logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 64,
              ),
            ).animate().scale(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              begin: const Offset(0.6, 0.6),
              end: const Offset(1.0, 1.0),
            ),

            const SizedBox(height: 24),

            // App name
            Text(
                  'TK Activity Checklist',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 400),
                )
                .moveY(
                  begin: 20,
                  end: 0,
                  curve: Curves.easeOutQuad,
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 400),
                ),

            const SizedBox(height: 8),

            // App tagline
            Text(
              'Pantau aktivitas TK di rumah dan sekolah',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 800),
              delay: const Duration(milliseconds: 600),
            ),

            const Spacer(),

            // Loading indicator
            const CircularProgressIndicator().animate().fadeIn(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 800),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
