import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/activity_model.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors_compat.dart';

class ActivityFormScreen extends StatefulWidget {
  final ActivityModel? activity;

  const ActivityFormScreen({super.key, this.activity});

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _environment;
  late String _difficulty;
  late RangeValues _ageRange;
  String? _nextActivityId;
  bool _isLoadingActivities = false;
  List<ActivityModel> _availableActivities = [];

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    _isEditing = widget.activity != null;

    _titleController = TextEditingController(text: widget.activity?.title);
    _descriptionController = TextEditingController(
      text: widget.activity?.description,
    );
    _environment = widget.activity?.environment ?? 'both';
    _difficulty = widget.activity?.difficulty ?? '3';
    _ageRange =
        widget.activity != null
            ? RangeValues(
              widget.activity!.ageRange.min.toDouble(),
              widget.activity!.ageRange.max.toDouble(),
            )
            : const RangeValues(3, 6);
    _nextActivityId = widget.activity?.nextActivityId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailableActivities();
    });
  }

  Future<void> _loadAvailableActivities() async {
    if (_isEditing) {
      setState(() {
        _isLoadingActivities = true;
      });

      final activityProvider = Provider.of<ActivityProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.userModel != null) {
        activityProvider.loadActivities(
          authProvider.userModel!.id,
          showAllActivities: true,
        );

        await Future.delayed(const Duration(milliseconds: 500));

        setState(() {
          // Filter out the current activity to avoid circular references
          _availableActivities =
              activityProvider.activities
                  .where((activity) => activity.id != widget.activity?.id)
                  .toList();
          _isLoadingActivities = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveActivity() async {
    if (_formKey.currentState?.validate() ?? false) {
      final activityProvider = Provider.of<ActivityProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (_isEditing && widget.activity != null) {
        final updatedActivity = widget.activity!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          environment: _environment,
          difficulty: _difficulty,
          ageRange: AgeRange(
            min: _ageRange.start.toInt(),
            max: _ageRange.end.toInt(),
          ),
          nextActivityId: _nextActivityId,
        );

        final success = await activityProvider.updateActivity(updatedActivity);

        if (success && mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aktivitas berhasil diperbarui')),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                activityProvider.errorMessage.isNotEmpty
                    ? activityProvider.errorMessage
                    : 'Gagal memperbarui aktivitas',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } else {
        final success = await activityProvider.addActivity(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          environment: _environment,
          teacherId: authProvider.userModel!.id,
          difficulty: _difficulty,
          ageRange: AgeRange(
            min: _ageRange.start.toInt(),
            max: _ageRange.end.toInt(),
          ),
          nextActivityId: _nextActivityId,
        );

        if (success && mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aktivitas berhasil dibuat')),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                activityProvider.errorMessage.isNotEmpty
                    ? activityProvider.errorMessage
                    : 'Gagal membuat aktivitas',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityProvider = Provider.of<ActivityProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Aktivitas' : 'Buat Aktivitas'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Aktivitas',
                  hintText: 'Masukkan judul deskriptif',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Silakan masukkan judul';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Aktivitas',
                  hintText: 'Masukkan instruksi detail',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Silakan masukkan deskripsi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Environment selection
              Text(
                'Dimana aktivitas ini dapat diselesaikan?',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 8),

              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'home',
                    label: Text('Rumah'),
                    icon: Icon(Icons.home),
                  ),
                  ButtonSegment(
                    value: 'school',
                    label: Text('Sekolah'),
                    icon: Icon(Icons.school),
                  ),
                  ButtonSegment(
                    value: 'both',
                    label: Text('Keduanya'),
                    icon: Icon(Icons.compare_arrows),
                  ),
                ],
                selected: {_environment},
                onSelectionChanged: (Set<String> selection) {
                  setState(() {
                    _environment = selection.first;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Difficulty selection
              Text(
                'Tingkat Kesulitan',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Mudah'),
                  Expanded(
                    child: Slider(
                      value: double.parse(_difficulty),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _difficulty,
                      onChanged: (value) {
                        setState(() {
                          _difficulty = value.toInt().toString();
                        });
                      },
                    ),
                  ),
                  const Text('Sulit'),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Icon(
                    index < int.parse(_difficulty)
                        ? Icons.star
                        : Icons.star_border,
                    color:
                        index < int.parse(_difficulty)
                            ? Colors.amber
                            : Colors.grey.shade400,
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Age Range selection
              Text(
                'Rentang Usia',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_ageRange.start.toInt()} tahun'),
                  Expanded(
                    child: RangeSlider(
                      values: _ageRange,
                      min: 3,
                      max: 6,
                      divisions: 3,
                      labels: RangeLabels(
                        '${_ageRange.start.toInt()} tahun',
                        '${_ageRange.end.toInt()} tahun',
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _ageRange = values;
                        });
                      },
                    ),
                  ),
                  Text('${_ageRange.end.toInt()} tahun'),
                ],
              ),

              const SizedBox(height: 24),

              // Next Activity selection (only shown for editing)
              if (_isEditing) ...[
                Text(
                  'Aktivitas Lanjutan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                const SizedBox(height: 8),

                if (_isLoadingActivities)
                  const Center(child: CircularProgressIndicator())
                else
                  DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      labelText: 'Pilih Aktivitas Lanjutan (Opsional)',
                      hintText: 'Pilih aktivitas yang mengikuti ini',
                    ),
                    value: _nextActivityId,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Tidak Ada'),
                      ),
                      ..._availableActivities.map((activity) {
                        return DropdownMenuItem<String?>(
                          value: activity.id,
                          child: Text(
                            activity.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        _nextActivityId = value;
                      });
                    },
                  ),

                const SizedBox(height: 16),
              ],

              // Save button
              ElevatedButton(
                onPressed: activityProvider.isLoading ? null : _saveActivity,
                child:
                    activityProvider.isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          _isEditing ? 'Perbarui Aktivitas' : 'Buat Aktivitas',
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
