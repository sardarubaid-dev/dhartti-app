import 'package:dhartti/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  final String baseUrl = AppConstants.baseUrl; // Replace with your Laravel API URL

  Future<void> updateViews(int propertyId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analytics/update-views/$propertyId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        print('Analytics updateViews response: ${response.statusCode}');
      }
    } catch (e) {
      print('Analytics updateViews error: $e');
    }
  }

  Future<void> updateWhatsAppClicks(int propertyId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analytics/update-whatsapp-clicks/$propertyId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        print('Analytics updateWhatsAppClicks response: ${response.statusCode}');
      }
    } catch (e) {
      print('Analytics updateWhatsAppClicks error: $e');
    }
  }

  Future<void> updateCallClicks(int propertyId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analytics/update-call-clicks/$propertyId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        print('Analytics updateCallClicks response: ${response.statusCode}');
      }
    } catch (e) {
      print('Analytics updateCallClicks error: $e');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // Fetch the user token
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
