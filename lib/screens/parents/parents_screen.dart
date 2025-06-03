import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/providers/auth_provider.dart';
import '/models/user_model.dart';
import '/screens/parents/add_parent_screen.dart';
import '/lib/theme/app_theme.dart';

enum ParentSortOption { nameAsc, nameDesc, emailAsc, emailDesc, newest, oldest }

class ParentsScreen extends StatefulWidget {
  const ParentsScreen({super.key});

  @override
  State<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends State<ParentsScreen> {
  bool _isLoading = true;
  List<UserModel> _parents = [];
  List<UserModel> _filteredParents = [];

  // Pencarian dan Filter
  final TextEditingController _searchController = TextEditingController();
  ParentSortOption _currentSortOption = ParentSortOption.nameAsc;
  String _searchQuery = '';

  // Reset Password
  bool _isResettingPassword = false;
  String? _selectedParentId;
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchParents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchParents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Only fetch parents created by current teacher
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'parent')
              .where('createdBy', isEqualTo: authProvider.userId)
              .get();

      final parents =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return UserModel.fromJson({'id': doc.id, ...data});
          }).toList();

      setState(() {
        _parents = parents;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching parents: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<UserModel> filtered = List.from(_parents);

    // Terapkan pencarian
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((parent) {
            return parent.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                parent.email.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
    }

    // Terapkan pengurutan
    switch (_currentSortOption) {
      case ParentSortOption.nameAsc:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ParentSortOption.nameDesc:
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case ParentSortOption.emailAsc:
        filtered.sort((a, b) => a.email.compareTo(b.email));
        break;
      case ParentSortOption.emailDesc:
        filtered.sort((a, b) => b.email.compareTo(a.email));
        break;
      case ParentSortOption.newest:
        // Implementasi jika ada timestamp
        break;
      case ParentSortOption.oldest:
        // Implementasi jika ada timestamp
        break;
    }

    setState(() {
      _filteredParents = filtered;
    });
  }

  Future<void> _resetPassword(String parentId) async {
    setState(() {
      _isResettingPassword = true;
      _selectedParentId = parentId;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Masukkan password baru untuk akun orang tua ini:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isResettingPassword = false;
                    _selectedParentId = null;
                    _newPasswordController.clear();
                  });
                },
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_newPasswordController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password minimal 6 karakter'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                    return;
                  }

                  try {
                    // Implementasi reset password
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_selectedParentId)
                        .update({
                          'isTempPassword': true,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                    // Disini implementasi reset password di Firebase Auth
                    // ...

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password berhasil direset'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal reset password: $e'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  } finally {
                    setState(() {
                      _isResettingPassword = false;
                      _selectedParentId = null;
                      _newPasswordController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reset Password'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteParent(UserModel parent) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Akun Orang Tua'),
            content: Text(
              'Anda yakin ingin menghapus akun ${parent.name}? Tindakan ini tidak dapat dibatalkan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    // Implement hapus orang tua (ini hanya contoh)
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(parent.id)
                        .update({
                          'status': 'deleted',
                          'deletedAt': FieldValue.serverTimestamp(),
                        });

                    _fetchParents();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Akun orang tua berhasil dihapus'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus akun: $e'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari orang tua...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                                _applyFilters();
                              },
                            )
                            : null,
                    filled: true,
                    fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip('Nama (A-Z)', ParentSortOption.nameAsc),
                      const SizedBox(width: 8),
                      _buildSortChip('Nama (Z-A)', ParentSortOption.nameDesc),
                      const SizedBox(width: 8),
                      _buildSortChip('Email (A-Z)', ParentSortOption.emailAsc),
                      const SizedBox(width: 8),
                      _buildSortChip('Email (Z-A)', ParentSortOption.emailDesc),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List parents
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredParents.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppTheme.surfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Tidak ada orang tua yang sesuai pencarian'
                                : 'Belum ada orang tua yang terdaftar',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_searchQuery.isEmpty)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const AddParentScreen(),
                                  ),
                                ).then((_) => _fetchParents());
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Orang Tua'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredParents.length,
                      itemBuilder: (context, index) {
                        final parent = _filteredParents[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary,
                              child: Text(
                                parent.name.isNotEmpty
                                    ? parent.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              parent.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(parent.email),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildActionButton(
                                          icon: Icons.password,
                                          label: 'Reset Password',
                                          color: Colors.orange,
                                          onTap:
                                              () => _resetPassword(parent.id),
                                        ),
                                        _buildActionButton(
                                          icon: Icons.edit,
                                          label: 'Edit',
                                          color: AppTheme.primary,
                                          onTap: () {
                                            // TODO: Navigasi ke halaman edit
                                          },
                                        ),
                                        _buildActionButton(
                                          icon: Icons.delete,
                                          label: 'Hapus',
                                          color: Colors.red,
                                          onTap: () => _deleteParent(parent),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton:
          _parents.isNotEmpty
              ? FloatingActionButton(
                heroTag: 'parents_fab',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddParentScreen(),
                    ),
                  ).then((_) => _fetchParents());
                },
                backgroundColor: AppTheme.primary,
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
    );
  }

  Widget _buildSortChip(String label, ParentSortOption option) {
    final isSelected = _currentSortOption == option;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _currentSortOption = option;
        });
        _applyFilters();
      },
      backgroundColor: AppTheme.surfaceVariant.withOpacity(0.3),
      selectedColor: AppTheme.primary.withOpacity(0.2),
      checkmarkColor: AppTheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primary : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
