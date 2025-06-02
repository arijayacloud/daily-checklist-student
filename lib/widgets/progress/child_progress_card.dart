import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/models/child_model.dart';
import '/models/checklist_item_model.dart';
import '/models/activity_model.dart';
import '/providers/activity_provider.dart';
import '/screens/progress/child_checklist_screen.dart';

class ChildProgressCard extends StatelessWidget {
  final ChildModel child;
  final List<ChecklistItemModel> checklistItems;
  final ActivityProvider activityProvider;

  const ChildProgressCard({
    Key? key,
    required this.child,
    required this.checklistItems,
    required this.activityProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Hitung statistik
    final totalItems = checklistItems.length;
    final completedItems =
        checklistItems.where((item) => item.isCompleted).length;
    final overdueItems = checklistItems.where((item) => item.isOverdue).length;

    // Hitung persentase penyelesaian
    final completionRate = totalItems > 0 ? completedItems / totalItems : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigasi ke detail checklist anak
          Navigator.of(
            context,
          ).pushNamed(ChildChecklistScreen.routeName, arguments: child.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan avatar dan info anak
              Row(
                children: [
                  // Avatar anak
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(child.getAvatarUrl()),
                    onBackgroundImageError: (_, __) {
                      // Fallback ke DiceBear jika gagal memuat avatar
                      Image.network(child.getDiceBearUrl());
                    },
                  ),
                  const SizedBox(width: 16),
                  // Info anak
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${child.age} tahun',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  _buildStatusBadge(context, completionRate),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: completionRate,
                  minHeight: 8,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
              ),

              const SizedBox(height: 8),

              // Statistik
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$completedItems dari $totalItems sudah selesai'),
                  if (overdueItems > 0)
                    Text(
                      '$overdueItems telat',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Daftar aktivitas terbaru
              if (checklistItems.isNotEmpty) ...[
                Text(
                  'Aktivitas Terbaru:',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                ...checklistItems
                    .take(3)
                    .map((item) => _buildActivityItem(context, item))
                    .toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, double completionRate) {
    String label;
    Color color;

    if (completionRate >= 1.0) {
      label = 'Tuntas';
      color = Colors.green;
    } else if (completionRate >= 0.7) {
      label = 'Hampir Selesai';
      color = Colors.blue;
    } else if (completionRate >= 0.3) {
      label = 'Setengah Jalan';
      color = Colors.orange;
    } else {
      label = 'Baru Dimulai';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, ChecklistItemModel item) {
    // Ambil data aktivitas
    final activity = activityProvider.getActivityById(item.activityId);
    final activityTitle = activity?.title ?? 'Aktivitas';

    // Format tanggal
    final dateFormat = DateFormat('dd MMM yyyy');
    final assignedDate = dateFormat.format(item.assignedDate.toDate());

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        _getStatusIcon(item),
        color: _getStatusColor(context, item),
      ),
      title: Text(activityTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('Ditugaskan: $assignedDate'),
      trailing: _buildStatusText(context, item),
    );
  }

  IconData _getStatusIcon(ChecklistItemModel item) {
    if (item.isCompleted) {
      return Icons.check_circle;
    }
    if (item.isOverdue) {
      return Icons.warning;
    }
    if (item.isInProgress) {
      return Icons.refresh;
    }
    return Icons.hourglass_empty;
  }

  Color _getStatusColor(BuildContext context, ChecklistItemModel item) {
    if (item.isCompleted) {
      return Colors.green;
    }
    if (item.isOverdue) {
      return Colors.orange;
    }
    if (item.isInProgress) {
      return Colors.blue;
    }
    return Colors.grey;
  }

  Widget _buildStatusText(BuildContext context, ChecklistItemModel item) {
    String text;
    Color color;

    if (item.isCompleted) {
      text = 'Selesai';
      color = Colors.green;
    } else if (item.isOverdue) {
      text = 'Terlambat';
      color = Theme.of(context).colorScheme.error;
    } else if (item.isInProgress) {
      text = 'Sedang Dikerjakan';
      color = Colors.blue;
    } else {
      text = 'Belum Dimulai';
      color = Colors.grey;
    }

    return Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }
}
