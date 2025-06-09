import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/planning_model.dart';

class PlanningProvider {
  final String baseUrl;
  PlanningProvider({required this.baseUrl});

  Future<List<Planning>> fetchPlannings() async {
    final response = await http.get(Uri.parse('$baseUrl/plannings'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Planning.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat planning');
    }
  }

  Future<Planning> addPlanning(Planning planning) async {
    final response = await http.post(
      Uri.parse('$baseUrl/plannings'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(planning.toJson()),
    );
    if (response.statusCode == 201) {
      return Planning.fromJson(json.decode(response.body));
    } else {
      throw Exception('Gagal menambah planning');
    }
  }

  Future<Planning> updatePlanning(Planning planning) async {
    final response = await http.put(
      Uri.parse('$baseUrl/plannings/${planning.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(planning.toJson()),
    );
    if (response.statusCode == 200) {
      return Planning.fromJson(json.decode(response.body));
    } else {
      throw Exception('Gagal update planning');
    }
  }

  Future<void> deletePlanning(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/plannings/$id'));
    if (response.statusCode != 204) {
      throw Exception('Gagal menghapus planning');
    }
  }
}
