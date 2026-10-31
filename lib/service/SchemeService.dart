import 'package:dhartti/constants.dart';
import 'dart:convert';
import 'package:dhartti/Model/SchemeModel.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SchemeService {
  static const String baseUrl = AppConstants.baseUrl;

  // Helper method for adding auth headers
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.get('userId')?.toString() ?? prefs.get('user_id')?.toString();
    final email = prefs.getString('email') ?? prefs.getString('user_email');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (userId != null) 'X-User-Id': userId,
      if (email != null) 'X-User-Email': email,
    };
  }

  // Get all schemes
  static Future<List<Scheme>> getAllSchemes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/schemes'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((json) => Scheme.fromJson(json)).toList();
      } else if (data['data'] is List) {
        return (data['data'] as List).map((json) => Scheme.fromJson(json)).toList();
      } else {
        throw Exception('Invalid response format');
      }
    } else {
      throw Exception('Failed to load schemes: ${response.statusCode}');
    }
  }

  // Get schemes for current user
  static Future<List<Scheme>> getUserSchemes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/schemes/user'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((json) => Scheme.fromJson(json)).toList();
      } else if (data['data'] is List) {
        return (data['data'] as List).map((json) => Scheme.fromJson(json)).toList();
      } else {
        throw Exception('Invalid response format');
      }
    } else {
      throw Exception('Failed to load user schemes: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getSchemeDetails(int schemeId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/schemes/$schemeId/details'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load scheme details: ${response.statusCode}');
    }
  }

  // Create new scheme
  static Future<Scheme> createScheme(Scheme scheme) async {
    final response = await http.post(
      Uri.parse('$baseUrl/schemes'),
      headers: await _getHeaders(),
      body: jsonEncode(scheme.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Scheme.fromJson(data is Map ? data : data['data']);
    } else {
      throw Exception('Failed to create scheme: ${response.statusCode}');
    }
  }

  // Update existing scheme
  static Future<Scheme> updateScheme(Scheme scheme) async {
    final response = await http.put(
      Uri.parse('$baseUrl/schemes/${scheme.id}'),
      headers: await _getHeaders(),
      body: jsonEncode(scheme.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Scheme.fromJson(data is Map ? data : data['data']);
    } else {
      throw Exception('Failed to update scheme: ${response.statusCode}');
    }
  }

  // Delete scheme
  static Future<void> deleteScheme(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/schemes/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete scheme: ${response.statusCode}');
    }
  }

  // Get applications for a single scheme
  static Future<List<Map<String, dynamic>>> getSchemeApplications(int schemeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/schemes/$schemeId/applications'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final apps = data['applications'] ?? data['data'] ?? [];
      return List<Map<String, dynamic>>.from(apps);
    } else {
      throw Exception('Failed to load scheme applications: ${response.statusCode}');
    }
  }

  // Get all applications across all schemes created by user
  static Future<List<Map<String, dynamic>>> getAllUserSchemeApplications() async {
    final headers = await _getHeaders();
    http.Response response = await http.get(
      Uri.parse('$baseUrl/user/scheme-applications'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      // Fallback direct endpoint
      response = await http.get(
        Uri.parse('$baseUrl/direct-user-scheme-applications'),
        headers: headers,
      );
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data is List ? data : (data['data'] ?? []);
      return List<Map<String, dynamic>>.from(list);
    } else {
      throw Exception('Failed to load scheme applications');
    }
  }

  // Update status of a scheme application (approved, rejected, pending)
  static Future<bool> updateApplicationStatus(int applicationId, String status) async {
    final headers = await _getHeaders();
    final body = jsonEncode({'status': status});

    http.Response response = await http.post(
      Uri.parse('$baseUrl/scheme-applications/$applicationId/status'),
      headers: headers,
      body: body,
    );

    if (response.statusCode != 200) {
      response = await http.post(
        Uri.parse('$baseUrl/direct-scheme-applications/$applicationId/status'),
        headers: headers,
        body: body,
      );
    }

    return response.statusCode == 200;
  }
}
