import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/laravel_api/models/child_model.dart';
import '/laravel_api/providers/checklist_provider.dart';
import '/laravel_api/providers/child_provider.dart';
import '/laravel_api/providers/api_provider.dart';
import '/lib/theme/app_theme.dart';
import '/widgets/home/laravel_child_avatar.dart';

class TeacherChecklistScreen extends StatefulWidget {
  final ChildModel child;

  const TeacherChecklistScreen({
    super.key,
    required this.child,
  });

  @override
  State<TeacherChecklistScreen> createState() => _TeacherChecklistScreenState();
}

class _TeacherChecklistScreenState extends State<TeacherChecklistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load checklist items for this child
      Provider.of<ChecklistProvider>(context, listen: false)
          .fetchChecklistItems(widget.child.id);
          
      // Refresh child data to ensure we have the most current information
      Provider.of<ChildProvider>(context, listen: false)
          .fetchChildById(widget.child.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checklist ${widget.child.name}'),
      ),
      body: Consumer<ChecklistProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildChildHeader(),
              Expanded(
                child: provider.items.isEmpty
                    ? _buildEmptyState()
                    : _buildChecklist(provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_checklist_item',
        onPressed: () => _addChecklistItemDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryContainer.withAlpha(76),
      child: Row(
        children: [
          Hero(
            tag: 'child_avatar_${widget.child.id}',
            child: LaravelChildAvatar(
              child: widget.child, 
              size: 60,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.child.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.child.age} tahun',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist,
            size: 80,
            color: AppTheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Checklist',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Buat checklist baru dengan tombol + di bawah',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _addChecklistItemDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Checklist'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist(ChecklistProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.items.length,
      itemBuilder: (context, index) {
        final item = provider.items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              item.title,
              style: TextStyle(
                fontWeight: item.completed ? FontWeight.normal : FontWeight.bold,
                decoration: item.completed ? TextDecoration.lineThrough : null,
                color: item.completed 
                    ? AppTheme.onSurfaceVariant.withOpacity(0.7)
                    : null,
              ),
            ),
            subtitle: item.description.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.description,
                      style: TextStyle(
                        decoration: item.completed ? TextDecoration.lineThrough : null,
                        color: item.completed
                            ? AppTheme.onSurfaceVariant.withOpacity(0.6)
                            : AppTheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    item.completed
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: item.completed ? Colors.green : Colors.grey,
                  ),
                  onPressed: () {
                    provider.toggleItemCompletion(item.id, !item.completed);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editChecklistItemDialog(context, item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDeleteItem(context, item.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addChecklistItemDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Checklist Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                Provider.of<ChecklistProvider>(context, listen: false)
                    .addChecklistItem(
                  childId: widget.child.id,
                  title: titleController.text,
                  description: descriptionController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    titleController.dispose();
    descriptionController.dispose();
  }

  Future<void> _editChecklistItemDialog(BuildContext context, dynamic item) async {
    final titleController = TextEditingController(text: item.title);
    final descriptionController = TextEditingController(text: item.description);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Checklist'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                Provider.of<ChecklistProvider>(context, listen: false)
                    .updateChecklistItem(
                  id: item.id,
                  title: titleController.text,
                  description: descriptionController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    titleController.dispose();
    descriptionController.dispose();
  }

  void _confirmDeleteItem(BuildContext context, String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Checklist'),
        content: const Text('Apakah Anda yakin ingin menghapus checklist ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<ChecklistProvider>(context, listen: false)
                  .deleteChecklistItem(itemId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
} 