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
      appBar: AppBar(title: const Text('Detail Aktivitas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 24),
            _buildInfoSection(),
            const SizedBox(height: 24),
            _buildStepsSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.activity.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(
                      widget.activity.difficulty,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _translateDifficultyToIndonesian(
                      widget.activity.difficulty,
                    ),
                    style: TextStyle(
                      color: _getDifficultyColor(widget.activity.difficulty),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _getEnvironmentIcon(widget.activity.environment),
                  color: _getEnvironmentColor(widget.activity.environment),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _translateEnvironmentToIndonesian(
                    widget.activity.environment,
                  ),
                  style: TextStyle(
                    color: _getEnvironmentColor(widget.activity.environment),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  color: AppTheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Usia ${widget.activity.ageRange.min}-${widget.activity.ageRange.max} tahun',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.activity.description,
              style: TextStyle(fontSize: 16, color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Aktivitas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  'Tingkat Kesulitan',
                  _translateDifficultyToIndonesian(widget.activity.difficulty),
                  _getDifficultyColor(widget.activity.difficulty),
                ),
                const Divider(),
                _buildInfoRow(
                  'Lingkungan',
                  _translateEnvironmentToIndonesian(
                    widget.activity.environment,
                  ),
                  _getEnvironmentColor(widget.activity.environment),
                ),
                const Divider(),
                _buildInfoRow(
                  'Rentang Usia',
                  '${widget.activity.ageRange.min}-${widget.activity.ageRange.max} tahun',
                  AppTheme.primary,
                ),
                if (widget.activity.nextActivityId != null) ...[
                  const Divider(),
                  _buildInfoRow(
                    'Aktivitas Lanjutan',
                    'Tersedia',
                    AppTheme.tertiary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsSection() {
    final steps =
        widget.activity.customSteps.isNotEmpty
            ? widget.activity.customSteps.first.steps
            : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Langkah-langkah Aktivitas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                steps.isEmpty
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Tidak ada langkah yang ditentukan untuk aktivitas ini',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                    : Column(
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
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: AppTheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      step,
                                      style: const TextStyle(fontSize: 16),
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

  IconData _getEnvironmentIcon(String environment) {
    switch (environment) {
      case 'Home':
        return Icons.home;
      case 'School':
        return Icons.school;
      case 'Both':
        return Icons.sync;
      default:
        return Icons.location_on;
    }
  }

  String _translateDifficultyToIndonesian(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return 'Mudah';
      case 'Medium':
        return 'Sedang';
      case 'Hard':
        return 'Sulit';
      default:
        return difficulty;
    }
  }

  String _translateEnvironmentToIndonesian(String environment) {
    switch (environment) {
      case 'Home':
        return 'Rumah';
      case 'School':
        return 'Sekolah';
      case 'Both':
        return 'Keduanya';
      default:
        return environment;
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
          content: Text('Aktivitas berhasil ditetapkan'),
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
}
