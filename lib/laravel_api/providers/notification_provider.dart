import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/notification_model.dart';

class NotificationProvider {
  final String baseUrl;
  NotificationProvider({required this.baseUrl});

  Future<List<NotificationModel>> fetchNotifications() async {
    final response = await http.get(Uri.parse('$baseUrl/notifications'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => NotificationModel.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat notifikasi');
    }
  }

  Future<NotificationModel> addNotification(NotificationModel notif) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(notif.toJson()),
    );
    if (response.statusCode == 201) {
      return NotificationModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Gagal menambah notifikasi');
    }
  }

  Future<void> deleteNotification(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/notifications/$id'));
    if (response.statusCode != 204) {
      throw Exception('Gagal menghapus notifikasi');
    }
  }
}
