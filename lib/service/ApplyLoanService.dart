import 'package:dhartti/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dhartti/Model/ApplyLoanModel.dart';

class ApplyLoanService {
  static const String baseUrl = AppConstants.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.get('userId')?.toString() ?? prefs.get('user_id')?.toString();
    final email = prefs.getString('email') ?? prefs.getString('user_email');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (userId != null && userId.isNotEmpty) 'X-User-Id': userId,
      if (email != null && email.isNotEmpty) 'X-User-Email': email,
    };
  }

  static Future<ApplyLoan> applyForLoan(ApplyLoan application) async {
    final headers = await _getHeaders();
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.get('userId')?.toString() ?? prefs.get('user_id')?.toString();

    final bodyMap = application.toJson();
    if (savedUserId != null && savedUserId.isNotEmpty) {
      bodyMap['user_id'] = int.tryParse(savedUserId) ?? savedUserId;
      bodyMap['userId'] = int.tryParse(savedUserId) ?? savedUserId;
    }

    http.Response response = await http.post(
      Uri.parse('$baseUrl/apply-loan'),
      headers: headers,
      body: jsonEncode(bodyMap),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      // Fallback direct route
      response = await http.post(
        Uri.parse('$baseUrl/direct-apply-loan'),
        headers: headers,
        body: jsonEncode(bodyMap),
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return ApplyLoan.fromJson(data['data'] ?? data);
    } else {
      String errMsg = 'Failed to submit application (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson['message'] != null) {
          errMsg = errJson['message'];
        }
      } catch (_) {}
      throw Exception(errMsg);
    }
  }
}
