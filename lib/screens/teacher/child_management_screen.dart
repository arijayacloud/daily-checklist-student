import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/child_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/theme/app_colors_compat.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/empty_state.dart';

class ChildManagementScreen extends StatefulWidget {
  const ChildManagementScreen({super.key});

  @override
  State<ChildManagementScreen> createState() => _ChildManagementScreenState();
}

class _ChildManagementScreenState extends State<ChildManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      childProvider.loadChildrenForTeacher(authProvider.userModel!.id);
      await userProvider.loadParents(authProvider.userModel!.id);
    }
  }

  void _showAddChildDialog(BuildContext context) {
    final nameController = TextEditingController();
    final ageController = TextEditingController(text: '5');
    final notesController = TextEditingController();
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    String? selectedParentId;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tambah Siswa'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ageController,
                    decoration: const InputDecoration(
                      labelText: 'Usia',
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Orang Tua',
                      prefixIcon: Icon(Icons.family_restroom),
                    ),
                    hint: const Text('Pilih Orang Tua'),
                    value: selectedParentId,
                    items: [
                      ...userProvider.parents.map(
                        (parent) => DropdownMenuItem(
                          value: parent.id,
                          child: Text(parent.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      selectedParentId = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (Opsional)',
                      prefixIcon: Icon(Icons.note_outlined),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                  if (userProvider.parents.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Belum ada akun orang tua. Buat akun orang tua terlebih dahulu.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed:
                    userProvider.parents.isEmpty
                        ? () {
                          Navigator.of(context).pop();
                          _showCreateParentDialog(context);
                        }
                        : null,
                child: const Text('Buat Akun Orang Tua'),
              ),
              ElevatedButton(
                onPressed:
                    userProvider.parents.isEmpty
                        ? null
                        : () async {
                          if (nameController.text.isNotEmpty &&
                              selectedParentId != null) {
                            final childProvider = Provider.of<ChildProvider>(
                              context,
                              listen: false,
                            );
                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );

                            final age = int.tryParse(ageController.text) ?? 5;

                            final success = await childProvider.addChild(
                              name: nameController.text,
                              age: age,
                              parentId: selectedParentId!,
                              teacherId: authProvider.userModel!.id,
                            );

                            if (success && mounted) {
                              Navigator.of(context).pop();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Siswa berhasil ditambahkan'),
                                  backgroundColor: AppColors.complete,
                                ),
                              );
                            } else if (mounted) {
                              Navigator.of(context).pop();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    childProvider.errorMessage.isNotEmpty
                                        ? childProvider.errorMessage
                                        : 'Gagal menambahkan siswa',
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Nama siswa dan orang tua harus diisi',
                                ),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                          }
                        },
                child: const Text('Tambah'),
              ),
            ],
          ),
    );
  }

  void _showCreateParentDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Buat Akun Orang Tua'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Orang Tua',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.info),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Password akan dibuat secara otomatis dan dapat dilihat pada halaman manajemen pengguna.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty &&
                      emailController.text.isNotEmpty) {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    final userProvider = Provider.of<UserProvider>(
                      context,
                      listen: false,
                    );

                    final tempPassword = await authProvider.createParentAccount(
                      name: nameController.text,
                      email: emailController.text,
                      teacherId: authProvider.userModel!.id,
                    );

                    if (tempPassword != null && mounted) {
                      Navigator.of(context).pop();

                      // Refresh daftar orang tua
                      await userProvider.loadParents(
                        authProvider.userModel!.id,
                      );

                      // Tampilkan dialog sukses dengan password
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Akun Berhasil Dibuat'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Akun orang tua berhasil dibuat dengan detail:',
                                  ),
                                  const SizedBox(height: 12),
                                  _detailRow('Nama', nameController.text),
                                  _detailRow('Email', emailController.text),
                                  _detailRow(
                                    'Password',
                                    tempPassword,
                                    canCopy: true,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Catatan: Simpan password ini karena akan diperlukan untuk login pertama kali.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _showAddChildDialog(context);
                                  },
                                  child: const Text('Tambah Siswa'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Tutup'),
                                ),
                              ],
                            ),
                      );
                    } else if (mounted) {
                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            authProvider.errorMessage ??
                                'Gagal membuat akun orang tua',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Buat'),
              ),
            ],
          ),
    );
  }

  Widget _detailRow(String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
          if (canCopy)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                _copyToClipboard(value);
              },
              tooltip: 'Salin ke clipboard',
            ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      const SnackBar(
        content: Text('Teks disalin ke clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Siswa'), centerTitle: false),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari siswa',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: Builder(
                  builder: (context) {
                    if (childProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (childProvider.errorMessage.isNotEmpty) {
                      return Center(
                        child: Text(
                          'Error: ${childProvider.errorMessage}',
                          style: TextStyle(color: AppColors.error),
                        ),
                      );
                    }

                    if (childProvider.children.isEmpty) {
                      return const EmptyState(
                        icon: Icons.child_care,
                        title: 'Tidak Ada Siswa',
                        message:
                            'Ketuk tombol + di bawah untuk menambahkan siswa.',
                      );
                    }

                    final filteredChildren =
                        childProvider.children
                            .where(
                              (child) =>
                                  _searchQuery.isEmpty ||
                                  child.name.toLowerCase().contains(
                                    _searchQuery,
                                  ),
                            )
                            .toList();

                    if (filteredChildren.isEmpty) {
                      return Center(
                        child: Text(
                          'Tidak ada siswa dengan nama yang mengandung "$_searchQuery"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredChildren.length,
                      itemBuilder: (context, index) {
                        final child = filteredChildren[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                ChildAvatar(
                                  avatarUrl: child.avatarUrl,
                                  radius: 30,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        child.name,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Usia: ${child.age} tahun',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton(
                                  icon: const Icon(Icons.more_vert),
                                  itemBuilder:
                                      (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                color: AppColors.error,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Hapus',
                                                style: TextStyle(
                                                  color: AppColors.error,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showEditChildDialog(context, child);
                                    } else if (value == 'delete') {
                                      _showDeleteConfirmation(context, child);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddChildDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showEditChildDialog(BuildContext context, ChildModel child) {
    final nameController = TextEditingController(text: child.name);
    final ageController = TextEditingController(text: child.age.toString());
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    String? selectedParentId = child.parentId;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Siswa'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ageController,
                    decoration: const InputDecoration(
                      labelText: 'Usia',
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Orang Tua',
                      prefixIcon: Icon(Icons.family_restroom),
                    ),
                    hint: const Text('Pilih Orang Tua'),
                    value: selectedParentId,
                    items: [
                      ...userProvider.parents.map(
                        (parent) => DropdownMenuItem(
                          value: parent.id,
                          child: Text(parent.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      selectedParentId = value;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty &&
                      selectedParentId != null) {
                    final childProvider = Provider.of<ChildProvider>(
                      context,
                      listen: false,
                    );

                    final age = int.tryParse(ageController.text) ?? child.age;

                    // Buat objek ChildModel baru berdasarkan data yang ada
                    final updatedChild = ChildModel(
                      id: child.id,
                      name: nameController.text,
                      age: age,
                      parentId: selectedParentId!,
                      teacherId: child.teacherId,
                      avatarUrl: child.avatarUrl,
                      createdAt: child.createdAt,
                    );

                    final success = await childProvider.updateChild(
                      updatedChild,
                    );

                    if (success && mounted) {
                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Siswa berhasil diperbarui'),
                          backgroundColor: AppColors.complete,
                        ),
                      );
                    } else if (mounted) {
                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            childProvider.errorMessage.isNotEmpty
                                ? childProvider.errorMessage
                                : 'Gagal memperbarui siswa',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nama siswa dan orang tua harus diisi'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  }
                },
                child: const Text('Perbarui'),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ChildModel child) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Siswa'),
            content: Text(
              'Anda yakin ingin menghapus siswa ${child.name}? Tindakan ini tidak dapat dibatalkan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final childProvider = Provider.of<ChildProvider>(
                    context,
                    listen: false,
                  );

                  final success = await childProvider.deleteChild(child.id);

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Siswa berhasil dihapus'),
                        backgroundColor: AppColors.complete,
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          childProvider.errorMessage.isNotEmpty
                              ? childProvider.errorMessage
                              : 'Gagal menghapus siswa',
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
  }
}
