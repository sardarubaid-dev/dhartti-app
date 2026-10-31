import 'package:dhartti/constants.dart';
import 'dart:convert';
import 'package:dhartti/Model/PropertyInquiry.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PropertyInquiryService {
  final String baseUrl = AppConstants.baseUrl; // Replace with your API URL


  Future<bool> submitInquiry(PropertyInquiry inquiry) async {
    if (inquiry.propertyId == null) {
      throw Exception("propertyId is null!");
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/submit-property-inquiry'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(inquiry.toJson()),
    );

    print("Response: ${response.statusCode} - ${response.body}");

    return response.statusCode == 200 || response.statusCode == 201;
  }

}
