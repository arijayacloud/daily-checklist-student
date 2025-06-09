import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/child_model.dart';

class ChildProvider {
  final String baseUrl;
  ChildProvider({required this.baseUrl});

  Future<List<Child>> fetchChildren() async {
    final response = await http.get(Uri.parse('$baseUrl/children'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Child.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat anak');
    }
  }

  Future<Child> addChild(Child child) async {
    final response = await http.post(
      Uri.parse('$baseUrl/children'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(child.toJson()),
    );
    if (response.statusCode == 201) {
      return Child.fromJson(json.decode(response.body));
    } else {
      throw Exception('Gagal menambah anak');
    }
  }

  Future<Child> updateChild(Child child) async {
    final response = await http.put(
      Uri.parse('$baseUrl/children/${child.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(child.toJson()),
    );
    if (response.statusCode == 200) {
      return Child.fromJson(json.decode(response.body));
    } else {
      throw Exception('Gagal update anak');
    }
  }

  Future<void> deleteChild(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/children/$id'));
    if (response.statusCode != 204) {
      throw Exception('Gagal menghapus anak');
    }
  }
}
