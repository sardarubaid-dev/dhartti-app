import 'package:dhartti/constants.dart';
import 'dart:convert';
import 'package:dhartti/Model/Contact.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ContactService {
  final String baseUrl = AppConstants.baseUrl; // Replace with your API URL
  final FlutterSecureStorage storage = FlutterSecureStorage();

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final dynamic val = prefs.get('userId');
    if (val is int) return val;
    if (val is String) return int.tryParse(val);
    return null;
  }
  Future<List<Contact>> fetchContact() async {
    final response = await http.get(
      Uri.parse('$baseUrl/contacts'),
      headers: {
        'Content-Type': 'application/json', // Optional: Only include if your API requires it
      },
    );

    if (response.statusCode == 200) {
      // Parse the JSON response
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Contact.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load contacts');
    }
  }

  // Future<List<Contact>> fetchContact() async {
  //   final token = await getToken();
  //   if (token == null) {
  //     throw Exception("User not authenticated");
  //   }
  //
  //   final response = await http.get(
  //     Uri.parse('$baseUrl/contacts'),
  //     headers: {
  //       'Authorization': 'Bearer $token', // Include the token in the headers
  //       'Content-Type': 'application/json',
  //     },
  //   );
  //
  //   if (response.statusCode == 200) {
  //     // Parse the JSON response
  //     List<dynamic> data = json.decode(response.body);
  //     return data.map((contactJson) => Contact.fromJson(contactJson)).toList();
  //   } else {
  //     throw Exception('Failed to load contacts data: ${response.body}');
  //   }
  // }
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  Future<bool> createContact(Map<String, dynamic> contactData) async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    // Normalize keys expected by Laravel API
    final payload = {
      'Name': contactData['Name'] ?? contactData['name'] ?? '',
      'Email': contactData['Email'] ?? contactData['email'] ?? '',
      'Phone_number': contactData['Phone_number'] ?? contactData['phone'] ?? contactData['phone_number'] ?? '',
      'Subject': contactData['Subject'] ?? contactData['subject'] ?? 'General Inquiry',
      'Message': contactData['Message'] ?? contactData['message'] ?? '',
    };

    final response = await http.post(
      Uri.parse('$baseUrl/contacts'),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      String msg = 'Failed to submit contact inquiry: ${response.statusCode}';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded['message'] != null) msg = decoded['message'];
      } catch (_) {}
      throw Exception(msg);
    }
  }
}
