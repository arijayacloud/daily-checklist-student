import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/activity_model.dart';

class ActivityProvider {
  final String baseUrl;
  ActivityProvider({required this.baseUrl});

  Future<List<Activity>> fetchActivities() async {
    final response = await http.get(Uri.parse('$baseUrl/activities'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Activity.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat aktivitas');
    }
  }

  Future<Activity> addActivity(Activity activity) async {
    final response = await http.post(
      Uri.parse('$baseUrl/activities'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(activity.toJson()),
    );
    if (response.statusCode == 201) {
      return Activity.fromJson(json.decode(response.body));
    } else {
      throw Exception('Gagal menambah aktivitas');
    }
  }

  Future<Activity> updateActivity(Activity activity) async {
    final response = await http.put(
      Uri.parse('$baseUrl/activities/${activity.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(activity.toJson()),
    );
    if (response.statusCode == 200) {
      return Activity.fromJson(json.decode(response.body));
    } else {
      throw Exception('Gagal update aktivitas');
    }
  }

  Future<void> deleteActivity(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/activities/$id'));
    if (response.statusCode != 204) {
      throw Exception('Gagal menghapus aktivitas');
    }
  }
}
