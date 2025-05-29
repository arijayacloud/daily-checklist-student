import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../models/activity_model.dart';
import '../../models/child_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/checklist_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/empty_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors_compat.dart';

class AssignActivityScreen extends StatefulWidget {
  final ActivityModel activity;

  const AssignActivityScreen({super.key, required this.activity});

  @override
  State<AssignActivityScreen> createState() => _AssignActivityScreenState();
}

class _AssignActivityScreenState extends State<AssignActivityScreen> {
  final Set<String> _selectedChildrenIds = {};
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _dueDate = DateTime.now().add(const Duration(days: 7));
    initializeDateFormatting('id_ID');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      childProvider.loadChildrenForTeacher(authProvider.userModel!.id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSnackbar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.complete : AppColors.error,
      ),
    );
  }

  Future<void> _assignActivity() async {
    if (_selectedChildrenIds.isEmpty) {
      _showSnackbar('Silakan pilih minimal satu siswa', false);
      return;
    }

    final checklistProvider = Provider.of<ChecklistProvider>(
      context,
      listen: false,
    );

    int successCount = 0;
    int errorCount = 0;

    for (final childId in _selectedChildrenIds) {
      try {
        await checklistProvider.createChecklistItem(
          childId: childId,
          activityId: widget.activity.id,
          dueDate: _dueDate,
        );
        successCount++;
      } catch (e) {
        errorCount++;
        print('Error assigning to child $childId: $e');
      }
    }

    if (context.mounted) {
      if (successCount > 0) {
        _showSnackbar(
          'Aktivitas berhasil ditugaskan ke $successCount siswa',
          true,
        );
        Navigator.pop(context);
      } else {
        _showSnackbar('Gagal menugaskan aktivitas', false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context);
    final checklistProvider = Provider.of<ChecklistProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Assign Activity'), centerTitle: false),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.activity.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.activity.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildEnvironmentChip(widget.activity.environment),
                      const SizedBox(width: 8),
                      _buildDifficultyIndicator(
                        int.parse(widget.activity.difficulty),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Due date selector
                  Text(
                    'Tenggat Waktu',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );

                      if (picked != null && picked != _dueDate) {
                        setState(() {
                          _dueDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat(
                              'EEEE, d MMMM yyyy',
                              'id_ID',
                            ).format(_dueDate),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Student selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pilih Siswa',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            if (_selectedChildrenIds.length ==
                                childProvider.children.length) {
                              _selectedChildrenIds.clear();
                            } else {
                              _selectedChildrenIds.clear();
                              _selectedChildrenIds.addAll(
                                childProvider.children.map((child) => child.id),
                              );
                            }
                          });
                        },
                        icon: Icon(
                          _selectedChildrenIds.length ==
                                  childProvider.children.length
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                        ),
                        label: Text(
                          _selectedChildrenIds.length ==
                                  childProvider.children.length
                              ? 'Batalkan Semua'
                              : 'Pilih Semua',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Student list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: Builder(
                  builder: (context) {
                    if (childProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (childProvider.errorMessage.isNotEmpty) {
                      return Center(
                        child: Text(
                          'Error: ${childProvider.errorMessage}',
                          style: TextStyle(color: AppColors.error),
                        ),
                      );
                    }

                    if (childProvider.children.isEmpty) {
                      return const EmptyState(
                        icon: Icons.child_care,
                        title: 'Tidak Ada Siswa',
                        message:
                            'Tambahkan siswa sebelum menugaskan aktivitas.',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: childProvider.children.length,
                      itemBuilder: (context, index) {
                        final child = childProvider.children[index];
                        final isSelected = _selectedChildrenIds.contains(
                          child.id,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedChildrenIds.add(child.id);
                                } else {
                                  _selectedChildrenIds.remove(child.id);
                                }
                              });
                            },
                            title: Text(
                              child.name,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('Usia: ${child.age}'),
                            secondary: ChildAvatar(
                              avatarUrl: child.avatarUrl,
                              radius: 20,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              '${_selectedChildrenIds.length} siswa terpilih',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: checklistProvider.isLoading ? null : _assignActivity,
              child:
                  checklistProvider.isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('Tugaskan Aktivitas'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentChip(String environment) {
    Color color;
    String label;

    switch (environment) {
      case 'home':
        color = AppColors.home;
        label = 'Rumah';
        break;
      case 'school':
        color = AppColors.school;
        label = 'Sekolah';
        break;
      case 'both':
        color = AppColors.both;
        label = 'Keduanya';
        break;
      default:
        color = Colors.grey;
        label = 'Tidak Diketahui';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }

  Widget _buildDifficultyIndicator(int difficulty) {
    return Row(
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < difficulty ? Icons.star : Icons.star_border,
            size: 14,
            color: index < difficulty ? Colors.amber : Colors.grey.shade400,
          );
        }),
      ],
    );
  }
}
