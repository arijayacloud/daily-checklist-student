import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '/laravel_api/models/activity_model.dart';
import '/laravel_api/models/child_model.dart';
import '/laravel_api/models/planning_model.dart';
import '/laravel_api/providers/activity_provider.dart';
import '/laravel_api/providers/child_provider.dart';
import '/laravel_api/providers/planning_provider.dart';
import '/laravel_api/providers/checklist_provider.dart';
import '/lib/theme/app_theme.dart';

class AddPlanScreen extends StatefulWidget {
  final DateTime selectedDate;

  const AddPlanScreen({super.key, required this.selectedDate});

  @override
  State<AddPlanScreen> createState() => _AddPlanScreenState();
}

class _AddPlanScreenState extends State<AddPlanScreen> {
  final List<Map<String, dynamic>> _activities = [];
  String? _selectedChildId;
  bool _isSubmitting = false;
  String _planType = 'daily'; // 'daily' or 'weekly'
  DateTime _startDate = DateTime.now();
  String? _filterEnvironment;
  String? _filterDifficulty;
  RangeValues _ageFilter = const RangeValues(3, 6);
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Inisialisasi locale data untuk format tanggal bahasa Indonesia
    initializeDateFormatting('id_ID', null);

    _startDate = widget.selectedDate;

    // Jika tipe plan adalah weekly, pastikan tanggal mulainya adalah Senin
    if (_planType == 'weekly') {
      _startDate = _getWeekStartDate(_startDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _planType == 'daily'
              ? 'Tambah Rencana Harian'
              : 'Tambah Rencana Mingguan',
        ),
      ),
      body: Column(
        children: [
          _buildPlanTypeSelector(),
          Expanded(child: _buildFormContent()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildPlanTypeSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildPlanTypeOption('daily', 'Harian')),
          Expanded(child: _buildPlanTypeOption('weekly', 'Mingguan')),
        ],
      ),
    );
  }

  Widget _buildPlanTypeOption(String type, String label) {
    final isSelected = _planType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _planType = type;

          // Jika berganti ke weekly, pastikan tanggal mulainya adalah Senin
          if (type == 'weekly') {
            _startDate = _getWeekStartDate(_startDate);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      children: [
        _buildDateHeader(),
        _buildChildSelector(),
        Expanded(child: _buildActivityList()),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryContainer.withOpacity(0.3),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: AppTheme.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Perencanaan untuk:', style: TextStyle(fontSize: 14)),
              _planType == 'daily'
                  ? Text(
                    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_startDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat(
                          'EEEE, d MMMM yyyy',
                          'id_ID',
                        ).format(_startDate),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Hingga ${DateFormat('d MMMM yyyy', 'id_ID').format(_getEndDateOfWeek())}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
            ],
          ),
          const Spacer(),
          if (_planType == 'daily')
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (pickedDate != null) {
                  setState(() {
                    _startDate = pickedDate;
                  });
                }
              },
            )
          else if (_planType == 'weekly')
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    setState(() {
                      // Mundur 7 hari
                      _startDate = _startDate.subtract(const Duration(days: 7));
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 30),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      selectableDayPredicate: (day) {
                        // Hanya izinkan memilih hari Senin
                        return day.weekday == DateTime.monday;
                      },
                      helpText: 'Pilih Awal Minggu (Senin)',
                    );
                    if (pickedDate != null) {
                      setState(() {
                        // Menggunakan hari Senin terdekat sebagai awal minggu
                        _startDate = _getWeekStartDate(pickedDate);
                      });
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    setState(() {
                      // Maju 7 hari
                      _startDate = _startDate.add(const Duration(days: 7));
                    });
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Mendapatkan tanggal akhir minggu (Minggu)
  DateTime _getEndDateOfWeek() {
    // Jika _startDate adalah Senin (weekday = 1), maka end date adalah Minggu (weekday = 7)
    // yang berarti start + 6 hari
    return _startDate.add(const Duration(days: 6));
  }

  // Mendapatkan tanggal awal minggu (Senin) dari tanggal yang diberikan
  DateTime _getWeekStartDate(DateTime date) {
    // Jika date.weekday = 1 (Senin), kembalikan date
    // Jika date.weekday > 1, kembalikan date - (weekday - 1) hari
    final int daysToSubtract = date.weekday - 1;
    return date.subtract(Duration(days: daysToSubtract));
  }

  Widget _buildChildSelector() {
    return Consumer<ChildProvider>(
      builder: (context, childProvider, child) {
        if (childProvider.children.isEmpty) {
          return const SizedBox.shrink();
        }

        final children = childProvider.children;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Anak (Opsional):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedChildId,
                decoration: InputDecoration(
                  hintText: 'Semua Anak',
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
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Semua Anak'),
                  ),
                  ...children.map((child) {
                    return DropdownMenuItem<String>(
                      value: child.id,
                      child: Text('${child.name} (${child.age} tahun)'),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedChildId = value;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityList() {
    return _activities.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _activities.length,
          itemBuilder: (context, index) {
            return _buildActivityItem(index);
          },
        );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 80,
            color: AppTheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada aktivitas yang direncanakan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol + untuk menambahkan aktivitas ke rencana ini',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(int index) {
    final activityData = _activities[index];
    final activityId = activityData['activityId'] as String;
    final scheduledTime = activityData['scheduledTime'] as String?;
    final reminder = activityData['reminder'] as bool;
    final scheduledDay =
        activityData['scheduledDay'] as int?; // Hari dalam seminggu (0-6)

    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        final activity = activityProvider.getActivityById(activityId);

        if (activity == null) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_planType == 'weekly' && scheduledDay != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getDayName(scheduledDay),
                          style: TextStyle(
                            color: AppTheme.onSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (scheduledTime != null)
                      Container(
                        margin: EdgeInsets.only(
                          left:
                              _planType == 'weekly' && scheduledDay != null
                                  ? 8
                                  : 0,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          scheduledTime,
                          style: TextStyle(
                            color: AppTheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      color: AppTheme.primary,
                      onPressed: () => _editActivity(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      color: AppTheme.error,
                      onPressed: () {
                        setState(() {
                          _activities.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activity.description,
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(
                          activity.difficulty,
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _translateDifficultyToIndonesian(activity.difficulty),
                        style: TextStyle(
                          color: _getDifficultyColor(activity.difficulty),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getEnvironmentColor(
                          activity.environment,
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _translateEnvironmentToIndonesian(activity.environment),
                        style: TextStyle(
                          color: _getEnvironmentColor(activity.environment),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      scheduledTime ?? 'Tidak ada waktu spesifik',
                      style: TextStyle(color: AppTheme.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Switch(
                      value: reminder,
                      onChanged: (value) {
                        setState(() {
                          _activities[index]['reminder'] = value;
                        });
                      },
                      activeColor: AppTheme.primary,
                    ),
                    Text(
                      'Pengingat',
                      style: TextStyle(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _addActivity,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Aktivitas'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppTheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 0),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _activities.isEmpty || _isSubmitting ? null : _savePlan,
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
                  'Simpan Rencana',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }

  void _addActivity() async {
    final selectedActivity = await showDialog<String>(
      context: context,
      builder: (context) => const ActivitySelectorDialog(),
    );

    if (selectedActivity != null) {
      if (_planType == 'daily') {
        // Untuk plan harian, hanya perlu waktu
        final timeOfDay = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            );
          },
        );

        setState(() {
          _activities.add({
            'activityId': selectedActivity,
            'scheduledTime':
                timeOfDay != null
                    ? '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}'
                    : null,
            'reminder': true,
          });
        });
      } else {
        // Untuk plan mingguan, perlu pilih hari
        final selectedDay = await showDialog<int>(
          context: context,
          builder: (context) => DayPickerDialog(startDate: _startDate),
        );

        if (selectedDay != null) {
          // Setelah memilih hari, pilih waktu
          final timeOfDay = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
            builder: (BuildContext context, Widget? child) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(alwaysUse24HourFormat: true),
                child: child!,
              );
            },
          );

          setState(() {
            _activities.add({
              'activityId': selectedActivity,
              'scheduledDay': selectedDay,
              'scheduledTime':
                  timeOfDay != null
                      ? '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}'
                      : null,
              'reminder': true,
            });
          });
        }
      }
    }
  }

  void _editActivity(int index) async {
    final activityData = _activities[index];
    final scheduledTime = activityData['scheduledTime'] as String?;
    final scheduledDay = activityData['scheduledDay'] as int?;

    if (_planType == 'weekly' && scheduledDay != null) {
      // Edit hari untuk plan mingguan
      final newDay = await showDialog<int>(
        context: context,
        builder:
            (context) => DayPickerDialog(
              startDate: _startDate,
              initialDay: scheduledDay,
            ),
      );

      if (newDay != null) {
        setState(() {
          _activities[index]['scheduledDay'] = newDay;
        });
      }
    }

    // Edit waktu untuk semua tipe plan
    final timeOfDay = await showTimePicker(
      context: context,
      initialTime:
          scheduledTime != null
              ? TimeOfDay(
                hour: int.parse(scheduledTime.split(':')[0]),
                minute: int.parse(scheduledTime.split(':')[1]),
              )
              : TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (timeOfDay != null) {
      setState(() {
        _activities[index]['scheduledTime'] =
            '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _savePlan() async {
    if (_activities.isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      List<PlannedActivity> plannedActivities = [];

      if (_planType == 'daily') {
        // Untuk plan harian, semua aktivitas terjadwal pada tanggal yang sama
        plannedActivities =
            _activities.map((data) {
              return PlannedActivity(
                planId: 0, // This will be set by the server
                activityId: data['activityId'],
                scheduledDate: _startDate,
                scheduledTime: data['scheduledTime'],
                reminder: data['reminder'],
              );
            }).toList();
      } else {
        // Untuk plan mingguan, sesuaikan tanggal berdasarkan scheduledDay
        plannedActivities =
            _activities.map((data) {
              final int scheduledDay = data['scheduledDay'] as int? ?? 0;
              // Menghitung tanggal dari hari dalam seminggu
              // startDate adalah hari Senin (weekday = 1), jadi kita tambahkan selisih harinya
              // Contoh: Jika scheduledDay = 0 (Minggu), maka kita tambahkan 6 hari dari Senin
              // Jika scheduledDay = 1 (Senin), tambahkan 0 hari, dst
              final int daysToAdd = (scheduledDay == 0) ? 6 : scheduledDay - 1;
              final DateTime activityDate = _startDate.add(
                Duration(days: daysToAdd),
              );

              return PlannedActivity(
                planId: 0, // This will be set by the server
                activityId: data['activityId'],
                scheduledDate: activityDate,
                scheduledTime: data['scheduledTime'],
                reminder: data['reminder'],
              );
            }).toList();
      }

      // Simpan rencana
      final Planning? plan = await Provider.of<PlanningProvider>(
        context,
        listen: false,
      ).createPlan(
        startDate: _startDate,
        childId: _selectedChildId,
        activities: plannedActivities,
        type: _planType,
      );

      // Jika ada childId yang dipilih, tanyakan apakah ingin langsung menambahkan ke checklist
      if (_selectedChildId != null && plan != null) {
        await _confirmAddToChecklist(plan.id.toString(), plannedActivities);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rencana berhasil dibuat'),
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

  Future<void> _confirmAddToChecklist(
    String planId,
    List<PlannedActivity> activities,
  ) async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambahkan ke Checklist'),
          content: const Text(
            'Apakah Anda ingin langsung menambahkan aktivitas-aktivitas ini ke checklist anak?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('TIDAK'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('YA'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _addActivitiesToChecklist(activities);
    }
  }

  Future<void> _addActivitiesToChecklist(
    List<PlannedActivity> activities,
  ) async {
    if (_selectedChildId == null) return;

    final checklistProvider = Provider.of<ChecklistProvider>(
      context,
      listen: false,
    );

    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );

    try {
      // Tambahkan setiap aktivitas ke checklist
      for (final activity in activities) {
        final activityModel = activityProvider.getActivityById(
          activity.activityId.toString(),
        );
        if (activityModel == null) continue;

        // Use activitySteps instead of customSteps
        List<String> steps = [];
        if (activityModel.activitySteps.isNotEmpty) {
          steps = activityModel.activitySteps.first.steps;
        }

        await checklistProvider.assignActivity(
          childId: _selectedChildId!,
          activityId: activity.activityId.toString(),
          scheduledDate: activity.scheduledDate,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktivitas berhasil ditambahkan ke checklist'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error menambahkan ke checklist: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
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

  String _getDayName(int day) {
    final List<String> dayNames = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    return dayNames[day % 7];
  }
}

class ActivitySelectorDialog extends StatefulWidget {
  const ActivitySelectorDialog({super.key});

  @override
  State<ActivitySelectorDialog> createState() => _ActivitySelectorDialogState();
}

class _ActivitySelectorDialogState extends State<ActivitySelectorDialog> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ActivityModel> _getFilteredActivities(List<ActivityModel> activities) {
    if (_searchQuery.isEmpty) {
      return activities;
    }

    final query = _searchQuery.toLowerCase();
    return activities.where((activity) {
      return activity.title.toLowerCase().contains(query) ||
          activity.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          children: [
            const Text(
              'Pilih Aktivitas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari aktivitas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                filled: true,
                fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<ActivityProvider>(
                builder: (context, activityProvider, child) {
                  if (activityProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (activityProvider.activities.isEmpty) {
                    return Center(
                      child: Text(
                        'Tidak ada aktivitas ditemukan',
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                    );
                  }

                  final filteredActivities = _getFilteredActivities(
                    activityProvider.activities,
                  );

                  if (filteredActivities.isEmpty) {
                    return Center(
                      child: Text(
                        'Tidak ada aktivitas yang cocok',
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredActivities.length,
                    itemBuilder: (context, index) {
                      final activity = filteredActivities[index];

                      return ListTile(
                        title: Text(
                          activity.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          activity.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.assignment,
                            color: AppTheme.primary,
                          ),
                        ),
                        trailing: Text(
                          '${activity.minAge}-${activity.maxAge} thn',
                          style: TextStyle(color: AppTheme.onSurfaceVariant),
                        ),
                        onTap: () {
                          Navigator.of(context).pop(activity.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.primary),
                ),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}

class DayPickerDialog extends StatefulWidget {
  final DateTime startDate;
  final int? initialDay;

  const DayPickerDialog({super.key, required this.startDate, this.initialDay});

  @override
  State<DayPickerDialog> createState() => _DayPickerDialogState();
}

class _DayPickerDialogState extends State<DayPickerDialog> {
  int _selectedDay = 0;

  @override
  void initState() {
    super.initState();
    // Jika ada initialDay, gunakan itu, jika tidak, gunakan hari dari startDate
    _selectedDay = widget.initialDay ?? widget.startDate.weekday % 7;
  }

  String _getDayName(int day) {
    final List<String> dayNames = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    return dayNames[day % 7];
  }

  DateTime _getDateForDay(int day) {
    // Hitung tanggal berdasarkan hari dalam seminggu
    final startWeekday = widget.startDate.weekday % 7;
    return widget.startDate.add(Duration(days: (day - startWeekday + 7) % 7));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Hari',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(7, (index) {
              final day = index;
              final date = _getDateForDay(day);
              final isSelected = _selectedDay == day;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDay = day;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppTheme.primaryContainer
                            : AppTheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getDayName(day),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected
                                  ? AppTheme.onPrimaryContainer
                                  : AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('d MMM', 'id_ID').format(date),
                        style: TextStyle(
                          color:
                              isSelected
                                  ? AppTheme.onPrimaryContainer
                                  : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('BATAL'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedDay),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('PILIH'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
