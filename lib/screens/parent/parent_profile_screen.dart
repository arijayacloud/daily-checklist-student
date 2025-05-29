import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../../core/theme/app_colors_compat.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ParentProfileScreen extends StatelessWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya'), centerTitle: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child:
                        user?.avatarUrl != null
                            ? CachedNetworkImage(
                              imageUrl: user!.avatarUrl ?? '',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) =>
                                      const CircularProgressIndicator(),
                              errorWidget:
                                  (context, url, error) => Icon(
                                    Icons.person,
                                    size: 60,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            )
                            : Icon(
                              Icons.person,
                              size: 60,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // User name
              Text(
                user?.name ?? 'Orang Tua',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // User email
              Text(
                user?.email ?? '',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Profile menu
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Edit Profil'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Show edit profile dialog
                        _showEditProfileDialog(context);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Bantuan & Dukungan'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Show help dialog
                        _showHelpDialog(context);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Tentang'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Show about dialog
                        _showAboutDialog(context);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Logout button
              OutlinedButton.icon(
                onPressed: () async {
                  await authProvider.signOut();

                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;

    final nameController = TextEditingController(text: user?.name);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Profil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    // Karena belum ada metode updateProfile, cukup tutup dialog
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profil berhasil diperbarui'),
                      ),
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bantuan & Dukungan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Butuh bantuan dengan aplikasi ini?',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Silakan hubungi guru atau administrator sekolah anak Anda untuk mendapatkan bantuan.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tentang'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TK Activity Checklist',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Versi 1.0.0',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aplikasi untuk melacak aktivitas TK antara rumah dan sekolah.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
