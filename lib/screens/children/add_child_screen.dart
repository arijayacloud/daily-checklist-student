import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
  DateTime _dateOfBirth = DateTime.now().subtract(const Duration(days: 365 * 4)); // Default to 4 years old
  bool _isSubmitting = false;
  bool _isLoadingParents = true;
  List<dynamic> _parents = [];
  String? _selectedParentId;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _fetchParents();
    
    // Initialize form with existing data if editing
    if (widget.childToEdit != null) {
      _isEditMode = true;
      _nameController.text = widget.childToEdit!.name;
      
      // Use date of birth if available, otherwise estimate from age
      if (widget.childToEdit!.dateOfBirth != null) {
        _dateOfBirth = widget.childToEdit!.dateOfBirth!;
      } else {
        // Estimate DOB from age
        _dateOfBirth = DateTime.now().subtract(Duration(days: 365 * widget.childToEdit!.age));
      }
      
      _selectedParentId = widget.childToEdit!.parentId;
    }
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

  // Calculate age from date of birth
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    // Adjust age if birthday hasn't occurred yet this year
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
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
      
      // Calculate age from date of birth
      final age = _calculateAge(_dateOfBirth);

      // If editing existing child
      if (widget.childToEdit != null) {
        // Update existing child
        await Provider.of<ChildProvider>(context, listen: false).updateChild(
          id: widget.childToEdit!.id,
          name: name,
          age: age,
          dateOfBirth: _dateOfBirth,
          avatarUrl: avatarUrl,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data anak berhasil diperbarui'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        // Add new child
        await Provider.of<ChildProvider>(context, listen: false).addChild(
          name: name,
          age: age,
          dateOfBirth: _dateOfBirth,
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
      }

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(DateTime.now().year - 7), // Allow up to 7 years old
      lastDate: DateTime.now(),
      helpText: 'Pilih Tanggal Lahir',
      cancelText: 'BATAL',
      confirmText: 'PILIH',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate current age from selected date of birth
    final currentAge = _calculateAge(_dateOfBirth);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.childToEdit != null ? 'Edit Data Murid' : 'Tambah Murid')
      ),
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

              // Date of Birth picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanggal Lahir',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMMM yyyy').format(_dateOfBirth),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Usia saat ini: $currentAge tahun',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Ubah'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryContainer,
                      foregroundColor: AppTheme.onPrimaryContainer,
                    ),
                  ),
                ],
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
                        : Text(
                          widget.childToEdit != null ? 'Simpan Perubahan' : 'Tambah Murid',
                          style: const TextStyle(
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
