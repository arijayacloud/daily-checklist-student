import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors_compat.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/empty_state.dart';
import 'create_user_screen.dart'; // Import halaman baru

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      await userProvider.loadAllUsers(authProvider.userModel!.id);
    }
  }

  // Mengganti dialog pembuatan dengan navigasi ke halaman terpisah
  void _navigateToCreateUser() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateUserScreen()),
    ).then((_) {
      // Refresh data setelah kembali dari halaman pembuatan akun
      _loadData();
    });
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

  void _showUserOptions(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Reset Password'),
                onTap: () {
                  Navigator.pop(context);
                  _showResetPasswordConfirmation(context, user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Detail Pengguna'),
                onTap: () {
                  Navigator.pop(context);
                  _showUserDetails(context, user);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text(
                  'Hapus Pengguna',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, user);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showResetPasswordConfirmation(BuildContext context, UserModel user) {
    // Implementasi reset password akan ditambahkan nanti
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Password'),
            content: Text(
              'Fitur reset password untuk ${user.name} akan segera tersedia.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  void _showUserDetails(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Detail Pengguna'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Nama', user.name),
                _detailRow('Email', user.email),
                _detailRow(
                  'Peran',
                  user.role == 'parent' ? 'Orangtua' : 'Guru',
                ),
                if (user.role == 'parent' && user.tempPassword != null)
                  _detailRow(
                    'Password',
                    user.tempPassword ?? '',
                    canCopy: true,
                  ),
                _detailRow('ID', user.id),
                _detailRow('Dibuat pada', _formatDate(user.createdAt)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Pengguna'),
            content: Text(
              'Anda yakin ingin menghapus akun ${user.name}? Tindakan ini tidak dapat dibatalkan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final userProvider = Provider.of<UserProvider>(
                    context,
                    listen: false,
                  );

                  setState(() {
                    _isLoading = true;
                  });

                  final success = await userProvider.deleteUser(user.id);

                  setState(() {
                    _isLoading = false;
                  });

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pengguna berhasil dihapus'),
                        backgroundColor: AppColors.complete,
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          userProvider.errorMessage ??
                              'Gagal menghapus pengguna',
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    if (!authProvider.isTeacher) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manajemen Pengguna')),
        body: const Center(
          child: Text('Anda tidak memiliki akses ke halaman ini'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pengguna'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari pengguna',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed:
                      _navigateToCreateUser, // Gunakan fungsi navigasi baru
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: Builder(
                builder: (context) {
                  if (_isLoading || userProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (userProvider.errorMessage.isNotEmpty) {
                    return Center(
                      child: Text(
                        'Error: ${userProvider.errorMessage}',
                        style: TextStyle(color: AppColors.error),
                      ),
                    );
                  }

                  // Gabungkan daftar orangtua dan guru
                  final allUsers = [
                    ...userProvider.parents,
                    ...userProvider.teachers,
                  ];

                  if (allUsers.isEmpty) {
                    return const EmptyState(
                      icon: Icons.people,
                      title: 'Tidak Ada Pengguna',
                      message:
                          'Ketuk tombol + di atas untuk menambahkan pengguna.',
                    );
                  }

                  // Filter data berdasarkan search query
                  final filteredUsers =
                      allUsers.where((user) {
                        if (_searchQuery.isEmpty) return true;
                        return user.name.toLowerCase().contains(_searchQuery) ||
                            user.email.toLowerCase().contains(_searchQuery);
                      }).toList();

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Text(
                        'Tidak ada pengguna dengan nama atau email yang mengandung "$_searchQuery"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: const Icon(
                              Icons.person,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(user.email),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          user.role == 'parent'
                                              ? AppColors.primary.withOpacity(
                                                0.1,
                                              )
                                              : AppColors.complete.withOpacity(
                                                0.1,
                                              ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      user.role == 'parent'
                                          ? 'Orangtua'
                                          : 'Guru',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            user.role == 'parent'
                                                ? AppColors.primary
                                                : AppColors.complete,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Dibuat: ${_formatDate(user.createdAt)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () {
                              _showUserOptions(context, user);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
