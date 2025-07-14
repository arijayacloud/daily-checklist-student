import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/config.dart';

// Auth provider
import '/laravel_api/providers/auth_provider.dart';
import '/laravel_api/providers/api_provider.dart';

import '/screens/home/parent_home_screen.dart';
import '/screens/home/teacher_home_screen.dart';
import '/screens/profile/change_password_screen.dart';
import '/lib/theme/app_theme.dart';

class PasswordCheckScreen extends StatefulWidget {
  const PasswordCheckScreen({super.key});

  @override
  State<PasswordCheckScreen> createState() => _PasswordCheckScreenState();
}

class _PasswordCheckScreenState extends State<PasswordCheckScreen> {
  bool _isLoading = true;
  bool _isTemp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPasswordStatus();
    });
  }

  Future<void> _checkPasswordStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiProvider = Provider.of<ApiProvider>(context, listen: false);
      
      if (!apiProvider.isAuthenticated) {
        debugPrint('PasswordCheckScreen: Not authenticated, redirecting to login');
        // No token, redirect to login
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
      
      // Try to force refresh user data if needed
      if (authProvider.user == null) {
        debugPrint('PasswordCheckScreen: No user data, trying to refresh');
        await authProvider.refreshUserData();
      }
      
      final hasUserData = authProvider.user != null;
      debugPrint('PasswordCheckScreen: Has user data: $hasUserData');
      
      if (hasUserData) {
        // Explicitly get user role and log it
        final userRole = authProvider.user!.role;
        debugPrint('PasswordCheckScreen: User role from model: $userRole');
        
        // Check if user has a temporary password
        final isTempPassword = authProvider.user?.isTempPassword ?? false;
        debugPrint('PasswordCheckScreen: Is temp password: $isTempPassword');
        
        if (mounted) {
          setState(() => _isTemp = isTempPassword);
        }
        
        if (!isTempPassword && mounted) {
          debugPrint('PasswordCheckScreen: Navigating to $userRole home screen');
          _goToHomeScreen(userRole);
        }
      } else {
        // No user data available, use default role
        final fallbackRole = 'parent';
        debugPrint('PasswordCheckScreen: No user data, using fallback role: $fallbackRole');
        _goToHomeScreen(fallbackRole);
      }
    } catch (e) {
      debugPrint('PasswordCheckScreen: Error checking status: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToHomeScreen(String role) {
    debugPrint('PasswordCheckScreen: Going to home for role: $role');
    if (role == 'teacher' || role == 'superadmin') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const TeacherHomeScreen(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const ParentHomeScreen(),
        ),
      );
    }
  }

  void _navigateToChangePassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isTemp) {
      return const SizedBox.shrink(); // Will be redirected
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.key_rounded,
                  size: 80,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  'Password Sementara',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Anda menggunakan password sementara. Untuk keamanan, silahkan ganti password Anda sekarang.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _navigateToChangePassword,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: AppTheme.primary,
                  ),
                  child: const Text(
                    'Ganti Password',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: TextButton(
                    onPressed: () {
                      final role = Provider.of<AuthProvider>(context, listen: false).userRole;
                      _goToHomeScreen(role);
                    },
                    child: const Text(
                      'Lewati untuk saat ini',
                      style: TextStyle(color: AppTheme.secondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
