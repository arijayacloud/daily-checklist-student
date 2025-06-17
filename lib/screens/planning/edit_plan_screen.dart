import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '/laravel_api/models/planning_model.dart';
import '/laravel_api/models/activity_model.dart';
import '/laravel_api/models/child_model.dart';
import '/laravel_api/providers/planning_provider.dart';
import '/laravel_api/providers/child_provider.dart';
import '/laravel_api/providers/activity_provider.dart';
import '/lib/theme/app_theme.dart';
import '/screens/planning/planning_detail_screen.dart';

class EditPlanScreen extends StatefulWidget {
  final Planning plan;

  const EditPlanScreen({
    Key? key,
    required this.plan,
  }) : super(key: key);

  @override
  State<EditPlanScreen> createState() => _EditPlanScreenState();
}

class _EditPlanScreenState extends State<EditPlanScreen> {
  late DateTime _startDate;
  String _planType = 'daily';
  List<String> _selectedChildIds = [];
  List<PlannedActivity> _activities = [];
  List<int> _removedActivityIds = [];
  bool _isLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with existing plan data
    _startDate = widget.plan.startDate;
    _planType = widget.plan.type;
    _selectedChildIds = List<String>.from(widget.plan.childIds);
    _activities = List<PlannedActivity>.from(widget.plan.activities);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Edit Rencana'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePlan,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeSelection(),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 24),
            _buildChildSelection(),
            const SizedBox(height: 24),
            _buildActivitiesSection(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTypeSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jenis Perencanaan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeOption(
                    'daily',
                    'Harian',
                    'Rencana aktivitas untuk satu hari',
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeOption(
                    'weekly',
                    'Mingguan',
                    'Rencana aktivitas untuk satu minggu',
                    Icons.date_range,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(
    String value, 
    String title, 
    String description,
    IconData icon,
  ) {
    final isSelected = _planType == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _planType = value;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryContainer : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primary : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppTheme.primary.withOpacity(0.7) : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDatePicker() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tanggal Mulai',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                
                if (picked != null && mounted) {
                  setState(() {
                    _startDate = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_startDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_planType == 'weekly')
                            Text(
                              'Sampai: ${DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_startDate.add(const Duration(days: 6)))}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChildSelection() {
    return Consumer<ChildProvider>(
      builder: (context, childProvider, child) {
        final children = childProvider.children;
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Anak',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Jika tidak ada anak yang dipilih, rencana akan berlaku untuk semua anak.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                if (childProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (children.isEmpty)
                  const Center(
                    child: Text('Tidak ada data anak'),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: children.length,
                    itemBuilder: (context, index) {
                      final child = children[index];
                      return CheckboxListTile(
                        title: Text(child.name),
                        subtitle: Text('${child.age} tahun'),
                        value: _selectedChildIds.contains(child.id),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              if (!_selectedChildIds.contains(child.id)) {
                                _selectedChildIds.add(child.id);
                              }
                            } else {
                              _selectedChildIds.removeWhere((id) => id == child.id);
                            }
                          });
                        },
                        activeColor: AppTheme.primary,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedChildIds.length == children.length) {
                        // If all children are selected, deselect all
                        _selectedChildIds.clear();
                      } else {
                        // Otherwise select all
                        _selectedChildIds = children.map((c) => c.id).toList();
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceVariant,
                    foregroundColor: AppTheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _selectedChildIds.length == children.length
                        ? 'Batalkan Semua Pilihan'
                        : 'Pilih Semua Anak',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildActivitiesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aktivitas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kelola aktivitas dalam rencana ini',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            // Tampilkan list aktivitas yang dapat diedit
            Consumer<ActivityProvider>(
              builder: (context, activityProvider, _) {
                if (_activities.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text('Belum ada aktivitas dalam rencana ini'),
                    ),
                  );
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _activities.length,
                  itemBuilder: (context, index) {
                    final activity = _activities[index];
                    final activityDetail = activityProvider.getActivityById(activity.activityId.toString());
                    
                    if (activityDetail == null) {
                      return const ListTile(
                        title: Text('Aktivitas tidak ditemukan'),
                      );
                    }
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activityDetail.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('d MMM yyyy', 'id_ID').format(activity.scheduledDate),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  if (activity.scheduledTime != null)
                                    Text(
                                      'Waktu: ${activity.scheduledTime}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                // Edit button
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _editActivityTime(index),
                                ),
                                const SizedBox(width: 8),
                                // Remove button
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _removeActivity(index),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Tambah aktivitas baru
            OutlinedButton.icon(
              onPressed: () => _showAddActivityDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Aktivitas'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tombol untuk melihat detail
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlanningDetailScreen(
                      planId: widget.plan.id,
                      activities: _activities.where((activity) => 
                          !_removedActivityIds.contains(activity.id)).toList(),
                      selectedDate: _startDate,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Lihat Detail Aktivitas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Dialog untuk mengedit waktu aktivitas
  void _editActivityTime(int index) {
    final activity = _activities[index];
    TimeOfDay? initialTime;
    
    if (activity.scheduledTime != null) {
      final parts = activity.scheduledTime!.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          initialTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }
    
    showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    ).then((time) {
      if (time != null && mounted) {
        setState(() {
          _activities[index] = PlannedActivity(
            id: activity.id,
            planId: activity.planId,
            activityId: activity.activityId,
            scheduledDate: activity.scheduledDate, 
            scheduledTime: '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            reminder: activity.reminder,
            completed: activity.completed,
          );
        });
      }
    });
  }
  
  // Hapus aktivitas
  void _removeActivity(int index) {
    final activity = _activities[index];
    
    // Jika aktivitas belum punya ID, berarti belum disimpan ke server
    if (activity.id != null) {
      _removedActivityIds.add(activity.id!);
    }
    
    setState(() {
      _activities.removeAt(index);
    });
  }
  
  // Dialog untuk menambahkan aktivitas baru
  void _showAddActivityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Aktivitas'),
        content: const Text(
          'Fitur tambah aktivitas akan datang segera. '
          'Silahkan gunakan halaman Detail Rencana untuk menambah aktivitas.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlanningDetailScreen(
                    planId: widget.plan.id,
                    activities: _activities.where((activity) => 
                        !_removedActivityIds.contains(activity.id)).toList(),
                    selectedDate: _startDate,
                  ),
                ),
              );
            },
            child: const Text('Ke Halaman Detail'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _savePlan() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
    
    try {
      // Persiapkan data aktivitas untuk dikirim
      List<PlannedActivity> activityUpdates = [];
      
      for (var activity in _activities) {
        if (!_removedActivityIds.contains(activity.id)) {
          activityUpdates.add(activity);
        }
      }
      
      final result = await planningProvider.updatePlan(
        planId: widget.plan.id,
        type: _planType,
        startDate: _startDate,
        childIds: _selectedChildIds.isNotEmpty ? _selectedChildIds : null,
        activities: activityUpdates.isEmpty ? null : activityUpdates,
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rencana berhasil diperbarui'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(planningProvider.error ?? 'Gagal memperbarui rencana'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 