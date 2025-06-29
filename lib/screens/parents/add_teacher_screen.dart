import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daily_checklist_student/laravel_api/providers/user_provider.dart';
import 'package:daily_checklist_student/lib/theme/app_theme.dart';

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSubmitting = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _addMoreDetails = false;
  bool _nameManuallyEdited = false; // Track if user has manually edited the name field

  @override
  void initState() {
    super.initState();
    
    // Listen to email changes to suggest name, but only if user hasn't edited name yet
    _emailController.addListener(() {
      if (!_nameManuallyEdited && _nameController.text.isEmpty && _emailController.text.contains('@')) {
        // Extract username part of email (before @) as a name suggestion
        final username = _emailController.text.split('@').first;
        // Capitalize first letter of each word
        final formattedName = username
            .split(RegExp(r'[._-]')) // Split by common email separators
            .map((word) => word.isNotEmpty 
                ? word[0].toUpperCase() + word.substring(1) 
                : '')
            .join(' ');
            
        _nameController.text = formattedName;
      }
    });
    
    // Listen to name changes to track manual edits
    _nameController.addListener(() {
      if (_nameController.text.isNotEmpty) {
        _nameManuallyEdited = true;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Fungsi validasi email sederhana
  bool _isValidEmail(String email) {
    // Format regex untuk validasi email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _createTeacher() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Create teacher account using UserProvider with proper role
      debugPrint('AddTeacherScreen: Creating teacher account...');
      final newTeacher = await userProvider.createUser(
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        password: _passwordController.text,
        role: 'teacher',
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        isTempPassword: true, // Teachers should change password on first login
      );

      if (!mounted) return;

      if (newTeacher == null) {
        final errorMessage = userProvider.error ?? 'Failed to create teacher account';
        debugPrint('AddTeacherScreen: Error creating teacher: $errorMessage');
        throw Exception(errorMessage);
      }

      debugPrint('AddTeacherScreen: Teacher account created successfully: ${newTeacher.id}');

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.success),
                  const SizedBox(width: 8),
                  const Text('Berhasil'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Akun guru berhasil dibuat:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Email: ${_emailController.text.trim()}'),
                  Text('Nama: ${_nameController.text.trim()}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Catatan: Guru akan diminta untuk mengubah password saat pertama kali login.',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Selesai'),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
      );
    } catch (e) {
      debugPrint('AddTeacherScreen: Exception during teacher creation: $e');
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Guru')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informasi Akun Guru',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Teacher email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Guru',
                  hintText: 'Masukkan email guru',
                  filled: true,
                  fillColor: AppTheme.surfaceVariant.withAlpha(76),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Silahkan masukkan email';
                  }
                  if (!_isValidEmail(value.trim())) {
                    return 'Silahkan masukkan email yang valid';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),

              // Teacher name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Guru',
                  hintText: 'Masukkan nama guru',
                  filled: true,
                  fillColor: AppTheme.surfaceVariant.withAlpha(76),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Silahkan masukkan nama';
                  }
                  if (value.trim().length < 3) {
                    return 'Nama harus minimal 3 karakter';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),

              // Teacher password
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password Sementara',
                  hintText: 'Buat password sementara',
                  filled: true,
                  fillColor: AppTheme.surfaceVariant.withAlpha(76),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
                obscureText: !_showPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Silahkan masukkan password';
                  }
                  if (value.length < 6) {
                    return 'Password harus minimal 6 karakter';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),

              // Confirm password
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  hintText: 'Masukkan password kembali',
                  filled: true,
                  fillColor: AppTheme.surfaceVariant.withAlpha(76),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: !_showConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Silahkan konfirmasi password';
                  }
                  if (value != _passwordController.text) {
                    return 'Password tidak cocok';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 8),

              Text(
                'Catatan: Guru akan diminta untuk mengganti password ini saat login pertama kali.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),

              // Tampilkan more details
              SwitchListTile(
                title: const Text('Tambahkan detail lainnya'),
                subtitle: const Text('Nomor telepon, alamat, dll'),
                value: _addMoreDetails,
                onChanged: (value) {
                  setState(() {
                    _addMoreDetails = value;
                  });
                },
                activeColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
              ),

              if (_addMoreDetails) ...[
                const SizedBox(height: 16),

                // Phone number
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Nomor Telepon',
                    hintText: 'Masukkan nomor telepon',
                    filled: true,
                    fillColor: AppTheme.surfaceVariant.withAlpha(76),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Alamat',
                    hintText: 'Masukkan alamat lengkap',
                    filled: true,
                    fillColor: AppTheme.surfaceVariant.withAlpha(76),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.home_outlined),
                  ),
                  maxLines: 3,
                ),
              ],

              const SizedBox(height: 32),

              // Create button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _createTeacher,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.primary.withAlpha(153),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Buat Akun Guru',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
