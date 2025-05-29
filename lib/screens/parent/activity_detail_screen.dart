import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/checklist_item_model.dart';
import '../../models/child_model.dart';
import '../../models/activity_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/checklist_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors_compat.dart';
import '../../widgets/completion_badge.dart';
import '../../widgets/completion_note_input.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

class ActivityDetailScreen extends StatelessWidget {
  final ChecklistItemModel checklistItem;
  final ChildModel child;

  const ActivityDetailScreen({
    super.key,
    required this.checklistItem,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final checklistProvider = Provider.of<ChecklistProvider>(context);

    // Get activity details from provider
    final ActivityModel? activity = checklistProvider
        .findActivityForChecklistItem(checklistItem.activityId);

    if (activity == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail Aktivitas'),
          centerTitle: false,
        ),
        body: const Center(child: Text('Aktivitas tidak ditemukan')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Aktivitas'), centerTitle: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Activity title
              Text(
                activity.title,
                style: Theme.of(context).textTheme.headlineLarge,
              ),

              const SizedBox(height: 8),

              // Due date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tenggat: ${DateFormat('d MMM yyyy').format(checklistItem.dueDate)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _getDueDateColor(
                        context,
                        checklistItem.dueDate,
                        checklistItem,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Activity description
              Text('Deskripsi', style: Theme.of(context).textTheme.titleLarge),

              const SizedBox(height: 8),

              Text(
                activity.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const SizedBox(height: 24),

              // Completion status
              Text(
                'Status Penyelesaian',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 16),

              // Home status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rumah',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppColors.home),
                          ),
                          CompletionBadge(
                            isCompleted: checklistItem.homeStatus.completed,
                            environment: 'Home',
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      if (checklistItem.homeStatus.completed) ...[
                        const Divider(),

                        // Completed time
                        if (checklistItem.homeStatus.completedAt != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Diselesaikan ${timeago.format(checklistItem.homeStatus.completedAt!, locale: 'id')}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Notes
                        if (checklistItem.homeStatus.notes != null &&
                            checklistItem.homeStatus.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.note,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    checklistItem.homeStatus.notes!,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // School status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sekolah',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppColors.school),
                          ),
                          CompletionBadge(
                            isCompleted: checklistItem.schoolStatus.completed,
                            environment: 'School',
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      if (checklistItem.schoolStatus.completed) ...[
                        const Divider(),

                        // Completed time
                        if (checklistItem.schoolStatus.completedAt != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Diselesaikan ${timeago.format(checklistItem.schoolStatus.completedAt!, locale: 'id')}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Notes
                        if (checklistItem.schoolStatus.notes != null &&
                            checklistItem.schoolStatus.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.note,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    checklistItem.schoolStatus.notes!,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ElevatedButton(
          onPressed:
              checklistItem.homeStatus.completed
                  ? () async {
                    // Unmark as completed
                    await checklistProvider.updateCompletionStatus(
                      checklistItemId: checklistItem.id,
                      environment: 'home',
                      userId: authProvider.userModel!.id,
                      notes: null,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Aktivitas ditandai belum selesai'),
                        ),
                      );
                    }
                  }
                  : () async {
                    // Show dialog to add completion note
                    final result = await showDialog<CompletionNoteResult>(
                      context: context,
                      builder: (context) => const CompletionNoteDialog(),
                    );

                    if (result != null && context.mounted) {
                      await checklistProvider.updateCompletionStatus(
                        checklistItemId: checklistItem.id,
                        environment: 'home',
                        userId: authProvider.userModel!.id,
                        notes: result.note,
                        photoUrl:
                            null, // Photo upload not implemented in this version
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Aktivitas ditandai selesai'),
                          ),
                        );
                      }
                    }
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                checklistItem.homeStatus.completed
                    ? Colors.grey.shade300
                    : AppColors.home,
            foregroundColor:
                checklistItem.homeStatus.completed
                    ? Colors.black87
                    : Colors.white,
          ),
          child: Text(
            checklistItem.homeStatus.completed
                ? 'Tandai Belum Selesai'
                : 'Tandai Selesai',
          ),
        ),
      ),
    );
  }

  Color _getDueDateColor(
    BuildContext context,
    DateTime dueDate,
    ChecklistItemModel checklistItem,
  ) {
    final now = DateTime.now();

    if (dueDate.isBefore(now) &&
        !(checklistItem.homeStatus.completed ||
            checklistItem.schoolStatus.completed)) {
      return AppColors.error;
    }

    if (dueDate.difference(now).inDays <= 2 &&
        !(checklistItem.homeStatus.completed ||
            checklistItem.schoolStatus.completed)) {
      return AppColors.pending;
    }

    return Colors.grey.shade600;
  }
}
