import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../models/child_model.dart';
import 'add_child_screen.dart';

class ChildScreen extends StatefulWidget {
  const ChildScreen({Key? key}) : super(key: key);

  @override
  _ChildScreenState createState() => _ChildScreenState();
}

class _ChildScreenState extends State<ChildScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChildren();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadChildren() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      Provider.of<ChildProvider>(
        context,
        listen: false,
      ).loadChildrenForTeacher(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context);
    final children = childProvider.children;

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Anak')),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari anak...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                childProvider.setSearchQuery(value);
              },
            ),
          ),

          // Children List
          Expanded(
            child:
                childProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : children.isEmpty
                    ? const Center(
                      child: Text('Belum ada anak. Tambahkan anak baru.'),
                    )
                    : ListView.builder(
                      itemCount: children.length,
                      itemBuilder: (context, index) {
                        final child = children[index];
                        return _buildChildCard(context, child);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddChildScreen()),
          ).then((_) => _loadChildren());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, ChildModel child) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(child.avatarUrl),
          radius: 25,
        ),
        title: Text(child.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usia: ${child.age} tahun'),
            FutureBuilder<String?>(
              future: _getParentName(child.parentId),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Text('Orangtua: ${snapshot.data}');
                }
                return const Text('Orangtua: Memuat...');
              },
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              // TODO: Navigate to edit screen
            } else if (value == 'delete') {
              _confirmDelete(context, child);
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
        ),
        onTap: () {
          // TODO: Show child details
        },
      ),
    );
  }

  Future<String?> _getParentName(String parentId) async {
    // TODO: Implement a service to get parent name from ID
    // For now, return a placeholder
    return 'Orangtua #$parentId';
  }

  Future<void> _confirmDelete(BuildContext context, ChildModel child) async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text(
              'Apakah Anda yakin ingin menghapus anak "${child.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (result == true) {
      await childProvider.deleteChild(child.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anak "${child.name}" berhasil dihapus')),
        );
      }
    }
  }
}
