import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../models/child_model.dart';
import '../../models/user_model.dart';

class EditChildScreen extends StatefulWidget {
  final ChildModel child;

  const EditChildScreen({Key? key, required this.child}) : super(key: key);

  @override
  _EditChildScreenState createState() => _EditChildScreenState();
}

class _EditChildScreenState extends State<EditChildScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;

  List<Map<String, String>> _parentsList = [];
  String _selectedParentId = '';
  bool _isLoadingParents = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child.name);
    _ageController = TextEditingController(text: widget.child.age.toString());
    _selectedParentId = widget.child.parentId;
    _loadParents();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadParents() async {
    setState(() {
      _isLoadingParents = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final QuerySnapshot snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'parent')
                .where('createdBy', isEqualTo: authProvider.user!.uid)
                .get();

        List<Map<String, String>> parents = [];
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          parents.add({
            'id': doc.id,
            'name': data['name'] ?? 'Nama tidak diketahui',
          });
        }

        setState(() {
          _parentsList = parents;
          _isLoadingParents = false;
        });
      }
    } catch (e) {
      print('Error loading parents: $e');
      setState(() {
        _isLoadingParents = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Data Anak')),
      body:
          _isLoadingParents
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar preview
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(
                                widget.child.avatarUrl,
                              ),
                              radius: 50,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Avatar akan diperbarui jika nama diubah',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Anak',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Age
                      TextFormField(
                        controller: _ageController,
                        decoration: InputDecoration(
                          labelText: 'Usia',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Usia wajib diisi';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Usia harus berupa angka';
                          }
                          final age = int.parse(value);
                          if (age < 3 || age > 6) {
                            return 'Usia harus antara 3-6 tahun';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Parent Dropdown
                      DropdownButtonFormField<String>(
                        value:
                            _parentsList.any(
                                  (p) => p['id'] == _selectedParentId,
                                )
                                ? _selectedParentId
                                : (_parentsList.isNotEmpty
                                    ? _parentsList[0]['id']
                                    : null),
                        decoration: InputDecoration(
                          labelText: 'Orangtua',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items:
                            _parentsList
                                .map(
                                  (parent) => DropdownMenuItem(
                                    value: parent['id'],
                                    child: Text(parent['name']!),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedParentId = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              childProvider.isLoading
                                  ? null
                                  : () => _handleSubmit(context),
                          child:
                              childProvider.isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Simpan Perubahan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final childProvider = Provider.of<ChildProvider>(context, listen: false);

      // Buat avatar URL baru jika nama berubah
      String avatarUrl = widget.child.avatarUrl;
      if (_nameController.text.trim() != widget.child.name) {
        avatarUrl =
            'https://api.dicebear.com/7.x/avataaars/svg?seed=${_nameController.text.trim()}';
      }

      // Buat objek ChildModel baru dengan data yang diperbarui
      ChildModel updatedChild = ChildModel(
        id: widget.child.id,
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        parentId: _selectedParentId,
        teacherId: widget.child.teacherId,
        avatarUrl: avatarUrl,
        createdAt: widget.child.createdAt,
      );

      final success = await childProvider.updateChild(updatedChild);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data anak berhasil diperbarui')),
        );
        Navigator.pop(context);
      }
    }
  }
}
