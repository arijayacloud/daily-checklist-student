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

class TeacherChildrenScreen extends StatefulWidget {
  const TeacherChildrenScreen({super.key});

  @override
  State<TeacherChildrenScreen> createState() => _TeacherChildrenScreenState();
}

class _TeacherChildrenScreenState extends State<TeacherChildrenScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

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

  List<ChildModel> _getFilteredChildren(List<ChildModel> children) {
    if (_searchQuery.isEmpty) {
      return children;
    }

    final query = _searchQuery.toLowerCase();
    return children.where((child) {
      return child.name.toLowerCase().contains(query) ||
          child.age.toString().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Murid Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddChildScreen()),
              );
            },
            tooltip: 'Tambah Murid',
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => authProvider.signOut(),
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: Column(
        children: [_buildSearchBar(), Expanded(child: _buildChildrenGrid())],
      ),
      floatingActionButton: FloatingActionButton(
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
      padding: const EdgeInsets.all(16),
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

  Widget _buildChildrenGrid() {
    return Consumer<ChildProvider>(
      builder: (context, childProvider, child) {
        if (childProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (childProvider.children.isEmpty) {
          return _buildEmptyState();
        }

        final filteredChildren = _getFilteredChildren(childProvider.children);

        if (filteredChildren.isEmpty) {
          return _buildNoResultsState();
        }

        return RefreshIndicator(
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
            'Coba ubah kata pencarian Anda',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus Pencarian'),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, ChildModel child, int index) {
    return Card(
          elevation: 2,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChildAvatar(child: child, size: 80),
                  const SizedBox(height: 4),
                  Text(
                    child.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${child.age} tahun',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Lihat Aktivitas',
                      style: TextStyle(
                        color: AppTheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 500),
          delay: Duration(milliseconds: 100 * index),
        )
        .slideY(begin: 0.2, end: 0);
  }
}
