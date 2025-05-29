import 'package:flutter/material.dart';
import '../core/theme/app_colors_compat.dart';

class ProgressBar extends StatelessWidget {
  final int total;
  final int completed;
  final int partial;
  final Color completedColor;
  final Color partialColor;
  final Color backgroundColor;
  final double height;
  final bool showPercentage;

  const ProgressBar({
    Key? key,
    required this.total,
    required this.completed,
    this.partial = 0,
    this.completedColor = AppColors.complete,
    this.partialColor = AppColors.partial,
    this.backgroundColor = AppColors.backgroundLight,
    this.height = 16.0,
    this.showPercentage = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Prevent division by zero
    if (total == 0) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );
    }

    // Calculate percentages
    final double completedPercentage = completed / total;
    final double partialPercentage = partial / total;
    final double overallPercentage =
        completedPercentage + (partialPercentage * 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        Stack(
          children: [
            // Background
            Container(
              height: height,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),

            // Partial progress
            if (partial > 0)
              FractionallySizedBox(
                widthFactor: (completed + partial) / total,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: partialColor,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),

            // Completed progress
            if (completed > 0)
              FractionallySizedBox(
                widthFactor: completed / total,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: completedColor,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
          ],
        ),

        // Percentage indicator
        if (showPercentage)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(overallPercentage * 100).toInt()}% Selesai',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimaryLight,
                    fontSize: height * 0.8,
                  ),
                ),
                Text(
                  '$completed/${partial > 0 ? '$partial/' : ''}$total',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: height * 0.8,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
