import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/activity_model.dart';
import '/providers/child_provider.dart';
import '/providers/checklist_provider.dart';
import '/lib/theme/app_theme.dart';

class ActivityDetailScreen extends StatefulWidget {
  final ActivityModel activity;

  const ActivityDetailScreen({super.key, required this.activity});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final List<String> _selectedChildIds = [];
  bool _isAssigning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActivityHeader(),
            const SizedBox(height: 24),
            _buildActivityDescription(),
            const SizedBox(height: 24),
            _buildInstructionSteps(),
            const SizedBox(height: 24),
            _buildAssignToChildren(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.assignment_outlined,
            size: 40,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.activity.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildBadge(
                    widget.activity.difficulty,
                    _getDifficultyColor(widget.activity.difficulty),
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(
                    widget.activity.environment,
                    _getEnvironmentColor(widget.activity.environment),
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(
                    '${widget.activity.ageRange.min}-${widget.activity.ageRange.max} yrs',
                    AppTheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActivityDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          widget.activity.description,
          style: TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionSteps() {
    final steps =
        widget.activity.customSteps.isNotEmpty
            ? widget.activity.customSteps.first.steps
            : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Instruction Steps',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: AppTheme.surfaceVariant.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children:
                  steps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              step,
                              style: const TextStyle(fontSize: 16, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignToChildren() {
    return Consumer<ChildProvider>(
      builder: (context, childProvider, child) {
        if (childProvider.children.isEmpty) {
          return const SizedBox.shrink();
        }

        final children = childProvider.children;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assign to Children',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: AppTheme.surfaceVariant.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children:
                      children.map((child) {
                        final isSelected = _selectedChildIds.contains(child.id);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedChildIds.add(child.id);
                              } else {
                                _selectedChildIds.remove(child.id);
                              }
                            });
                          },
                          title: Text(
                            child.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${child.age} years old'),
                          secondary: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppTheme.primary
                                      : AppTheme.surfaceVariant,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSelected ? Icons.check : Icons.person,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppTheme.onSurfaceVariant,
                            ),
                          ),
                          activeColor: AppTheme.primary,
                          checkColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed:
                  _selectedChildIds.isEmpty || _isAssigning
                      ? null
                      : _assignToChildren,
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
                  _isAssigning
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        'Assign to ${_selectedChildIds.length} ${_selectedChildIds.length == 1 ? 'Child' : 'Children'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _assignToChildren() async {
    if (_selectedChildIds.isEmpty) {
      return;
    }

    setState(() {
      _isAssigning = true;
    });

    try {
      final checklistProvider = Provider.of<ChecklistProvider>(
        context,
        listen: false,
      );

      // Get the teacher ID for custom steps
      final customStepsUsed =
          widget.activity.customSteps.isNotEmpty
              ? [widget.activity.customSteps.first.teacherId]
              : <String>[];

      await checklistProvider.bulkAssignActivity(
        childIds: _selectedChildIds,
        activityId: widget.activity.id,
        customStepsUsed: customStepsUsed,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity assigned successfully'),
          backgroundColor: AppTheme.success,
        ),
      );

      setState(() {
        _selectedChildIds.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      setState(() {
        _isAssigning = false;
      });
    }
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
