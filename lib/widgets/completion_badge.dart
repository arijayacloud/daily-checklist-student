import 'package:flutter/material.dart';
import '../core/theme/app_colors_compat.dart';

class CompletionBadge extends StatelessWidget {
  final bool isCompleted;
  final String environment;
  final bool small;

  const CompletionBadge({
    super.key,
    required this.isCompleted,
    required this.environment,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color textColor;
    final String text;

    if (isCompleted) {
      if (environment == 'Home') {
        backgroundColor = AppColors.home.withOpacity(0.2);
        textColor = AppColors.home;
        text = 'Rumah';
      } else {
        backgroundColor = AppColors.school.withOpacity(0.2);
        textColor = AppColors.school;
        text = 'Sekolah';
      }
    } else {
      backgroundColor = Colors.grey.shade200;
      textColor = Colors.grey.shade600;
      text = small ? '' : 'Belum Selesai';
    }

    if (small) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.circle,
              size: 10,
              color: textColor,
            ),
            if (text.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                text,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isCompleted ? 'Selesai' : 'Belum Selesai',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
