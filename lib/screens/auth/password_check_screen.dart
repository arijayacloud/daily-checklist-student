import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPasswordStatus();
    });
  }

  Future<void> _checkPasswordStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Periksa apakah pengguna memiliki password sementara
    if (authProvider.user?.isTempPassword == true) {
      if (!mounted) return;

      // Tampilkan dialog untuk meminta pengguna mengubah password
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber),
                  const SizedBox(width: 8),
                  const Text('Password Sementara'),
                ],
              ),
              content: const Text(
                'Anda menggunakan password sementara. Untuk keamanan, Anda harus mengubah password sebelum melanjutkan.',
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    // Navigasi ke halaman ganti password
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const ChangePasswordScreen(isForced: true),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Ubah Password'),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
      );
    } else {
      // Jika tidak menggunakan password sementara, arahkan ke halaman utama
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (context) =>
                  authProvider.userRole == 'teacher'
                      ? const TeacherHomeScreen()
                      : const ParentHomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
