import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/child_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../core/theme/app_colors_compat.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/empty_state.dart';

class ChildManagementScreen extends StatefulWidget {
  const ChildManagementScreen({super.key});

  @override
  State<ChildManagementScreen> createState() => _ChildManagementScreenState();
}

class _ChildManagementScreenState extends State<ChildManagementScreen> {
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
    if (authProvider.userModel != null) {
      childProvider.loadChildrenForTeacher(authProvider.userModel!.id);
    }
  }

  void _showAddChildDialog(BuildContext context) {
    final nameController = TextEditingController();
    final ageController = TextEditingController(text: '5');
    final notesController = TextEditingController();

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
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (Opsional)',
                      prefixIcon: Icon(Icons.note_outlined),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
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
                  if (nameController.text.isNotEmpty) {
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
                      parentId: authProvider.userModel!.id,
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
                            childProvider.errorMessage ??
                                'Gagal menambahkan siswa',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
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
    final passwordController = TextEditingController();

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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
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
                      emailController.text.isNotEmpty &&
                      passwordController.text.isNotEmpty) {
                    final authProvider = Provider.of<AuthProvider>(
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

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Akun orang tua berhasil dibuat'),
                          backgroundColor: AppColors.complete,
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

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Siswa'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showCreateParentDialog(context),
            tooltip: 'Buat Akun Orang Tua',
          ),
        ],
      ),
      body: SafeArea(
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
                  message: 'Ketuk tombol + di bawah untuk menambahkan siswa.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: childProvider.children.length,
                itemBuilder: (context, index) {
                  final child = childProvider.children[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          ChildAvatar(avatarUrl: child.avatarUrl, radius: 30),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  child.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Usia: ${child.age}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              // Show edit dialog
                              _showEditChildDialog(context, child);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddChildDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditChildDialog(BuildContext context, ChildModel child) {
    final nameController = TextEditingController(text: child.name);
    final ageController = TextEditingController(text: child.age.toString());

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
                  if (nameController.text.isNotEmpty) {
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
                      parentId: child.parentId,
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
                            childProvider.errorMessage ??
                                'Gagal memperbarui siswa',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Perbarui'),
              ),
            ],
          ),
    );
  }
}
