import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/config.dart';

// Laravel auth provider
import '/laravel_api/providers/auth_provider.dart';

import '/screens/home/parent_home_screen.dart';
import '/screens/home/teacher_home_screen.dart';
import '/lib/theme/app_theme.dart';
import '/widgets/auth/custom_text_field.dart';
import '/screens/auth/teacher_register_screen.dart';
import '/screens/auth/password_check_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _accessCodeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _loginWithLaravel();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loginWithLaravel() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PasswordCheckScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Login gagal. Periksa email dan password Anda.';
      });
    }
  }

  void _showTeacherRegistrationDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              'Kode Akses',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Masukkan kode akses untuk registrasi guru',
                  style: TextStyle(color: AppTheme.secondary),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _accessCodeController,
                  hintText: 'Kode Akses',
                  prefixIcon: Icons.key_outlined,
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _accessCodeController.clear();
                },
                child: Text(
                  'Batal',
                  style: TextStyle(color: AppTheme.secondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_accessCodeController.text.trim() == 'DAFTAR') {
                    Navigator.of(ctx).pop();
                    _accessCodeController.clear();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TeacherRegisterScreen(),
                      ),
                    );
                  } else {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Kode akses tidak valid'),
                        backgroundColor: AppTheme.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                    _accessCodeController.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Lanjut'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: AppTheme.surface,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and Title
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 64,
                      color: AppTheme.primary,
                    ),
                  ).animate().scale(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                  ),
                  const SizedBox(height: 24),
                  Text(
                        'Selamat Datang',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 300),
                      )
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 8),
                  Text(
                        'Silakan masuk untuk melanjutkan',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppTheme.secondary),
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 400),
                      )
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 48),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: AppTheme.error,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 300))
                        .slideY(begin: 0.2, end: 0),
                  if (_errorMessage != null) const SizedBox(height: 24),

                  // Email field
                  CustomTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fadeIn(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 500),
                      )
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 16),

                  // Password field
                  CustomTextField(
                        controller: _passwordController,
                        hintText: 'Kata Sandi',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kata sandi tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Kata sandi minimal 6 karakter';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fadeIn(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 600),
                      )
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 32),

                  // Login button
                  ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppTheme.primary.withOpacity(
                            0.6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      )
                      .animate()
                      .fadeIn(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 700),
                      )
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 24),

                  // Footer text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum memiliki akun? ',
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                      GestureDetector(
                        onTap: () => _showTeacherRegistrationDialog(),
                        child: Text(
                          'Daftar sebagai guru',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 800),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
