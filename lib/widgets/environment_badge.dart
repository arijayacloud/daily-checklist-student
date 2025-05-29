import 'package:flutter/material.dart';
import '../core/theme/app_colors_compat.dart';

class EnvironmentBadge extends StatelessWidget {
  final String environment;
  final double size;

  const EnvironmentBadge({Key? key, required this.environment, this.size = 16})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String label;

    switch (environment.toLowerCase()) {
      case 'home':
        icon = Icons.home_rounded;
        color = AppColors.home;
        label = 'Rumah';
        break;
      case 'school':
        icon = Icons.school_rounded;
        color = AppColors.school;
        label = 'Sekolah';
        break;
      case 'both':
        icon = Icons.sync_alt_rounded;
        color = AppColors.both;
        label = 'Keduanya';
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
