import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/checklist_item_model.dart';

class ChecklistProvider {
  final String baseUrl;
  ChecklistProvider({required this.baseUrl});

  Future<List<ChecklistItem>> fetchChecklist() async {
    final response = await http.get(Uri.parse('$baseUrl/checklists'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => ChecklistItem.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat checklist');
    }
  }

  Future<ChecklistItem> addChecklist(ChecklistItem item) async {
    final response = await http.post(
      Uri.parse('$baseUrl/checklists'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(item.toJson()),
    );
    if (response.statusCode == 201) {
      return ChecklistItem.fromJson(json.decode(response.body));
    } else {
      throw Exception('Gagal menambah checklist');
    }
  }

  Future<ChecklistItem> updateChecklist(ChecklistItem item) async {
    final response = await http.put(
      Uri.parse('$baseUrl/checklists/${item.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(item.toJson()),
    );
    if (response.statusCode == 200) {
      return ChecklistItem.fromJson(json.decode(response.body));
    } else {
      throw Exception('Gagal update checklist');
    }
  }

  Future<void> deleteChecklist(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/checklists/$id'));
    if (response.statusCode != 204) {
      throw Exception('Gagal menghapus checklist');
    }
  }
}
