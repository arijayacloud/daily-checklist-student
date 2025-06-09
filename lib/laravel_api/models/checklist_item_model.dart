// Model ChecklistItem untuk API Laravel
class ChecklistItem {
  final int id;
  final String name;
  final bool isChecked;

  ChecklistItem({
    required this.id,
    required this.name,
    required this.isChecked,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      name: json['name'],
      isChecked: json['is_checked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'is_checked': isChecked};
  }
}
