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
  Set<String> _deletingChildIds = {}; // Track which children are being deleted
  
  // New age filtering approach with range values - updated range from 2.0 to 6.0
  double _minAgeFilter = 2.0;
  double _maxAgeFilter = 6.0;
  String _sortBy = 'name_asc';

  // Sort options remain the same
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

  // Calculate precise age including half years
  double _calculatePreciseAge(ChildModel child) {
    if (child.dateOfBirth != null) {
      // If we have a date of birth, calculate the precise age including months
      DateTime now = DateTime.now();
      DateTime birthDate = child.dateOfBirth!;
      
      // Calculate years
      int years = now.year - birthDate.year;
      
      // Adjust for months to get half-years
      int months = now.month - birthDate.month;
      if (now.day < birthDate.day) {
        months--;
      }
      
      // If months are negative, adjust the years
      if (months < 0) {
        years--;
        months += 12;
      }
      
      // Convert to decimal age (e.g., 3.5 years)
      double age = years + (months / 12.0);
      
      // Round to nearest 0.5 for consistency with the filter
      return (age * 2).round() / 2;
    } else {
      // If no date of birth, use the stored age value
      return child.age.toDouble();
    }
  }

  List<ChildModel> _getFilteredAndSortedChildren(List<ChildModel> children) {
    // Langkah 1: Filter berdasarkan pencarian
    List<ChildModel> filteredChildren = List.from(children);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredChildren = children.where((child) {
        final age = _calculatePreciseAge(child);
        return child.name.toLowerCase().contains(query) ||
            age.toString().contains(query);
      }).toList();
    }

    // Langkah 2: Filter berdasarkan rentang usia
    filteredChildren = filteredChildren.where((child) {
      // Get precise age using our helper method
      double childAge = _calculatePreciseAge(child);
      
      debugPrint('Child: ${child.name}, Age: $childAge, Filter Range: $_minAgeFilter-$_maxAgeFilter');
      
      // Check if the child's age is within the selected range
      return childAge >= _minAgeFilter && childAge <= _maxAgeFilter;
    }).toList();

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
          final ageA = _calculatePreciseAge(a);
          final ageB = _calculatePreciseAge(b);
          return ageA.compareTo(ageB);
        });
        break;
      case 'age_desc':
        filteredChildren.sort((a, b) {
          final ageA = _calculatePreciseAge(a);
          final ageB = _calculatePreciseAge(b);
          return ageB.compareTo(ageA);
        });
        break;
    }

    return filteredChildren;
  }

  // Format age to display half years correctly (3.5 -> "3,5")
  String _formatAgeDisplay(double age) {
    // Convert to string with comma as decimal separator for Indonesian format
    return age.toString().replaceAll('.', ',');
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
                    label: 'Usia: ${_formatAgeDisplay(_minAgeFilter)}-${_formatAgeDisplay(_maxAgeFilter)} tahun',
                    isSelected: _minAgeFilter != 2.0 || _maxAgeFilter != 6.0,
                    onSelected: (_) => _showFilterDialog(),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: _getSortLabel(),
                    isSelected: _sortBy != 'name_asc',
                    onSelected: (_) => _showFilterDialog(),
                  ),
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

  String _getSortLabel() {
    return _sortOptions[_sortBy] ?? 'Nama (A-Z)';
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
                      const Text(
                        'Filter Anak',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _minAgeFilter = 2.0;
                            _maxAgeFilter = 6.0;
                            _sortBy = 'name_asc';
                          });
                        },
                        child: const Text('Atur Ulang'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Age range filter
                  const Text(
                    'Rentang Usia',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: RangeValues(
                      _minAgeFilter,
                      _maxAgeFilter,
                    ),
                    min: 2.0,
                    max: 6.0,
                    divisions: 8, // 8 divisions for 0.5 increments between 2.0 and 6.0
                    labels: RangeLabels(
                      _formatAgeDisplay(_minAgeFilter),
                      _formatAgeDisplay(_maxAgeFilter),
                    ),
                    onChanged: (values) {
                      setState(() {
                        _minAgeFilter = values.start;
                        _maxAgeFilter = values.end;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '2,0 tahun',
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                      Text(
                        '6,0 tahun',
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sorting options
                  const Text(
                    'Urutkan Berdasarkan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _sortOptions.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(entry.value),
                            selected: _sortBy == entry.key,
                            onSelected: (selected) {
                              setState(() {
                                _sortBy = entry.key;
                              });
                            },
                            selectedColor: AppTheme.primaryContainer,
                            checkmarkColor: AppTheme.onPrimaryContainer,
                            labelStyle: TextStyle(
                              color: _sortBy == entry.key 
                                  ? AppTheme.onPrimaryContainer 
                                  : AppTheme.onSurface,
                              fontWeight: _sortBy == entry.key 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Apply button
                  ElevatedButton(
                    onPressed: () {
                      this.setState(() {
                        // Update the parent state
                        this._minAgeFilter = _minAgeFilter;
                        this._maxAgeFilter = _maxAgeFilter;
                        this._sortBy = _sortBy;
                      });
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
              childAspectRatio: 0.75,
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
                _minAgeFilter = 2.0;
                _maxAgeFilter = 6.0;
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
    // Calculate the precise age for display
    final preciseAge = _calculatePreciseAge(child);
    final formattedAge = _formatAgeDisplay(preciseAge);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ParentChecklistScreen(child: child),
            ),
          );
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LaravelChildAvatar(
                    child: child,
                    size: 85,
                  ).animate().scale(
                    curve: Curves.easeOutBack,
                    duration: Duration(milliseconds: 400 + (index * 100)),
                  ),
                  const SizedBox(height: 10),
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
                    '$formattedAge tahun',
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ).animate().fadeIn(
                    curve: Curves.easeOut,
                    duration: Duration(milliseconds: 400 + (index * 100)),
                    delay: const Duration(milliseconds: 300),
                  ),
                  const SizedBox(height: 12),
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
                      const SizedBox(width: 6),
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
                      const SizedBox(width: 6),
                      _buildDeleteButton(onTap: () => _confirmDeleteChild(context, child)),
                    ],
                  ).animate().fadeIn(
                    curve: Curves.easeOut,
                    duration: Duration(milliseconds: 400 + (index * 100)),
                    delay: const Duration(milliseconds: 400),
                  ),
                ],
              ),
            ),
            // Loading overlay when deleting
            if (_deletingChildIds.contains(child.id))
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
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

  Widget _buildDeleteButton({required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete, size: 16, color: Colors.red),
              const SizedBox(height: 4),
              const Text(
                'Hapus',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
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
              setState(() => _deletingChildIds.add(child.id));
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
                  setState(() => _deletingChildIds.remove(child.id));
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
