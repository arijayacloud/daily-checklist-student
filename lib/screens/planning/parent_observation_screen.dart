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
import '/laravel_api/providers/auth_provider.dart';
import '/lib/theme/app_theme.dart';

class ParentObservationScreen extends StatefulWidget {
  final String planId;
  final String planTitle;
  final String? childId; // Add childId parameter for parent view

  const ParentObservationScreen({
    Key? key,
    required this.planId,
    required this.planTitle,
    this.childId,
  }) : super(key: key);

  @override
  State<ParentObservationScreen> createState() => _ParentObservationScreenState();
}

class _ParentObservationScreenState extends State<ParentObservationScreen> {
  bool _showObservations = true;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final Set<String> _expandedObservations = {};

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
      observationProvider.fetchObservationsForPlan(widget.planId);
    });
  }
  
  @override
  void dispose() {
    super.dispose();
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
                
                observationProvider.fetchObservationsForPlan(widget.planId).then((_) {
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
          ],
        ),
        body: Consumer4<ObservationProvider, PlanningProvider, ChildProvider, AuthProvider>(
          builder: (context, observationProvider, planningProvider, childProvider, authProvider, _) {
            // Get plan details
            final planId = int.tryParse(widget.planId);
            if (planId == null) {
              return const Center(
                child: Text('ID perencanaan tidak valid'),
              );
            }
            
            final plan = planningProvider.plans.firstWhere(
              (p) => p.id == planId, 
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

            // Get children - for parents, only show their own children
            List<ChildModel> selectedChildren = [];
            if (plan.childIds.isNotEmpty) {
              // Filter children to only show the parent's children
              selectedChildren = childProvider.children
                  .where((child) => 
                      plan.childIds.contains(child.id) && 
                      child.parentId == authProvider.user?.id)
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
                  '${children.length} anak Anda terlibat',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Divider(height: 24),
            if (children.isNotEmpty) ...[
              Text(
                'Anak Anda yang Terlibat',
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
                              'Observasi akan muncul di sini setelah guru menambahkan observasi',
                              style: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...observationProvider.observations
                        .where((observation) => 
                            children.any((child) => child.id == observation.childId))
                        .map((observation) {
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
            'Presentasi Lanjutan',
            observation.presentasiLangsung,
            Icons.present_to_all,
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
}
