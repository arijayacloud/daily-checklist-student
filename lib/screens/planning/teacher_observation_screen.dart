import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '/laravel_api/models/observation_model.dart';
import '/laravel_api/models/planning_model.dart';
import '/laravel_api/models/child_model.dart';
import '/laravel_api/providers/observation_provider.dart';
import '/laravel_api/providers/planning_provider.dart';
import '/laravel_api/providers/child_provider.dart';
import '/laravel_api/providers/user_provider.dart';
import '/lib/theme/app_theme.dart';

class TeacherObservationScreen extends StatefulWidget {
  final int planId;
  final String planTitle;

  const TeacherObservationScreen({
    Key? key,
    required this.planId,
    required this.planTitle,
  }) : super(key: key);

  @override
  State<TeacherObservationScreen> createState() => _TeacherObservationScreenState();
}

class _TeacherObservationScreenState extends State<TeacherObservationScreen> {
  bool _showObservations = true;
  bool _showChildren = false;
  bool _showChildProgress = true;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _isInitialized = false;
  final Set<String> _expandedObservations = {};
  String? _selectedChildId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }
  
  void _loadInitialData() {
    Future.microtask(() {
      final childProvider = Provider.of<ChildProvider>(context, listen: false);
      if (childProvider.children.isEmpty) {
        childProvider.fetchChildren();
      }
      
      final observationProvider = Provider.of<ObservationProvider>(context, listen: false);
      observationProvider.fetchObservationsForPlan(widget.planId.toString());
    });
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Observasi - ${widget.planTitle}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () {
                final observationProvider = Provider.of<ObservationProvider>(context, listen: false);
                
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(
                    content: Text('Memuat ulang data observasi...'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                
                observationProvider.fetchObservationsForPlan(widget.planId.toString()).then((_) {
                  _scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(
                      content: Text('Data berhasil diperbarui'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                    ),
                  );
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Tambah Observasi',
              onPressed: () => _showAddObservationDialog(context),
            ),
          ],
        ),
        body: Consumer3<ObservationProvider, PlanningProvider, ChildProvider>(
          builder: (context, observationProvider, planningProvider, childProvider, _) {
            // Get plan details
            final plan = planningProvider.plans.firstWhere(
              (p) => p.id == widget.planId, 
              orElse: () => Planning(
                id: 0,
                type: 'daily',
                teacherId: '0',
                childId: null,
                startDate: DateTime.now(),
                activities: [],
              )
            );

            if (plan.id == 0) {
              return const Center(
                child: Text('Data perencanaan tidak ditemukan'),
              );
            }

            // Get children names
            List<ChildModel> selectedChildren = [];
            if (plan.childIds.isNotEmpty) {
              selectedChildren = childProvider.children
                  .where((child) => plan.childIds.contains(child.id))
                  .toList();
            }
            
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPlanHeader(plan, selectedChildren),
                      const SizedBox(height: 16),
                      _buildObservationsSection(observationProvider, selectedChildren),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlanHeader(Planning plan, List<ChildModel> children) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    plan.type == 'daily' ? 'Harian' : 'Mingguan',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.person, size: 16, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    if (plan.teacherId != '0') {
                      final teacherName = userProvider.getTeacherNameById(plan.teacherId);
                      if (teacherName == null) {
                        Future.microtask(() => userProvider.getUserById(plan.teacherId));
                        return const Text('Memuat...', style: TextStyle(fontSize: 14, color: Colors.grey));
                      }
                      return Text(
                        'Dibuat oleh $teacherName',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      );
                    }
                    return Text(
                      'Dibuat oleh Guru',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Periode Perencanaan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            if (plan.type == 'daily')
              _buildDateRow(plan.startDate)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateRow(plan.startDate, label: 'Mulai:'),
                  const SizedBox(height: 4),
                  _buildDateRow(
                    plan.startDate.add(const Duration(days: 6)),
                    label: 'Selesai:'
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${plan.activities.length} aktivitas dijadwalkan',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${children.length} anak terlibat',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Divider(height: 24),
            if (children.isNotEmpty) ...[
              Text(
                'Anak yang Terlibat',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: children.map((child) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: AppTheme.primaryContainer,
                      child: Text(
                        child.name.substring(0, 1),
                        style: TextStyle(
                          color: AppTheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    label: Text(child.name),
                    backgroundColor: AppTheme.surfaceVariant.withOpacity(0.3),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow(DateTime date, {String? label}) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 20,
          color: AppTheme.primary,
        ),
        const SizedBox(width: 8),
        if (label != null) 
          Text(
            label,
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        if (label != null) const SizedBox(width: 4),
        Text(
          DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

    Widget _buildObservationsSection(ObservationProvider observationProvider, List<ChildModel> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showObservations = !_showObservations;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Observasi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${observationProvider.observations.length} observasi tercatat',
                          style: TextStyle(color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showObservations ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_showObservations) const Divider(height: 1),
          if (_showObservations)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (observationProvider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (observationProvider.observations.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.psychology_outlined,
                              size: 64,
                              color: AppTheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada observasi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tambahkan observasi untuk melacak perkembangan anak',
                              style: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showAddObservationDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Observasi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...observationProvider.observations.map((observation) {
                      return _buildObservationCard(observation, children);
                    }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

    Widget _buildObservationCard(ObservationModel observation, List<ChildModel> children) {
    final String observationKey = 'observation_${observation.id}';
    bool isExpanded = _expandedObservations.contains(observationKey);
    
    // Find child name
    final child = children.firstWhere(
      (c) => c.id == observation.childId,
      orElse: () => ChildModel(
        id: observation.childId,
        name: 'Anak',
        age: 0,
        parentId: '',
        teacherId: '',
      ),
    );
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Observation header with expand/collapse
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedObservations.remove(observationKey);
                } else {
                  _expandedObservations.add(observationKey);
                }
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryContainer,
                        radius: 16,
                        child: Text(
                          child.name.substring(0, 1),
                          style: TextStyle(
                            color: AppTheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(observation.observationDate),
                              style: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Collapsible observation details
          if (isExpanded) ...[
            const Divider(height: 1),
            _buildObservationDetails(observation, child),
          ],
        ],
      ),
    );
  }

  Widget _buildObservationDetails(ObservationModel observation, ChildModel child) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (observation.observationResult != null && observation.observationResult!.isNotEmpty) ...[
            const Text(
              'Hasil Observasi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                observation.observationResult!,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          const Text(
            'Kesimpulan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          _buildConclusionItem(
            'Presentasi Ulang',
            observation.presentasiUlang,
            Icons.replay,
          ),
          _buildConclusionItem(
            'Extension',
            observation.extension,
            Icons.expand_more,
          ),
          _buildConclusionItem(
            'Bahasa',
            observation.bahasa,
            Icons.language,
          ),
          _buildConclusionItem(
            'Presentasi Langsung',
            observation.presentasiLangsung,
            Icons.present_to_all,
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditObservationDialog(context, observation),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDeleteConfirmation(context, observation),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Hapus'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConclusionItem(String title, bool value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: value ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: value ? Colors.green.shade700 : Colors.grey.shade600,
                fontWeight: value ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: value ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  Color _getCompletionColor(double percentage) {
    if (percentage < 30) {
      return Colors.red;
    } else if (percentage < 70) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

    void _showAddObservationDialog(BuildContext context) {
    final observationProvider = Provider.of<ObservationProvider>(context, listen: false);
    final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    
    final plan = planningProvider.plans.firstWhere(
      (p) => p.id == widget.planId,
      orElse: () => Planning(
        id: 0,
        type: 'daily',
        teacherId: '0',
        childId: null,
        startDate: DateTime.now(),
        activities: [],
      )
    );
    
    List<ChildModel> children = [];
    if (plan.childIds.isNotEmpty) {
      children = childProvider.children
          .where((child) => plan.childIds.contains(child.id))
          .toList();
    }
    
    if (children.isEmpty) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Tidak ada anak yang dipilih dalam perencanaan ini'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    String? selectedChildId = children.first.id;
    DateTime selectedDate = DateTime.now();
    final observationResultController = TextEditingController();
    Map<String, bool> conclusions = {
      'presentasi_ulang': false,
      'extension': false,
      'bahasa': false,
      'presentasi_langsung': false,
    };
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Tambah Observasi'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Child selection
                    DropdownButtonFormField<String>(
                      value: selectedChildId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Anak',
                        border: OutlineInputBorder(),
                      ),
                      items: children.map((child) {
                        return DropdownMenuItem(
                          value: child.id,
                          child: Text(child.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedChildId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Date selection
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Observasi',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(selectedDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Observation result
                    TextField(
                      controller: observationResultController,
                      decoration: const InputDecoration(
                        labelText: 'Hasil Observasi (Opsional)',
                        border: OutlineInputBorder(),
                        hintText: 'Catatan hasil observasi...',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Conclusions
                    const Text(
                      'Kesimpulan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    _buildConclusionCheckbox(
                      'Presentasi Ulang',
                      conclusions['presentasi_ulang']!,
                      (value) {
                        setState(() {
                          conclusions['presentasi_ulang'] = value;
                        });
                      },
                    ),
                    _buildConclusionCheckbox(
                      'Extension',
                      conclusions['extension']!,
                      (value) {
                        setState(() {
                          conclusions['extension'] = value;
                        });
                      },
                    ),
                    _buildConclusionCheckbox(
                      'Bahasa',
                      conclusions['bahasa']!,
                      (value) {
                        setState(() {
                          conclusions['bahasa'] = value;
                        });
                      },
                    ),
                    _buildConclusionCheckbox(
                      'Presentasi Langsung',
                      conclusions['presentasi_langsung']!,
                      (value) {
                        setState(() {
                          conclusions['presentasi_langsung'] = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedChildId == null) {
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(
                          content: Text('Pilih anak terlebih dahulu'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    Navigator.of(context).pop();
                    
                    final success = await observationProvider.createObservation(
                      planId: widget.planId.toString(),
                      childId: selectedChildId!,
                      observationDate: selectedDate,
                      observationResult: observationResultController.text.isNotEmpty 
                          ? observationResultController.text 
                          : null,
                      conclusions: conclusions,
                    );
                    
                    if (success != null) {
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(
                          content: Text('Observasi berhasil ditambahkan'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text('Gagal menambahkan observasi: ${observationProvider.error}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildConclusionCheckbox(String title, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      onChanged: (newValue) => onChanged(newValue ?? false),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showEditObservationDialog(BuildContext context, ObservationModel observation) {
    // Similar to add dialog but with pre-filled values
    // Implementation would be similar to _showAddObservationDialog
    // but with existing observation data
  }

  void _showDeleteConfirmation(BuildContext context, ObservationModel observation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Observasi'),
          content: const Text('Apakah Anda yakin ingin menghapus observasi ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                final observationProvider = Provider.of<ObservationProvider>(context, listen: false);
                final success = await observationProvider.deleteObservation(
                  widget.planId.toString(),
                  observation.id,
                );
                
                if (success) {
                  _scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(
                      content: Text('Observasi berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  _scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus observasi: ${observationProvider.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}