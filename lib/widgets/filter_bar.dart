import 'package:flutter/material.dart';
import '../core/theme.dart';

class FilterOption {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const FilterOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class FilterBar extends StatelessWidget {
  final String currentFilter;
  final Function(String) onFilterChanged;
  final List<FilterOption> filterOptions;

  FilterBar({
    Key? key,
    required this.currentFilter,
    required this.onFilterChanged,
    List<FilterOption>? filterOptions,
  }) : filterOptions = filterOptions ?? defaultFilterOptions,
       super(key: key);

  static const List<FilterOption> defaultFilterOptions = [
    FilterOption(
      id: 'all',
      label: 'Semua',
      icon: Icons.list_alt,
      color: AppColors.primary,
    ),
    FilterOption(
      id: 'pending',
      label: 'Belum',
      icon: Icons.pending_outlined,
      color: AppColors.pending,
    ),
    FilterOption(
      id: 'partial',
      label: 'Sebagian',
      icon: Icons.timelapse_rounded,
      color: AppColors.partial,
    ),
    FilterOption(
      id: 'complete',
      label: 'Selesai',
      icon: Icons.check_circle_outline_rounded,
      color: AppColors.complete,
    ),
    FilterOption(
      id: 'overdue',
      label: 'Terlambat',
      icon: Icons.warning_amber_rounded,
      color: AppColors.overdue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filterOptions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final option = filterOptions[index];
          final isSelected = currentFilter == option.id;

          return FilterChip(
            label: Text(
              option.label,
              style: TextStyle(
                color: isSelected ? Colors.white : option.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            avatar: Icon(
              option.icon,
              size: 18,
              color: isSelected ? Colors.white : option.color,
            ),
            selected: isSelected,
            selectedColor: option.color,
            backgroundColor: option.color.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: option.color, width: 1),
            ),
            onSelected: (selected) {
              if (selected) {
                onFilterChanged(option.id);
              }
            },
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          );
        },
      ),
    );
  }
}
