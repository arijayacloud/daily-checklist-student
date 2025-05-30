import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/activity_model.dart';
import '/models/checklist_item_model.dart';
import '/models/child_model.dart';
import '/providers/checklist_provider.dart';
import '/lib/theme/app_theme.dart';
import '/widgets/home/child_avatar.dart';

class ObservationFormScreen extends StatefulWidget {
  final ChildModel child;
  final ChecklistItemModel item;
  final ActivityModel activity;
  final bool isTeacher;

  const ObservationFormScreen({
    super.key,
    required this.child,
    required this.item,
    required this.activity,
    required this.isTeacher,
  });

  @override
  State<ObservationFormScreen> createState() => _ObservationFormScreenState();
}

class _ObservationFormScreenState extends State<ObservationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  int _durationMinutes = 15;
  int _engagement = 3;
  final _notesController = TextEditingController();
  final _learningOutcomesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    _learningOutcomesController.dispose();
    super.dispose();
  }

  Future<void> _submitObservation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final checklistProvider = Provider.of<ChecklistProvider>(
        context,
        listen: false,
      );

      if (widget.isTeacher) {
        await checklistProvider.addSchoolObservation(
          itemId: widget.item.id,
          duration: _durationMinutes,
          engagement: _engagement,
          notes: _notesController.text,
          learningOutcomes: _learningOutcomesController.text,
        );
      } else {
        await checklistProvider.addHomeObservation(
          itemId: widget.item.id,
          duration: _durationMinutes,
          engagement: _engagement,
          notes: _notesController.text,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Observation submitted successfully'),
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
      appBar: AppBar(title: const Text('Complete Activity')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildActivityInfo(),
              const SizedBox(height: 24),
              _buildObservationForm(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        ChildAvatar(child: widget.child, size: 50),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.child.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.child.age} years old',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(
                      widget.activity.difficulty,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.activity.difficulty,
                    style: TextStyle(
                      color: _getDifficultyColor(widget.activity.difficulty),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getEnvironmentColor(
                      widget.activity.environment,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.activity.environment,
                    style: TextStyle(
                      color: _getEnvironmentColor(widget.activity.environment),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.activity.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.activity.description,
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Observation Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Duration slider
        const Text(
          'Duration (minutes):',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _durationMinutes.toDouble(),
                min: 5,
                max: 60,
                divisions: 11,
                label: _durationMinutes.toString(),
                onChanged: (value) {
                  setState(() {
                    _durationMinutes = value.round();
                  });
                },
              ),
            ),
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '$_durationMinutes',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Engagement rating
        const Text(
          'Engagement Level:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final rating = index + 1;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _engagement = rating;
                });
              },
              child: Column(
                children: [
                  Icon(
                    rating <= _engagement ? Icons.star : Icons.star_border,
                    color:
                        rating <= _engagement
                            ? Colors.amber
                            : AppTheme.onSurfaceVariant,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rating.toString(),
                    style: TextStyle(
                      color:
                          rating <= _engagement
                              ? AppTheme.onSurface
                              : AppTheme.onSurfaceVariant,
                      fontWeight:
                          rating <= _engagement
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // Notes
        const Text('Notes:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter your observations about the activity...',
            filled: true,
            fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter some notes';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Learning outcomes (for teachers only)
        if (widget.isTeacher) ...[
          const Text(
            'Learning Outcomes:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _learningOutcomesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'What did the child learn from this activity?',
              filled: true,
              fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (widget.isTeacher && (value == null || value.isEmpty)) {
                return 'Please enter learning outcomes';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitObservation,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppTheme.primary,
        disabledBackgroundColor: AppTheme.primary.withOpacity(0.6),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                'Submit Observation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
