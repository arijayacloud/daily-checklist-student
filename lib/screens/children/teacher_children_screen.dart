import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/models/child_model.dart';
import '/providers/auth_provider.dart';
import '/providers/child_provider.dart';
import '/providers/checklist_provider.dart';
import '/screens/checklist/parent_checklist_screen.dart';
import '/screens/children/add_child_screen.dart';
import '/lib/theme/app_theme.dart';
import '/widgets/home/child_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      Provider.of<ChildProvider>(context, listen: false).fetchChildren();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChildModel> _getFilteredAndSortedChildren(List<ChildModel> children) {
    // Langkah 1: Filter berdasarkan pencarian
    List<ChildModel> filteredChildren = children;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredChildren =
          children.where((child) {
            return child.name.toLowerCase().contains(query) ||
                child.age.toString().contains(query);
          }).toList();
    }

    // Langkah 2: Filter berdasarkan usia
    if (_selectedAgeFilter != 'Semua') {
      final ageFilter = int.parse(_selectedAgeFilter.split(' ')[0]);
      filteredChildren =
          filteredChildren.where((child) => child.age == ageFilter).toList();
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
        filteredChildren.sort((a, b) => a.age.compareTo(b.age));
        break;
      case 'age_desc':
        filteredChildren.sort((a, b) => b.age.compareTo(a.age));
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Dropdown untuk filter umur
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAgeFilter,
                  isExpanded: true,
                  icon: const Icon(Icons.filter_list),
                  hint: const Text('Usia'),
                  items:
                      _ageFilters.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (newValue) {
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
          const SizedBox(width: 8),
          // Dropdown untuk sorting
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sortBy,
                  isExpanded: true,
                  icon: const Icon(Icons.sort),
                  hint: const Text('Urutkan'),
                  items:
                      _sortOptions.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                  onChanged: (newValue) {
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
    );
  }

  Widget _buildChildrenGrid() {
    return Consumer<ChildProvider>(
      builder: (context, childProvider, child) {
        if (childProvider.isLoading || _isDeleting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (childProvider.children.isEmpty) {
          return _buildEmptyState();
        }

        final filteredChildren = _getFilteredAndSortedChildren(
          childProvider.children,
        );

        if (filteredChildren.isEmpty) {
          return _buildNoResultsState();
        }

        // Menampilkan jumlah anak yang tampil dan total
        final totalChildren = childProvider.children.length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menampilkan ${filteredChildren.length} dari $totalChildren murid',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Muat ulang',
                    onPressed: () => childProvider.fetchChildren(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => childProvider.fetchChildren(),
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredChildren.length,
                  itemBuilder: (context, index) {
                    return _buildChildCard(
                      context,
                      filteredChildren[index],
                      index,
                    );
                  },
                ),
              ),
            ),
          ],
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
            'Belum ada murid',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan murid pertama Anda dengan menekan tombol +',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddChildScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Murid'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
            'Tidak ada murid yang cocok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah pencarian atau filter Anda',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _selectedAgeFilter = 'Semua';
                _sortBy = 'name_asc';
              });
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Reset Filter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, ChildModel child, int index) {
    return Card(
          elevation: 3,
          shadowColor: AppTheme.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              // Load checklist items for this child
              Provider.of<ChecklistProvider>(
                context,
                listen: false,
              ).fetchChecklistItems(child.id);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ParentChecklistScreen(child: child),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with Avatar and Name
                  Row(
                    children: [
                      // Avatar with decorated container
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ChildAvatar(child: child, size: 60),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${child.age} tahun',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Action buttons section - improved layout
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Button Lihat Aktivitas
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Provider.of<ChecklistProvider>(
                              context,
                              listen: false,
                            ).fetchChecklistItems(child.id);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        ParentChecklistScreen(child: child),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assignment_outlined, size: 18),
                          label: const Text('Lihat Aktivitas'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tombol Edit dan Hapus dalam satu row
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _editChild(context, child);
                                },
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: AppTheme.primary,
                                ),
                                label: const Text(
                                  'Edit',
                                  style: TextStyle(fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  side: BorderSide(
                                    color: AppTheme.primary.withOpacity(0.5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _showDeleteConfirmation(context, child);
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Hapus',
                                  style: TextStyle(fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(
                                    color: Colors.red,
                                    width: 0.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: 80 * index),
        )
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad);
  }

  // Fungsi untuk mengedit data anak
  void _editChild(BuildContext context, ChildModel child) {
    final nameController = TextEditingController(text: child.name);
    final ageController = TextEditingController(text: child.age.toString());
    int selectedAge = child.age;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Data Murid'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Murid',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedAge,
                  decoration: const InputDecoration(
                    labelText: 'Usia',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      List.generate(6, (index) => index + 3)
                          .map(
                            (age) => DropdownMenuItem(
                              value: age,
                              child: Text('$age tahun'),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedAge = value;
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('BATAL'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Validasi input
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nama tidak boleh kosong')),
                    );
                    return;
                  }

                  // Update data anak
                  _updateChildData(context, child.id, name, selectedAge);
                  Navigator.pop(context);
                },
                child: const Text('SIMPAN'),
              ),
            ],
          ),
    );
  }

  // Fungsi untuk menyimpan perubahan data anak ke Firebase
  Future<void> _updateChildData(
    BuildContext context,
    String childId,
    String name,
    int age,
  ) async {
    try {
      // Update data di Firestore
      await FirebaseFirestore.instance
          .collection('children')
          .doc(childId)
          .update({'name': name, 'age': age});

      // Refresh data
      if (!mounted) return;
      await Provider.of<ChildProvider>(context, listen: false).fetchChildren();

      // Tampilkan notifikasi sukses
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data murid berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      // Tampilkan pesan error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui data: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fungsi untuk menampilkan konfirmasi penghapusan
  void _showDeleteConfirmation(BuildContext context, ChildModel child) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Murid'),
            content: Text(
              'Apakah Anda yakin ingin menghapus ${child.name}? Semua data terkait murid ini akan terhapus secara permanen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('BATAL'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  _deleteChild(context, child.id);
                  Navigator.pop(context);
                },
                child: const Text('HAPUS'),
              ),
            ],
          ),
    );
  }

  // Fungsi untuk menghapus data anak dari Firebase
  Future<void> _deleteChild(BuildContext context, String childId) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      // 1. Hapus checklist items terkait anak
      final checklistSnapshot =
          await FirebaseFirestore.instance
              .collection('checklist_items')
              .where('childId', isEqualTo: childId)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in checklistSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 2. Hapus data anak
      batch.delete(
        FirebaseFirestore.instance.collection('children').doc(childId),
      );

      await batch.commit();

      // 3. Refresh data
      if (!mounted) return;
      await Provider.of<ChildProvider>(context, listen: false).fetchChildren();

      // 4. Tampilkan notifikasi sukses
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Murid berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      // Tampilkan pesan error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus murid: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }
}
