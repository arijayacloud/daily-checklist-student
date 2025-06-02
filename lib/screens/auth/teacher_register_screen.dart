import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/providers/auth_provider.dart';
import '/screens/home/teacher_home_screen.dart';
import '/lib/theme/app_theme.dart';
import '/widgets/auth/custom_text_field.dart';

class TeacherRegisterScreen extends StatefulWidget {
  static const routeName = '/teacher-register';

  const TeacherRegisterScreen({super.key});

  @override
  State<TeacherRegisterScreen> createState() => _TeacherRegisterScreenState();
}

class _TeacherRegisterScreenState extends State<TeacherRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.createTeacherAccount(
        _emailController.text.trim(),
        _nameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const TeacherHomeScreen()),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                      Icons.school_rounded,
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
                        'Pendaftaran Guru',
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
                        'Silakan lengkapi data untuk mendaftar sebagai guru',
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

                  // Name field
                  CustomTextField(
                        controller: _nameController,
                        hintText: 'Nama Lengkap',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fadeIn(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 400),
                      )
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 16),

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
                  const SizedBox(height: 16),

                  // Confirm Password field
                  CustomTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Konfirmasi Kata Sandi',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi kata sandi tidak boleh kosong';
                          }
                          if (value != _passwordController.text) {
                            return 'Kata sandi tidak sama';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fadeIn(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 700),
                      )
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 32),

                  // Register button
                  ElevatedButton(
                        onPressed: _isLoading ? null : _register,
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
                                  'Daftar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      )
                      .animate()
                      .fadeIn(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 800),
                      )
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 24),

                  // Footer text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah memiliki akun? ',
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          'Masuk',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 900),
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
