import 'package:flutter/material.dart';

class ProgressFilter extends StatelessWidget {
  final String currentFilter;
  final Function(String) onFilterChanged;

  const ProgressFilter({
    Key? key,
    required this.currentFilter,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        children: [
          Text('Filter: ', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'Semua', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'Belum Selesai', 'pending'),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'Sudah Selesai', 'completed'),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'Terlambat', 'overdue'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String filterValue,
  ) {
    final isSelected = currentFilter == filterValue;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onFilterChanged(filterValue),
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
