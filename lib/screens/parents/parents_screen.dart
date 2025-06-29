import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daily_checklist_student/laravel_api/providers/auth_provider.dart';
import 'package:daily_checklist_student/laravel_api/providers/user_provider.dart';
import 'package:daily_checklist_student/laravel_api/providers/api_provider.dart';
import 'package:daily_checklist_student/laravel_api/models/user_model.dart';
import 'package:daily_checklist_student/lib/theme/app_theme.dart';
import 'package:daily_checklist_student/screens/parents/add_parent_screen.dart';
import 'package:daily_checklist_student/screens/parents/add_teacher_screen.dart';

enum ParentSortOption { 
  nameAsc, 
  nameDesc, 
  emailAsc, 
  emailDesc, 
  newest, 
  oldest,
  statusActiveFirst,
  statusInactiveFirst
}

class ParentsScreen extends StatefulWidget {
  const ParentsScreen({super.key});

  @override
  State<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends State<ParentsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<UserModel> _parents = [];
  List<UserModel> _teachers = [];
  List<UserModel> _filteredParents = [];
  List<UserModel> _filteredTeachers = [];

  // Tab controller for superadmin view
  late TabController _tabController;
  bool _isSuperadmin = false;
  int _currentTabIndex = 0;

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
    
    // Initialize tab controller
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
          _searchQuery = '';
          _searchController.clear();
          _applyFilters();
        });
      }
    });
    
    // Use a post-frame callback to prevent calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _isSuperadmin = authProvider.user?.isSuperadmin ?? false;
      _fetchData();
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
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      if (_isSuperadmin) {
        // Superadmin: fetch all parents and teachers
        debugPrint('ParentsScreen: Fetching all parents and teachers as superadmin');
        
        // Fetch parents without filtering by created_by
        await userProvider.fetchParents(filterByCreatedBy: false);
        
        // Fetch teachers using our new endpoint
        await userProvider.fetchTeachers();
        
        setState(() {
          _parents = userProvider.parents;
          _teachers = userProvider.teachers;
          debugPrint('ParentsScreen: Fetched ${_parents.length} parents and ${_teachers.length} teachers');
        });
      } else {
        // Regular teacher: only fetch own parents
        debugPrint('ParentsScreen: Fetching only parents created by this teacher');
        await userProvider.fetchParents(filterByCreatedBy: true);
        setState(() {
          _parents = userProvider.parents;
          debugPrint('ParentsScreen: Fetched ${_parents.length} parents');
        });
      }
      
      _applyFilters();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('ParentsScreen: Error fetching data: $e');
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
    if (_currentTabIndex == 0) {
      // Filter parents
      List<UserModel> filtered = List.from(_parents);

      // Apply search
      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where((parent) {
          return parent.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              parent.email.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }

      // Apply sorting
      _applySorting(filtered);
      
      setState(() {
        _filteredParents = filtered;
      });
    } else {
      // Filter teachers
      List<UserModel> filtered = List.from(_teachers);

      // Apply search
      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where((teacher) {
          return teacher.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              teacher.email.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }

      // Apply sorting
      _applySorting(filtered);
      
      setState(() {
        _filteredTeachers = filtered;
      });
    }
  }
  
  void _applySorting(List<UserModel> users) {
    switch (_currentSortOption) {
      case ParentSortOption.nameAsc:
        users.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ParentSortOption.nameDesc:
        users.sort((a, b) => b.name.compareTo(a.name));
        break;
      case ParentSortOption.emailAsc:
        users.sort((a, b) => a.email.compareTo(b.email));
        break;
      case ParentSortOption.emailDesc:
        users.sort((a, b) => b.email.compareTo(a.email));
        break;
      case ParentSortOption.newest:
        // Implementasi jika ada timestamp
        break;
      case ParentSortOption.oldest:
        // Implementasi jika ada timestamp
        break;
      case ParentSortOption.statusActiveFirst:
        users.sort((a, b) {
          final aStatus = a.status ?? 'inactive';
          final bStatus = b.status ?? 'inactive';
          return aStatus.compareTo(bStatus);
        });
        break;
      case ParentSortOption.statusInactiveFirst:
        users.sort((a, b) {
          final aStatus = a.status ?? 'inactive';
          final bStatus = b.status ?? 'inactive';
          return bStatus.compareTo(aStatus);
        });
        break;
    }
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
                      await _fetchData();
                      
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
          _fetchData(); // Refresh data
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

  // Toggle user active/inactive status
  Future<void> _toggleUserStatus(UserModel parent) async {
    final bool isActive = (parent.status ?? 'inactive') == 'active';
    final String newStatus = isActive ? 'inactive' : 'active';
    final String actionText = isActive ? 'nonaktifkan' : 'aktifkan';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isActive ? 'Nonaktifkan' : 'Aktifkan'} Akun'),
        content: Text(
          'Anda yakin ingin $actionText akun ${parent.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigatorContext = context;
              
              // Close dialog first
              Navigator.pop(context);
              
              try {
                setState(() {
                  _isLoading = true;
                });
                
                final apiProvider = Provider.of<ApiProvider>(navigatorContext, listen: false);
                
                // Update user status via API
                final result = await apiProvider.put(
                  'users/${parent.id}',
                  {'status': newStatus}
                );

                if (result != null) {
                  // Refresh parent list
                  await _fetchData();
                  
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Akun berhasil ${isActive ? 'dinonaktifkan' : 'diaktifkan'}'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                } else {
                  throw Exception('Failed to update user status');
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Gagal mengubah status akun: $e'),
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
              backgroundColor: isActive ? Colors.orange : AppTheme.success,
              foregroundColor: Colors.white,
            ),
            child: Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
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
          if (_isSuperadmin) _buildTabs(),
          _buildSearchBar(),
          _buildFilterSection(),
          Expanded(child: _buildUserList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'parents_fab',
        onPressed: () {
          if (_isSuperadmin && _currentTabIndex == 1) {
            // Add teacher screen for superadmin
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddTeacherScreen(),
              ),
            ).then((_) => _fetchData());
          } else {
            // Add parent screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddParentScreen(),
              ),
            ).then((_) => _fetchData());
          }
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  
  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Orang Tua'),
        Tab(text: 'Guru'),
      ],
      labelColor: AppTheme.primary,
      unselectedLabelColor: Colors.grey,
      indicatorColor: AppTheme.primary,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: _isSuperadmin && _currentTabIndex == 1 
              ? 'Cari guru...' 
              : 'Cari orang tua...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
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
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Text(
            'Filter: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
                  _buildFilterChip(
                    label: _getCurrentSortLabel(),
                    isSelected: _currentSortOption != ParentSortOption.nameAsc,
                    onSelected: (_) => _showFilterDialog(),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
            const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Pencarian: $_searchQuery',
                      isSelected: true,
                      onSelected: (_) {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                        _applyFilters();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Detail',
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  String _getCurrentSortLabel() {
    switch (_currentSortOption) {
      case ParentSortOption.nameAsc:
        return 'Nama (A-Z)';
      case ParentSortOption.nameDesc:
        return 'Nama (Z-A)';
      case ParentSortOption.emailAsc:
        return 'Email (A-Z)';
      case ParentSortOption.emailDesc:
        return 'Email (Z-A)';
      case ParentSortOption.newest:
        return 'Terbaru';
      case ParentSortOption.oldest:
        return 'Terlama';
      case ParentSortOption.statusActiveFirst:
        return 'Aktif Dulu';
      case ParentSortOption.statusInactiveFirst:
        return 'Nonaktif Dulu';
      default:
        return 'Nama (A-Z)';
    }
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppTheme.primaryContainer,
      checkmarkColor: AppTheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.onPrimaryContainer : AppTheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _isSuperadmin && _currentTabIndex == 1
                            ? 'Filter Guru'
                            : 'Filter Orang Tua',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _currentSortOption = ParentSortOption.nameAsc;
                          });
                        },
                        child: const Text('Atur Ulang'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sorting options
                  const Text(
                    'Urutkan Berdasarkan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSortingChip('Nama (A-Z)', ParentSortOption.nameAsc, setState),
                      _buildSortingChip('Nama (Z-A)', ParentSortOption.nameDesc, setState),
                      _buildSortingChip('Email (A-Z)', ParentSortOption.emailAsc, setState),
                      _buildSortingChip('Email (Z-A)', ParentSortOption.emailDesc, setState),
                      _buildSortingChip('Aktif Dulu', ParentSortOption.statusActiveFirst, setState),
                      _buildSortingChip('Nonaktif Dulu', ParentSortOption.statusInactiveFirst, setState),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Apply button
                  ElevatedButton(
                    onPressed: () {
                      this.setState(() {
                        // Update the parent state
                        // Sort option already updated in the StatefulBuilder
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'Terapkan Filter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortingChip(String label, ParentSortOption option, StateSetter setState) {
    final isSelected = _currentSortOption == option;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _currentSortOption = option;
        });
        // Don't call _applyFilters here as we'll do it when Apply is pressed
      },
      selectedColor: AppTheme.primaryContainer,
      checkmarkColor: AppTheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.onPrimaryContainer : AppTheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildUserList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_isSuperadmin) {
      // Superadmin sees both tabs
      final currentList = _currentTabIndex == 0 ? _filteredParents : _filteredTeachers;
      
      if (currentList.isEmpty) {
        return _buildEmptyState();
      }
      
      return _buildUserListView(currentList);
    } else {
      // Regular teacher only sees parents
      if (_filteredParents.isEmpty) {
        return _buildEmptyState();
      }
      
      return _buildUserListView(_filteredParents);
    }
  }
  
  Widget _buildUserListView(List<UserModel> users) {
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
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
                  user.name.isNotEmpty
                      ? user.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (user.status ?? 'inactive') == 'active' 
                          ? Colors.green.withOpacity(0.2) 
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (user.status ?? 'inactive') == 'active' ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(
                        fontSize: 12,
                        color: (user.status ?? 'inactive') == 'active' ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(user.email),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      // Display user role for superadmin
                      if (_isSuperadmin)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getRoleColor(user.role).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getRoleDisplayName(user.role),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getRoleColor(user.role),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      // Display user phone and address if available
                      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.phone, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(user.phoneNumber!),
                            ],
                          ),
                        ),
                      if (user.address != null && user.address!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.home, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(child: Text(user.address!)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.password,
                            label: 'Reset Password',
                            color: Colors.orange,
                            onTap: () => _resetPassword(user.id),
                          ),
                          _buildActionButton(
                            icon: Icons.edit,
                            label: 'Edit',
                            color: AppTheme.primary,
                            onTap: () => _editParent(user),
                          ),
                          _buildActionButton(
                            icon: (user.status ?? 'inactive') == 'active' 
                                ? Icons.block 
                                : Icons.check_circle,
                            label: (user.status ?? 'inactive') == 'active' 
                                ? 'Nonaktifkan' 
                                : 'Aktifkan',
                            color: (user.status ?? 'inactive') == 'active' 
                                ? Colors.orange 
                                : Colors.green,
                            onTap: () => _toggleUserStatus(user),
                          ),
                          _buildActionButton(
                            icon: Icons.delete,
                            label: 'Hapus',
                            color: Colors.red,
                            onTap: () => _deleteParent(user),
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
    );
  }
  
  Color _getRoleColor(String role) {
    switch (role) {
      case 'superadmin':
        return Colors.purple;
      case 'teacher':
        return Colors.blue;
      case 'parent':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'superadmin':
        return 'Administrator';
      case 'teacher':
        return 'Guru';
      case 'parent':
        return 'Orang Tua';
      default:
        return 'Pengguna';
    }
  }

  Widget _buildEmptyState() {
    String message, buttonText;
    IconData icon = Icons.people_outline;
    
    if (_searchQuery.isNotEmpty) {
      message = 'Tidak ada pengguna yang sesuai pencarian';
      buttonText = 'Hapus Filter';
      icon = Icons.search_off;
    } else if (_isSuperadmin && _currentTabIndex == 1) {
      message = 'Belum ada guru yang terdaftar';
      buttonText = 'Tambah Guru';
    } else {
      message = 'Belum ada orang tua yang terdaftar';
      buttonText = 'Tambah Orang Tua';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppTheme.surfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (_searchQuery.isNotEmpty) {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
                _applyFilters();
              } else {
                if (_isSuperadmin && _currentTabIndex == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTeacherScreen(),
                    ),
                  ).then((_) => _fetchData());
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddParentScreen(),
                    ),
                  ).then((_) => _fetchData());
                }
              }
            },
            icon: Icon(_searchQuery.isNotEmpty ? Icons.clear : Icons.add),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
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
