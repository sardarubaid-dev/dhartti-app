import 'package:dhartti/constants.dart';
import 'dart:convert';
import 'package:dhartti/Model/ConstructionCostModel.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConstructionCostService {
  static const String baseUrl = AppConstants.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<ConstructionCostModel>> getAll() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/construction-costs'), headers: headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ConstructionCostModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<ConstructionCostModel> create(ConstructionCostModel model) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/construction-costs'),
      headers: headers,
      body: jsonEncode(model.toJson()),
    );
    if (response.statusCode == 201) {
      return ConstructionCostModel.fromJson(jsonDecode(response.body)['data']);
    } else {
      throw Exception("Failed to create");
    }
  }

  static Future<ConstructionCostModel> update(int id, ConstructionCostModel model) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/construction-costs/$id'),
      headers: headers,
      body: jsonEncode(model.toJson()),
    );
    if (response.statusCode == 200) {
      return ConstructionCostModel.fromJson(jsonDecode(response.body)['data']);
    } else {
      throw Exception("Failed to update");
    }
  }

  static Future<void> delete(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/construction-costs/$id'), headers: headers);
    if (response.statusCode != 200) {
      throw Exception("Failed to delete");
    }
  }
}
