import 'package:flutter/material.dart';
import '../core/theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double size;

  const StatusBadge({Key? key, required this.status, this.size = 16})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        icon = Icons.pending_outlined;
        color = AppColors.pending;
        label = 'Belum Selesai';
        break;
      case 'partial':
        icon = Icons.timelapse_rounded;
        color = AppColors.partial;
        label = 'Sebagian';
        break;
      case 'complete':
        icon = Icons.check_circle_outline_rounded;
        color = AppColors.complete;
        label = 'Selesai';
        break;
      case 'overdue':
        icon = Icons.warning_amber_rounded;
        color = AppColors.overdue;
        label = 'Terlambat';
        break;
      default:
        icon = Icons.help_outline_rounded;
        color = AppColors.textSecondary;
        label = 'Tidak Diketahui';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: size * 0.8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
