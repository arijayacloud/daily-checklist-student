import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'environment_badge.dart';
import 'status_badge.dart';

class ChecklistItemCard extends StatelessWidget {
  final ChecklistItemModel checklistItem;
  final ActivityModel activity;
  final VoidCallback? onTap;
  final Function(String, String)? onStatusUpdate;
  final String currentUserRole;
  final String currentUserId;

  const ChecklistItemCard({
    Key? key,
    required this.checklistItem,
    required this.activity,
    this.onTap,
    this.onStatusUpdate,
    required this.currentUserRole,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isOverdue =
        checklistItem.dueDate.isBefore(DateTime.now()) &&
        checklistItem.overallStatus != 'complete';

    final String displayStatus =
        isOverdue ? 'overdue' : checklistItem.overallStatus;

    // Tentukan apakah pengguna bisa menyelesaikan tugas di lingkungan tertentu
    final bool canCompleteAtHome =
        currentUserRole == 'parent' &&
        (activity.environment == 'home' || activity.environment == 'both') &&
        !checklistItem.homeStatus.completed;

    final bool canCompleteAtSchool =
        currentUserRole == 'teacher' &&
        (activity.environment == 'school' || activity.environment == 'both') &&
        !checklistItem.schoolStatus.completed;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul dan Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      activity.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: displayStatus),
                ],
              ),

              const SizedBox(height: 8),

              // Deskripsi
              Text(
                activity.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Environment dan Due Date
              Row(
                children: [
                  EnvironmentBadge(environment: activity.environment),
                  const Spacer(),
                  Icon(
                    Icons.event,
                    size: 16,
                    color:
                        isOverdue ? AppColors.overdue : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tenggat: ${DateFormat('dd MMM yyyy').format(checklistItem.dueDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          isOverdue
                              ? AppColors.overdue
                              : AppColors.textSecondary,
                      fontWeight:
                          isOverdue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Home Status
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.home.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.home_rounded,
                            color: AppColors.home,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rumah',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                checklistItem.homeStatus.completed
                                    ? 'Selesai'
                                    : 'Belum',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      checklistItem.homeStatus.completed
                                          ? AppColors.complete
                                          : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (canCompleteAtHome)
                          Checkbox(
                            value: checklistItem.homeStatus.completed,
                            onChanged: (value) {
                              if (onStatusUpdate != null && value == true) {
                                onStatusUpdate!('home', checklistItem.id);
                              }
                            },
                            activeColor: AppColors.complete,
                          ),
                      ],
                    ),
                  ),

                  // School Status
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.school.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            color: AppColors.school,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sekolah',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                checklistItem.schoolStatus.completed
                                    ? 'Selesai'
                                    : 'Belum',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      checklistItem.schoolStatus.completed
                                          ? AppColors.complete
                                          : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (canCompleteAtSchool)
                          Checkbox(
                            value: checklistItem.schoolStatus.completed,
                            onChanged: (value) {
                              if (onStatusUpdate != null && value == true) {
                                onStatusUpdate!('school', checklistItem.id);
                              }
                            },
                            activeColor: AppColors.complete,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
