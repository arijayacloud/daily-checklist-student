import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/activity_model.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/teacher/activity_form_screen.dart';
import '../../screens/teacher/assign_activity_screen.dart';
import '../../core/theme/app_colors_compat.dart';

class TeacherActivityDetailScreen extends StatefulWidget {
  final ActivityModel activity;

  const TeacherActivityDetailScreen({super.key, required this.activity});

  @override
  State<TeacherActivityDetailScreen> createState() =>
      _TeacherActivityDetailScreenState();
}

class _TeacherActivityDetailScreenState
    extends State<TeacherActivityDetailScreen> {
  ActivityModel? _nextActivity;
  bool _isLoadingNextActivity = false;
  String _errorMessage = '';
  final TextEditingController _customStepController = TextEditingController();
  final List<String> _customSteps = [];

  @override
  void initState() {
    super.initState();
    _loadNextActivity();
    _loadCustomSteps();
  }

  @override
  void dispose() {
    _customStepController.dispose();
    super.dispose();
  }

  Future<void> _loadNextActivity() async {
    if (widget.activity.nextActivityId == null) {
      return;
    }

    setState(() {
      _isLoadingNextActivity = true;
      _errorMessage = '';
    });

    try {
      final activityProvider = Provider.of<ActivityProvider>(
        context,
        listen: false,
      );
      final nextActivity = await activityProvider.getFollowUpActivity(
        widget.activity.id,
      );

      setState(() {
        _nextActivity = nextActivity;
        _isLoadingNextActivity = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat aktivitas lanjutan: $e';
        _isLoadingNextActivity = false;
      });
    }
  }

  void _loadCustomSteps() {
    // Dapatkan custom steps untuk guru ini
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel != null) {
      final teacherId = authProvider.userModel!.id;
      final customStep = widget.activity.customSteps.firstWhere(
        (step) => step.teacherId == teacherId,
        orElse: () => CustomStep(teacherId: teacherId, steps: []),
      );

      setState(() {
        _customSteps.clear();
        _customSteps.addAll(customStep.steps);
      });
    }
  }

  Future<void> _saveCustomSteps() async {
    if (_customSteps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan tambahkan minimal satu langkah')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );

    if (authProvider.userModel != null) {
      final teacherId = authProvider.userModel!.id;
      final success = await activityProvider.addCustomSteps(
        widget.activity.id,
        teacherId,
        _customSteps,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Langkah-langkah kustom berhasil disimpan'),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              activityProvider.errorMessage.isNotEmpty
                  ? activityProvider.errorMessage
                  : 'Gagal menyimpan langkah-langkah kustom',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addCustomStep() {
    final step = _customStepController.text.trim();
    if (step.isNotEmpty) {
      setState(() {
        _customSteps.add(step);
        _customStepController.clear();
      });
    }
  }

  void _removeCustomStep(int index) {
    setState(() {
      _customSteps.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Aktivitas'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ActivityFormScreen(activity: widget.activity),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.assignment_ind),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => AssignActivityScreen(activity: widget.activity),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Informasi Aktivitas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.activity.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Deskripsi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.activity.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildInfoItem(
                          'Lingkungan',
                          _getEnvironmentLabel(widget.activity.environment),
                          Icons.location_on,
                        ),
                        const SizedBox(width: 16),
                        _buildInfoItem(
                          'Kesulitan',
                          _getDifficultyLabel(widget.activity.difficulty),
                          Icons.star,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      'Rentang Usia',
                      '${widget.activity.ageRange.min}-${widget.activity.ageRange.max} tahun',
                      Icons.child_care,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Aktivitas Lanjutan
            if (widget.activity.nextActivityId != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aktivitas Lanjutan',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingNextActivity)
                        const Center(child: CircularProgressIndicator())
                      else if (_errorMessage.isNotEmpty)
                        Text(_errorMessage, style: TextStyle(color: Colors.red))
                      else if (_nextActivity != null)
                        ListTile(
                          title: Text(_nextActivity!.title),
                          subtitle: Text(
                            _nextActivity!.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => TeacherActivityDetailScreen(
                                      activity: _nextActivity!,
                                    ),
                              ),
                            );
                          },
                        )
                      else
                        const Text('Aktivitas lanjutan tidak ditemukan'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Custom Steps
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Langkah-langkah Kustom',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Daftar langkah kustom
                    if (_customSteps.isEmpty)
                      const Text(
                        'Belum ada langkah kustom. Tambahkan langkah pertama.',
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _customSteps.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(_customSteps[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeCustomStep(index),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 16),

                    // Input langkah baru
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customStepController,
                            decoration: const InputDecoration(
                              hintText: 'Tambah langkah baru',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addCustomStep,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Tombol simpan
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveCustomSteps,
                        child: const Text('Simpan Langkah-langkah Kustom'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  String _getEnvironmentLabel(String environment) {
    switch (environment) {
      case 'home':
        return 'Rumah';
      case 'school':
        return 'Sekolah';
      case 'both':
        return 'Keduanya';
      default:
        return 'Tidak Diketahui';
    }
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'Mudah';
      case 'medium':
        return 'Sedang';
      case 'hard':
        return 'Sulit';
      default:
        try {
          final stars = int.parse(difficulty);
          if (stars <= 2) {
            return 'Mudah';
          } else if (stars <= 4) {
            return 'Sedang';
          } else {
            return 'Sulit';
          }
        } catch (e) {
          return 'Tidak Diketahui';
        }
    }
  }
}
