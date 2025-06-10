import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/config.dart';

class ApiService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    final headers = Map<String, String>.from(defaultHeaders);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    
    debugPrint('GET $url');
    return http.get(url, headers: headers);
  }

  Future<http.Response> post(String endpoint, dynamic data) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    final body = jsonEncode(data);
    
    debugPrint('POST $url');
    debugPrint('Body: $body');
    return http.post(url, headers: headers, body: body);
  }

  Future<http.Response> put(String endpoint, dynamic data) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    final body = jsonEncode(data);
    
    debugPrint('PUT $url');
    debugPrint('Body: $body');
    return http.put(url, headers: headers, body: body);
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    
    debugPrint('DELETE $url');
    return http.delete(url, headers: headers);
  }
} 