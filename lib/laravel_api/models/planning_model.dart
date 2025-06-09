// Model Planning untuk API Laravel
class Planning {
  final int id;
  final String title;
  final String description;

  Planning({required this.id, required this.title, required this.description});

  factory Planning.fromJson(Map<String, dynamic> json) {
    return Planning(
      id: json['id'],
      title: json['title'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'description': description};
  }
}
