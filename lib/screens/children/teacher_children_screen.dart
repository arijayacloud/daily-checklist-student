import 'package:daily_checklist_student/screens/checklist/parent_checklist_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/config.dart';

// Import Laravel models and providers
import '/laravel_api/models/child_model.dart';
import '/laravel_api/providers/auth_provider.dart';
import '/laravel_api/providers/child_provider.dart';
import '/laravel_api/providers/user_provider.dart';

// Screens and widgets
import '/screens/checklist/teacher_checklist_screen.dart';
import '/screens/children/add_child_screen.dart';
import '/lib/theme/app_theme.dart';
import '/widgets/home/laravel_child_avatar.dart';

// Helper class for adapting child models
class _ChildAdapter {
  final String id;
  final String name;
  final int age;
  final String parentId;
  final String? avatarUrl;

  _ChildAdapter({
    required this.id,
    required this.name,
    required this.age,
    required this.parentId,
    this.avatarUrl,
  });
}

class TeacherChildrenScreen extends StatefulWidget {
  const TeacherChildrenScreen({super.key});

  @override
  State<TeacherChildrenScreen> createState() => _TeacherChildrenScreenState();
}

class _TeacherChildrenScreenState extends State<TeacherChildrenScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isDeleting = false;
  String _selectedAgeFilter = 'Semua';
  String _sortBy = 'name_asc';

  final List<String> _ageFilters = [
    'Semua',
    '3 tahun',
    '4 tahun',
    '5 tahun',
    '6 tahun',
    '7 tahun',
    '8 tahun',
  ];
  final Map<String, String> _sortOptions = {
    'name_asc': 'Nama (A-Z)',
    'name_desc': 'Nama (Z-A)',
    'age_asc': 'Usia (Muda-Tua)',
    'age_desc': 'Usia (Tua-Muda)',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch all necessary data
      Provider.of<ChildProvider>(context, listen: false).fetchChildren();
      Provider.of<UserProvider>(context, listen: false).fetchParents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChildModel> _getFilteredAndSortedChildren(List<ChildModel> children) {
    // Langkah 1: Filter berdasarkan pencarian
    List<ChildModel> filteredChildren = List.from(children);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredChildren = children.where((child) {
        final age = child.dateOfBirth != null ? child.getCalculatedAge() : child.age;
        return child.name.toLowerCase().contains(query) ||
            age.toString().contains(query);
      }).toList();
    }

    // Langkah 2: Filter berdasarkan usia
    if (_selectedAgeFilter != 'Semua') {
      final ageFilter = int.parse(_selectedAgeFilter.split(' ')[0]);
      filteredChildren = filteredChildren.where((child) {
        final age = child.dateOfBirth != null ? child.getCalculatedAge() : child.age;
        return age == ageFilter;
      }).toList();
    }

    // Langkah 3: Urutkan berdasarkan kriteria
    switch (_sortBy) {
      case 'name_asc':
        filteredChildren.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        filteredChildren.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'age_asc':
        filteredChildren.sort((a, b) {
          final ageA = a.dateOfBirth != null ? a.getCalculatedAge() : a.age;
          final ageB = b.dateOfBirth != null ? b.getCalculatedAge() : b.age;
          return ageA.compareTo(ageB);
        });
        break;
      case 'age_desc':
        filteredChildren.sort((a, b) {
          final ageA = a.dateOfBirth != null ? a.getCalculatedAge() : a.age;
          final ageB = b.dateOfBirth != null ? b.getCalculatedAge() : b.age;
          return ageB.compareTo(ageA);
        });
        break;
    }

    return filteredChildren;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterSection(),
          Expanded(child: _buildChildrenGrid()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'children_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddChildScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari murid...',
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
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Filter usia: ', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedAgeFilter,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: _ageFilters.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedAgeFilter = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Urutkan: ', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _sortBy,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: _sortOptions.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _sortBy = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenGrid() {
    return Consumer<ChildProvider>(
      builder: (context, childProvider, child) {
        if (childProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (childProvider.children.isEmpty) {
          return _buildEmptyState();
        }

        final filteredChildren = _getFilteredAndSortedChildren(childProvider.children);

        if (filteredChildren.isEmpty) {
          return _buildNoResultsState();
        }

        return RefreshIndicator(
          onRefresh: () => childProvider.fetchChildren(),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredChildren.length,
            itemBuilder: (context, index) {
              return _buildChildCard(context, filteredChildren[index], index);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.child_care,
            size: 80,
            color: AppTheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Data Anak',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan data anak dengan tombol + di bawah',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddChildScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Anak'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppTheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada anak yang cocok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah filter atau kata pencarian Anda',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _selectedAgeFilter = 'Semua';
                _sortBy = 'name_asc';
              });
            },
            child: const Text('Reset Filter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, ChildModel child, int index) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () {
          _showChildOptions(context, child);
        },
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LaravelChildAvatar(
                child: child,
                size: 90,
              ).animate().scale(
                curve: Curves.easeOutBack,
                duration: Duration(milliseconds: 400 + (index * 100)),
              ),
              const SizedBox(height: 6),
              Text(
                child.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ).animate().fadeIn(
                curve: Curves.easeOut,
                duration: Duration(milliseconds: 400 + (index * 100)),
                delay: const Duration(milliseconds: 200),
              ),
              const SizedBox(height: 4),
              Text(
                child.dateOfBirth != null 
                    ? child.getAgeString() 
                    : '${child.age} tahun',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ).animate().fadeIn(
                curve: Curves.easeOut,
                duration: Duration(milliseconds: 400 + (index * 100)),
                delay: const Duration(milliseconds: 300),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    icon: Icons.visibility,
                    label: 'Rapor',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ParentChecklistScreen(child: child),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.edit,
                    label: 'Edit',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddChildScreen(childToEdit: child),
                        ),
                      );
                    },
                  ),
                ],
              ).animate().fadeIn(
                curve: Curves.easeOut,
                duration: Duration(milliseconds: 400 + (index * 100)),
                delay: const Duration(milliseconds: 400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppTheme.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppTheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChildOptions(BuildContext context, ChildModel child) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: LaravelChildAvatar(
                    child: child,
                    size: 40,
                  ),
                ),
                title: Text(child.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  child.dateOfBirth != null 
                      ? child.getAgeString() 
                      : '${child.age} tahun'
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.checklist),
                title: const Text('Lihat Rapor'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParentChecklistScreen(child: child),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Data Anak'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddChildScreen(childToEdit: child),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red[700]),
                title: Text('Hapus Data Anak', style: TextStyle(color: Colors.red[700])),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteChild(context, child);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteChild(BuildContext context, ChildModel child) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data Anak'),
        content: Text('Apakah Anda yakin ingin menghapus data "${child.name}"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isDeleting = true);
              try {
                await Provider.of<ChildProvider>(context, listen: false).deleteChild(child.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data anak berhasil dihapus'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus data: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isDeleting = false);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
