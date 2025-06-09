// Model Activity untuk API Laravel
class Activity {
  final int id;
  final String name;
  final String date;

  Activity({required this.id, required this.name, required this.date});

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(id: json['id'], name: json['name'], date: json['date']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'date': date};
  }
}
