import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/activity_provider.dart';
import '/lib/theme/app_theme.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _environment = 'Both';
  String _difficulty = 'Medium';
  int _minAge = 3;
  int _maxAge = 6;
  final List<String> _steps = [''];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Filter out empty steps
    final steps = _steps.where((step) => step.trim().isNotEmpty).toList();

    if (steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tambahkan minimal satu langkah instruksi'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await Provider.of<ActivityProvider>(context, listen: false).addActivity(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        environment: _environment,
        difficulty: _difficulty,
        minAge: _minAge,
        maxAge: _maxAge,
        steps: steps,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktivitas berhasil dibuat'),
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

  void _addStep() {
    setState(() {
      _steps.add('');
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  void _updateStep(int index, String value) {
    setState(() {
      _steps[index] = value;
    });
  }

  String _getTranslatedEnvironment(String env) {
    switch (env) {
      case 'Home':
        return 'Rumah';
      case 'School':
        return 'Sekolah';
      case 'Both':
        return 'Keduanya';
      default:
        return env;
    }
  }

  String _getEnvironmentValue(String translatedEnv) {
    switch (translatedEnv) {
      case 'Rumah':
        return 'Home';
      case 'Sekolah':
        return 'School';
      case 'Keduanya':
        return 'Both';
      default:
        return translatedEnv;
    }
  }

  String _getTranslatedDifficulty(String diff) {
    switch (diff) {
      case 'Easy':
        return 'Mudah';
      case 'Medium':
        return 'Sedang';
      case 'Hard':
        return 'Sulit';
      default:
        return diff;
    }
  }

  String _getDifficultyValue(String translatedDiff) {
    switch (translatedDiff) {
      case 'Mudah':
        return 'Easy';
      case 'Sedang':
        return 'Medium';
      case 'Sulit':
        return 'Hard';
      default:
        return translatedDiff;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Aktivitas')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Aktivitas',
                  hintText: 'Masukkan judul untuk aktivitas',
                  filled: true,
                  fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Silakan masukkan judul';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Masukkan deskripsi untuk aktivitas',
                  filled: true,
                  fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Silakan masukkan deskripsi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Environment
              Text(
                'Lingkungan',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildEnvironmentOption('Rumah'),
                  _buildEnvironmentOption('Sekolah'),
                  _buildEnvironmentOption('Keduanya'),
                ],
              ),
              const SizedBox(height: 16),

              // Difficulty
              Text(
                'Tingkat Kesulitan',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildDifficultyOption('Mudah'),
                  _buildDifficultyOption('Sedang'),
                  _buildDifficultyOption('Sulit'),
                ],
              ),
              const SizedBox(height: 16),

              // Age Range
              Text(
                'Rentang Usia: $_minAge - $_maxAge tahun',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              RangeSlider(
                values: RangeValues(_minAge.toDouble(), _maxAge.toDouble()),
                min: 3,
                max: 6,
                divisions: 3,
                labels: RangeLabels(_minAge.toString(), _maxAge.toString()),
                onChanged: (values) {
                  setState(() {
                    _minAge = values.start.round();
                    _maxAge = values.end.round();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Instruction Steps
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Langkah-langkah Instruksi',
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addStep,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Langkah'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryContainer,
                      foregroundColor: AppTheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: AppTheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: step,
                          decoration: InputDecoration(
                            hintText: 'Masukkan langkah instruksi',
                            filled: true,
                            fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) => _updateStep(index, value),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: AppTheme.error,
                        onPressed:
                            _steps.length > 1 ? () => _removeStep(index) : null,
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _saveActivity,
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
                          'Simpan Aktivitas',
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

  Widget _buildEnvironmentOption(String option) {
    final translatedOption = option;
    final isSelected =
        _getTranslatedEnvironment(_environment) == translatedOption;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _environment = _getEnvironmentValue(translatedOption);
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? _getEnvironmentColor(
                      _getEnvironmentValue(translatedOption),
                    ).withOpacity(0.2)
                    : AppTheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border:
                isSelected
                    ? Border.all(
                      color: _getEnvironmentColor(
                        _getEnvironmentValue(translatedOption),
                      ),
                    )
                    : null,
          ),
          alignment: Alignment.center,
          child: Text(
            translatedOption,
            style: TextStyle(
              color:
                  isSelected
                      ? _getEnvironmentColor(
                        _getEnvironmentValue(translatedOption),
                      )
                      : AppTheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(String option) {
    final translatedOption = option;
    final isSelected =
        _getTranslatedDifficulty(_difficulty) == translatedOption;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _difficulty = _getDifficultyValue(translatedOption);
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? _getDifficultyColor(
                      _getDifficultyValue(translatedOption),
                    ).withOpacity(0.2)
                    : AppTheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border:
                isSelected
                    ? Border.all(
                      color: _getDifficultyColor(
                        _getDifficultyValue(translatedOption),
                      ),
                    )
                    : null,
          ),
          alignment: Alignment.center,
          child: Text(
            translatedOption,
            style: TextStyle(
              color:
                  isSelected
                      ? _getDifficultyColor(
                        _getDifficultyValue(translatedOption),
                      )
                      : AppTheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getEnvironmentColor(String environment) {
    switch (environment) {
      case 'Home':
        return Colors.purple;
      case 'School':
        return Colors.blue;
      case 'Both':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
