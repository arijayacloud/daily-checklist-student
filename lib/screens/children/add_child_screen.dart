import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/providers/child_provider.dart';
import '/lib/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/user_model.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPasswordController = TextEditingController();
  int _age = 4;
  bool _createNewParent = false;

  bool _isSubmitting = false;
  bool _isLoadingParents = true;
  List<UserModel> _parents = [];
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Only fetch parents created by current teacher
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'parent')
              .where('createdBy', isEqualTo: authProvider.userId)
              .get();

      final parents =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return UserModel.fromJson({'id': doc.id, ...data});
          }).toList();

      setState(() {
        _parents = parents;
        // Pre-select first parent if available
        _selectedParentId = parents.isNotEmpty ? parents.first.id : null;
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
    _parentEmailController.dispose();
    _parentNameController.dispose();
    _parentPasswordController.dispose();
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
      String parentId = '';

      // If creating a new parent
      if (_createNewParent) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Create parent account
        await authProvider.createParentAccount(
          _parentEmailController.text.trim(),
          _parentNameController.text.trim(),
          _parentPasswordController.text,
        );

        // Fetch the newly created parent
        final snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: _parentEmailController.text.trim())
                .limit(1)
                .get();

        if (snapshot.docs.isNotEmpty) {
          parentId = snapshot.docs.first.id;
        } else {
          throw 'Failed to find newly created parent';
        }
      } else {
        // Use selected parent ID
        if (_selectedParentId == null) {
          throw 'Please select a parent';
        }
        parentId = _selectedParentId!;
      }

      // Generate avatar URL using DiceBear API
      final name = _nameController.text.trim();
      final seed = Uri.encodeComponent(name);
      final avatarUrl = 'https://api.dicebear.com/9.x/thumbs/png?seed=$seed';

      // Add child
      await Provider.of<ChildProvider>(context, listen: false).addChild(
        name: name,
        age: _age,
        parentId: parentId,
        avatarUrl: avatarUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Child added successfully'),
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
      appBar: AppBar(title: const Text('Add Student')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Child information
              const Text(
                'Child Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Child name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Child Name',
                  hintText: 'Enter the child\'s name',
                  filled: true,
                  fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Child age
              Text(
                'Age: $_age years',
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
                'Parent Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Create new parent or use existing
              SwitchListTile(
                title: const Text('Create new parent account'),
                value: _createNewParent,
                onChanged: (value) {
                  setState(() {
                    _createNewParent = value;
                  });
                },
                activeColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              if (_createNewParent) ...[
                // Parent email
                TextFormField(
                  controller: _parentEmailController,
                  decoration: InputDecoration(
                    labelText: 'Parent Email',
                    hintText: 'Enter the parent\'s email',
                    filled: true,
                    fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (_createNewParent &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please enter an email';
                    }
                    if (_createNewParent &&
                        (!value!.contains('@') || !value.contains('.'))) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _parentNameController,
                  decoration: InputDecoration(
                    labelText: 'Parent Name',
                    hintText: 'Enter the parent\'s name',
                    filled: true,
                    fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (_createNewParent &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _parentPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Temporary Password',
                    hintText: 'Create a temporary password',
                    filled: true,
                    fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (_createNewParent &&
                        (value == null || value.length < 6)) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Note: The parent will be asked to change this password on first login.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else ...[
                // Dropdown to select existing parent
                _isLoadingParents
                    ? const Center(child: CircularProgressIndicator())
                    : _parents.isEmpty
                    ? const Text(
                      'No parents available. Please create a new parent account.',
                      style: TextStyle(color: Colors.red),
                    )
                    : DropdownButtonFormField<String>(
                      value: _selectedParentId,
                      decoration: InputDecoration(
                        labelText: 'Select Parent',
                        filled: true,
                        fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items:
                          _parents.map((parent) {
                            return DropdownMenuItem(
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
                        if (!_createNewParent && value == null) {
                          return 'Please select a parent';
                        }
                        return null;
                      },
                    ),
              ],

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
                          'Add Student',
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
