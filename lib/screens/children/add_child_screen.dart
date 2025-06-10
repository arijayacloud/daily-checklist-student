import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Laravel API providers
import '/laravel_api/providers/auth_provider.dart';
import '/laravel_api/providers/child_provider.dart';
import '/laravel_api/providers/user_provider.dart';
import '/laravel_api/models/user_model.dart';
import '/laravel_api/models/child_model.dart';

import '/lib/theme/app_theme.dart';

class AddChildScreen extends StatefulWidget {
  final ChildModel? childToEdit;
  
  const AddChildScreen({super.key, this.childToEdit});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  int _age = 4;
  bool _isSubmitting = false;
  bool _isLoadingParents = true;
  List<dynamic> _parents = [];
  String? _selectedParentId;

  @override
  void initState() {
    super.initState();
    _fetchParents();
  }

  // Fetch existing parents
  Future<void> _fetchParents() async {
    setState(() {
      _isLoadingParents = true;
    });

    try {
      // Fetch parents from Laravel API
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchParents();
      setState(() {
        _parents = userProvider.parents;
        // Pre-select first parent if available
        _selectedParentId = _parents.isNotEmpty ? _parents.first.id : null;
        _isLoadingParents = false;
      });
    } catch (e) {
      print('Error fetching parents: $e');
      setState(() {
        _isLoadingParents = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChild() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Use selected parent ID
      if (_selectedParentId == null) {
        throw 'Silahkan pilih orang tua';
      }
      String parentId = _selectedParentId!;

      // Generate avatar URL using DiceBear API
      final name = _nameController.text.trim();
      final seed = Uri.encodeComponent(name);
      final avatarUrl = 'https://api.dicebear.com/9.x/thumbs/png?seed=$seed';

      // Add child using Laravel API
      await Provider.of<ChildProvider>(context, listen: false).addChild(
        name: name,
        age: _age,
        parentId: parentId,
        avatarUrl: avatarUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anak berhasil ditambahkan'),
          backgroundColor: AppTheme.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Murid')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Child information
              const Text(
                'Informasi Anak',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Child name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Anak',
                  hintText: 'Masukkan nama anak',
                  filled: true,
                  fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Silahkan masukkan nama';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Child age
              Text(
                'Usia: $_age tahun',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              Slider(
                value: _age.toDouble(),
                min: 3,
                max: 6,
                divisions: 3,
                label: _age.toString(),
                onChanged: (value) {
                  setState(() {
                    _age = value.round();
                  });
                },
              ),
              const SizedBox(height: 24),

              // Parent information
              const Text(
                'Informasi Orang Tua',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Dropdown to select existing parent
              _isLoadingParents
                  ? const Center(child: CircularProgressIndicator())
                  : _parents.isEmpty
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tidak ada orang tua yang tersedia.',
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/add-parent',
                          ).then((_) => _fetchParents());
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Orang Tua Baru'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedParentId,
                        decoration: InputDecoration(
                          labelText: 'Pilih Orang Tua',
                          filled: true,
                          fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _parents.map((parent) {
                          return DropdownMenuItem<String>(
                            value: parent.id,
                            child: Text('${parent.name} (${parent.email})'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedParentId = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Silahkan pilih orang tua';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/add-parent',
                          ).then((_) => _fetchParents());
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Orang Tua Baru'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),

              const SizedBox(height: 32),

              // Save button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _saveChild,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.primary.withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Tambah Murid',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
