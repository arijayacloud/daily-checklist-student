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
import '/screens/checklist/parent_checklist_screen.dart';
import '/lib/theme/app_theme.dart';
import '/widgets/home/laravel_child_avatar.dart';

class ParentChildrenScreen extends StatefulWidget {
  const ParentChildrenScreen({super.key});

  @override
  State<ParentChildrenScreen> createState() => _ParentChildrenScreenState();
}

class _ParentChildrenScreenState extends State<ParentChildrenScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // For parents, we only need to fetch their own children
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated && authProvider.user?.isParent == true) {
        Provider.of<ChildProvider>(context, listen: false).fetchChildren();
      }
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
    return Scaffold(
      body: Column(
        children: [_buildSearchBar(), Expanded(child: _buildChildrenGrid())],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari anak...',
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
            'Silakan hubungi guru untuk menambahkan data anak Anda',
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
            'Tidak ada anak yang cocok',
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
            child: const Text('Reset Pencarian'),
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ParentChecklistScreen(child: child),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LaravelChildAvatar(
                child: child,
                size: 80, // Slightly reduced size
              ).animate().scale(
                curve: Curves.easeOutBack,
                duration: Duration(milliseconds: 400 + (index * 100)),
              ),
              const SizedBox(height: 12), // Changed from 16 to 12
              Flexible(  // Wrapped in Flexible to handle overflow better
                child: Text(
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
              const SizedBox(height: 16),
              _buildActionButton(
                icon: Icons.checklist,
                label: 'Rapor',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParentChecklistScreen(child: child),
                    ),
                  );
                },
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
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
