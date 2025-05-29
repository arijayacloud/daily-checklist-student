import 'package:flutter/material.dart';

class FilterChipGroup extends StatelessWidget {
  final List<String> options;
  final List<String> labels;
  final String selectedValue;
  final Function(String?) onSelected;

  const FilterChipGroup({
    super.key,
    required this.options,
    required this.labels,
    required this.onSelected,
    this.selectedValue = '',
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      children: List.generate(options.length, (index) {
        final option = options[index];
        final label = labels[index];

        return FilterChip(
          label: Text(label),
          selected: selectedValue == option,
          onSelected: (selected) {
            if (selected) {
              onSelected(option);
            } else {
              onSelected(null);
            }
          },
        );
      }),
    );
  }
}
