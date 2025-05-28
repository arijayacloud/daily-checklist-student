import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/activity_provider.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({Key? key}) : super(key: key);

  @override
  _AddActivityScreenState createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedEnvironment = 'both';
  String _selectedDifficulty = 'easy';

  final _environments = [
    {'value': 'home', 'label': 'Rumah'},
    {'value': 'school', 'label': 'Sekolah'},
    {'value': 'both', 'label': 'Keduanya'},
  ];

  final _difficulties = [
    {'value': 'easy', 'label': 'Mudah'},
    {'value': 'medium', 'label': 'Sedang'},
    {'value': 'hard', 'label': 'Sulit'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activityProvider = Provider.of<ActivityProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Aktivitas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Aktivitas',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Environment Dropdown
              DropdownButtonFormField<String>(
                value: _selectedEnvironment,
                decoration: InputDecoration(
                  labelText: 'Lingkungan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items:
                    _environments
                        .map(
                          (env) => DropdownMenuItem(
                            value: env['value'],
                            child: Text(env['label']!),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedEnvironment = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Difficulty Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDifficulty,
                decoration: InputDecoration(
                  labelText: 'Tingkat Kesulitan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items:
                    _difficulties
                        .map(
                          (difficulty) => DropdownMenuItem(
                            value: difficulty['value'],
                            child: Text(difficulty['label']!),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedDifficulty = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      activityProvider.isLoading
                          ? null
                          : () => _handleSubmit(context),
                  child:
                      activityProvider.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Simpan Aktivitas'),
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final activityProvider = Provider.of<ActivityProvider>(
        context,
        listen: false,
      );

      if (authProvider.user != null) {
        final success = await activityProvider.addActivity(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          environment: _selectedEnvironment,
          difficulty: _selectedDifficulty,
          teacherId: authProvider.user!.uid,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aktivitas berhasil ditambahkan')),
          );
          Navigator.pop(context);
        }
      }
    }
  }
}
