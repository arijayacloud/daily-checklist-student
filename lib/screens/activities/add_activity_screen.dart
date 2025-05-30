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
          content: Text('Please add at least one instruction step'),
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
          content: Text('Activity created successfully'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Activity')),
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
                  labelText: 'Activity Title',
                  hintText: 'Enter a title for the activity',
                  filled: true,
                  fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
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
                  labelText: 'Description',
                  hintText: 'Enter a description for the activity',
                  filled: true,
                  fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Environment
              Text(
                'Environment',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildEnvironmentOption('Home'),
                  _buildEnvironmentOption('School'),
                  _buildEnvironmentOption('Both'),
                ],
              ),
              const SizedBox(height: 16),

              // Difficulty
              Text(
                'Difficulty',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildDifficultyOption('Easy'),
                  _buildDifficultyOption('Medium'),
                  _buildDifficultyOption('Hard'),
                ],
              ),
              const SizedBox(height: 16),

              // Age Range
              Text(
                'Age Range: $_minAge - $_maxAge years',
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
                    'Instruction Steps',
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addStep,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Step'),
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
                            hintText: 'Enter instruction step',
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
                          'Save Activity',
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
    final isSelected = _environment == option;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _environment = option;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? _getEnvironmentColor(option).withOpacity(0.2)
                    : AppTheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border:
                isSelected
                    ? Border.all(color: _getEnvironmentColor(option))
                    : null,
          ),
          alignment: Alignment.center,
          child: Text(
            option,
            style: TextStyle(
              color:
                  isSelected
                      ? _getEnvironmentColor(option)
                      : AppTheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(String option) {
    final isSelected = _difficulty == option;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _difficulty = option;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? _getDifficultyColor(option).withOpacity(0.2)
                    : AppTheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border:
                isSelected
                    ? Border.all(color: _getDifficultyColor(option))
                    : null,
          ),
          alignment: Alignment.center,
          child: Text(
            option,
            style: TextStyle(
              color:
                  isSelected
                      ? _getDifficultyColor(option)
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
