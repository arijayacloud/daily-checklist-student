import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daily_checklist_student/laravel_api/providers/auth_provider.dart';
import 'package:daily_checklist_student/laravel_api/providers/user_provider.dart';
import 'package:daily_checklist_student/laravel_api/providers/api_provider.dart';
import 'package:daily_checklist_student/laravel_api/models/user_model.dart';
import 'package:daily_checklist_student/lib/theme/app_theme.dart';
import 'package:daily_checklist_student/screens/parents/add_parent_screen.dart';

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

  // Edit Parent
  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editEmailController = TextEditingController();
  final TextEditingController _editPasswordController = TextEditingController();
  final TextEditingController _editPhoneController = TextEditingController();
  final TextEditingController _editAddressController = TextEditingController();
  bool _showEditPassword = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to prevent calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchParents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newPasswordController.dispose();
    _editNameController.dispose();
    _editEmailController.dispose();
    _editPasswordController.dispose();
    _editPhoneController.dispose();
    _editAddressController.dispose();
    super.dispose();
  }

  Future<void> _fetchParents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Use server-side filtering for created_by instead of client-side filtering
      await userProvider.fetchParents(filterByCreatedBy: true);
      
      setState(() {
        // Use all parents from provider since they're already filtered by created_by
        _parents = userProvider.parents;
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
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    final apiProvider = Provider.of<ApiProvider>(context, listen: false);
                    
                    // Use direct change-password endpoint instead of reset-password
                    final result = await apiProvider.put(
                      'users/$_selectedParentId/change-password',
                      {
                        'new_password': _newPasswordController.text,
                        'is_temp_password': true
                      }
                    );

                    Navigator.pop(context);
                    if (result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password berhasil direset'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    } else {
                      throw Exception('Failed to reset password');
                    }
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
                  // Get the scaffold messenger and context before closing the dialog
                  // to avoid accessing a deactivated widget
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final navigatorContext = context;
                  
                  // Close the dialog first
                  Navigator.pop(context);
                  
                  try {
                    setState(() {
                      _isLoading = true;
                    });
                    
                    final userProvider = Provider.of<UserProvider>(navigatorContext, listen: false);
                    final apiProvider = Provider.of<ApiProvider>(navigatorContext, listen: false);
                    
                    // Use Laravel API to delete the user
                    final result = await apiProvider.delete('users/${parent.id}');

                    if (result != null) {
                      // Refresh the parent list after successful deletion
                      await _fetchParents();
                      
                      // Only show a message if the widget is still mounted
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Akun orang tua berhasil dihapus'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    } else {
                      throw Exception('Failed to delete user');
                    }
                  } catch (e) {
                    // Only show error if the widget is still mounted
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Gagal menghapus akun: $e'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
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

  Future<void> _editParent(UserModel parent) async {
    // Set the initial values in the controllers
    _editNameController.text = parent.name;
    _editEmailController.text = parent.email;
    _editPasswordController.clear();
    _editPhoneController.text = parent.phoneNumber ?? '';
    _editAddressController.text = parent.address ?? '';

    setState(() {
      _isEditing = true;
      _showEditPassword = false; // Reset password visibility
    });

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Data Orang Tua'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name field
                  TextFormField(
                    controller: _editNameController,
                    decoration: InputDecoration(
                      labelText: 'Nama',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Email field (disabled/read-only)
                  TextFormField(
                    controller: _editEmailController,
                    enabled: true, // Enable email editing
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone field
                  TextFormField(
                    controller: _editPhoneController,
                    decoration: InputDecoration(
                      labelText: 'Nomor Telepon',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  
                  // Address field
                  TextFormField(
                    controller: _editAddressController,
                    decoration: InputDecoration(
                      labelText: 'Alamat',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.home_outlined),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validate inputs
                  if (_editNameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nama tidak boleh kosong'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                    return;
                  }
                  
                  if (_editEmailController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email tidak boleh kosong'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                    return;
                  }
                  
                  if (_editPasswordController.text.isNotEmpty && _editPasswordController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password minimal 6 karakter'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Simpan'),
              ),
            ],
          );
        }
      ),
    );

    if (result == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        // Prepare update data (only name, phone, address)
        Map<String, dynamic> updateData = {
          'name': _editNameController.text.trim(),
          'email': _editEmailController.text.trim(),
          'phone_number': _editPhoneController.text.trim(),
          'address': _editAddressController.text.trim(),
        };
        
        // Call update API - only send name, phone_number, and address
        final success = await userProvider.updateUserProfile(
          id: parent.id,
          name: updateData['name'],
          email: updateData['email'],
          phoneNumber: updateData['phone_number'],
          address: updateData['address'],
        );

        // Handle password update separately if needed
        if (_editPasswordController.text.isNotEmpty) {
          final apiProvider = Provider.of<ApiProvider>(context, listen: false);
          await apiProvider.put(
            'users/${parent.id}/reset-password',
            {
              'password': _editPasswordController.text,
              'is_temp_password': true
            }
          );
        }

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Data orang tua berhasil diperbarui'),
                backgroundColor: AppTheme.success,
              ),
            );
          }
          _fetchParents(); // Refresh data
        } else {
          throw Exception('Failed to update parent');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memperbarui data: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
      }
    } else {
      setState(() {
        _isEditing = false;
      });
    }
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
                    fillColor: AppTheme.surfaceVariant.withAlpha(76),
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
                                          onTap: () => _editParent(parent),
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
      backgroundColor: AppTheme.surfaceVariant.withAlpha(76),
      selectedColor: AppTheme.primary.withAlpha(51),
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
