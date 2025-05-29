import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors_compat.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({Key? key}) : super(key: key);

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String selectedRole = 'parent'; // Default role
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama dan email harus diisi'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      // Gunakan metode baru di UserProvider yang tidak mengubah status auth
      if (selectedRole == 'parent') {
        result = await userProvider.createParentAccount(
          name: nameController.text,
          email: emailController.text,
          teacherId: authProvider.userModel!.id,
        );
      } else {
        result = await userProvider.createTeacherAccount(
          name: nameController.text,
          email: emailController.text,
          creatorId: authProvider.userModel!.id,
        );
      }

      setState(() {
        isLoading = false;
      });

      if (result['success'] && mounted) {
        // Tampilkan dialog sukses dengan password
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Akun Berhasil Dibuat'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Akun pengguna berhasil dibuat dengan detail:'),
                    const SizedBox(height: 12),
                    _detailRow(
                      'Peran',
                      selectedRole == 'parent' ? 'Orang Tua' : 'Guru',
                    ),
                    _detailRow('Nama', nameController.text),
                    _detailRow('Email', emailController.text),
                    _detailRow(
                      'Password',
                      result['password'] ?? '',
                      canCopy: true,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Catatan: Simpan password ini karena akan diperlukan untuk login pertama kali.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Akun akan diaktifkan dalam beberapa saat. Gunakan password ini untuk login setelah diaktifkan.',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      // Reset form dan tetap di halaman ini
                      nameController.clear();
                      emailController.clear();
                      setState(() {
                        selectedRole = 'parent'; // Reset ke default
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text('Buat Lagi'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Kembali ke halaman sebelumnya
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Selesai'),
                  ),
                ],
              ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal membuat akun pengguna'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _detailRow(String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
          if (canCopy)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                _copyToClipboard(value);
              },
              tooltip: 'Salin ke clipboard',
            ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teks disalin ke clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Akun Pengguna')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Akun',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Peran Pengguna',
                        prefixIcon: Icon(Icons.assignment_ind_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'parent',
                          child: Text('Orang Tua'),
                        ),
                        DropdownMenuItem(value: 'teacher', child: Text('Guru')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedRole = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Pengguna',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.info),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Password akan dibuat secara otomatis dan akan ditampilkan setelah akun berhasil dibuat. Akun akan diaktifkan dalam beberapa saat setelah dibuat.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _createAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('Buat Akun'),
            ),
          ],
        ),
      ),
    );
  }
}
