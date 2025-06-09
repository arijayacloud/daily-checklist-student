// Model Child untuk API Laravel
class Child {
  final int id;
  final String name;
  final int age;

  Child({required this.id, required this.name, required this.age});

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(id: json['id'], name: json['name'], age: json['age']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'age': age};
  }
}
