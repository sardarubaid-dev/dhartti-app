import 'package:dhartti/constants.dart';
import 'dart:convert';
import 'package:dhartti/Model/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
    static const String baseUrl = AppConstants.baseUrl;

  Future<Map<String, dynamic>> registerUserDetailed(
    String name,
    String email,
    String contactNumber,
    String password,
    String passwordConfirm, {
    int roleId = 1,
    String? agencyName,
    String? firmName,
    String? city,
    String? cnic,
    String? specialization,
    String? experienceYears,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'name': name,
        'email': email,
        'contact_number': contactNumber,
        'password': password,
        'password_confirmation': passwordConfirm,
        'roleId': roleId,
      };

      if (agencyName != null && agencyName.isNotEmpty) requestBody['agency_name'] = agencyName;
      if (firmName != null && firmName.isNotEmpty) requestBody['firm_name'] = firmName;
      if (city != null && city.isNotEmpty) requestBody['city'] = city;
      if (cnic != null && cnic.isNotEmpty) requestBody['cnic'] = cnic;
      if (specialization != null && specialization.isNotEmpty) requestBody['specialization'] = specialization;
      if (experienceYears != null && experienceYears.isNotEmpty) requestBody['experience_years'] = experienceYears;

      final response = await http.post(
        Uri.parse('$baseUrl/registers'),
        body: jsonEncode(requestBody),
        headers: {"Content-Type": "application/json", "Accept": "application/json"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final token = data['token'];
        final user = data['user'];
        final returnedRoleId = (data['roleId'] ?? user?['roleId'] ?? roleId).toString();

        if (token != null) await _saveToken(token);
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('name', user['name']?.toString() ?? name);
          await prefs.setString('userName', user['name']?.toString() ?? name);
          await prefs.setString('email', user['email']?.toString() ?? email);
          await prefs.setString('userEmail', user['email']?.toString() ?? email);
          await prefs.setString('contact_number', user['contact_number']?.toString() ?? contactNumber);
          await prefs.setString('userPhone', user['contact_number']?.toString() ?? contactNumber);
          if (user['id'] != null) {
            await prefs.setInt('userId', int.tryParse(user['id'].toString()) ?? 0);
            await prefs.setString('userId', user['id'].toString());
          }
          await prefs.setString('roleId', returnedRoleId);
        }
        return {
          'success': true,
          'roleId': returnedRoleId,
          'pending_approval': data['pending_approval'] == true,
          'requested_role': data['requested_role'],
          'message': data['message'] ?? 'Account created successfully!',
        };
      } else {
        String msg = data['message'] ?? 'Registration failed';
        if (data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          final firstKey = errors.keys.first;
          msg = errors[firstKey][0].toString();
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<bool> registerUser(String name, String email, String contactNumber, String password, String passwordConfirm, {int roleId = 1}) async {
    final res = await registerUserDetailed(name, email, contactNumber, password, passwordConfirm, roleId: roleId);
    return res['success'] == true;
  }

  int? getSafeUserId(SharedPreferences prefs) {
    try {
      final dynamic raw = prefs.get('userId');
      if (raw is int) return raw;
      if (raw is String) return int.tryParse(raw);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> upgradeRole(
    int requestedRole, {
    Map<String, dynamic>? details,
    String? notes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = getSafeUserId(prefs);

      final headers = <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json",
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final Map<String, dynamic> body = {
        'requested_role': requestedRole,
        'user_id': userId,
      };

      if (details != null) {
        body.addAll(details);
      }
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/upgrade-role'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Upgrade request submitted successfully!',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit upgrade request',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getUpgradeStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = getSafeUserId(prefs);

      final headers = <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json",
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final url = '$baseUrl/upgrade-status${userId != null ? "?user_id=$userId" : ""}';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final request = data['request'];
        final serverRoleId = (data['role_id'] ?? request?['requested_role'] ?? '').toString();
        if (serverRoleId.isNotEmpty && serverRoleId != 'null') {
          if (request != null && request['status'] == 'approved') {
            await prefs.setString('roleId', serverRoleId);
          } else if (data['role_id'] != null && data['role_id'].toString() != '1') {
            await prefs.setString('roleId', data['role_id'].toString());
          }
        }
        return {
          'success': true,
          'has_request': data['has_request'] == true,
          'request': request,
          'role_id': prefs.getString('roleId') ?? '1',
        };
      }
      return {'success': false, 'has_request': false};
    } catch (e) {
      return {'success': false, 'has_request': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> loginUserDetailed(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
        headers: {"Content-Type": "application/json", "Accept": "application/json"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        String token = data['token'];
        String username = data['user']['name'] ?? '';
        String userEmail = data['user']['email'] ?? '';
        String contactNumber = data['user']['contact_number'] ?? '';
        final roleId = (data['roleId'] ?? data['user']['roleId'] ?? 1).toString();
        final rawUserId = data['user']['id'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('name', username);
        await prefs.setString('userName', username);
        await prefs.setString('email', userEmail);
        await prefs.setString('userEmail', userEmail);
        await prefs.setString('contact_number', contactNumber);
        await prefs.setString('userPhone', contactNumber);
        await prefs.setString('roleId', roleId);
        if (rawUserId != null) {
          await prefs.setInt('userId', int.tryParse(rawUserId.toString()) ?? 0);
          await prefs.setString('userId', rawUserId.toString());
        }
        await _setTokenExpiration();

        return {
          'success': true,
          'roleId': roleId,
          'message': 'Login successful!',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Invalid email or password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please check your network.',
      };
    }
  }

  Future<bool> loginUser(String email, String password) async {
    final res = await loginUserDetailed(email, password);
    return res['success'] == true;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
  }

  Future<void> _saveContactNumber(String contactNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('contact_number', contactNumber);
  }

  Future<void> _setTokenExpiration() async {
    final prefs = await SharedPreferences.getInstance();
    final expirationTime = DateTime.now().add(Duration(days: 2)).toIso8601String();
    await prefs.setString('token_expiration', expirationTime);
  }
    Future<int> fetchTotalUsers() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        final response = await http.get(
          Uri.parse('$baseUrl/users/count'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['totalUsers']; // Adjust if key is different
        } else {
          print("Failed to fetch total users: ${response.body}");
          return 0;
        }
      } catch (e) {
        print("Error fetching total users: $e");
        return 0;
      }
    }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final name = prefs.getString('name');
    final contactNumber = prefs.getString('contact_number'); // Fixed key
    final email = prefs.getString('email');
    final userId = prefs.getString('userId');
    final roleIdStr = prefs.getString('roleId');
    final roleId = int.tryParse(roleIdStr ?? '1') ?? 1;

    if (token == null) return null;

    return User(
      id: int.tryParse(userId ?? '0') ?? 0, // Handle potential null/parsing
      name: name ?? '',
      email: email ?? '',
      contactNumber: contactNumber ?? '',
      token: token,
      roleId: roleId,
    );
  }

  Future<bool> updateUserProfile({
    required String name,
    required String email,
    required String contactNumber,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'contact_number': contactNumber,
        }),
      );

      if (response.statusCode == 200) {
        await _saveName(name);
        await _saveEmail(email);
        await _saveContactNumber(contactNumber);
        return true;
      }
      return false;
    } catch (e) {
      print("Update Error: $e");
      return false;
    }
  }

  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expirationTime = prefs.getString('token_expiration');

    if (expirationTime == null) return true;

    final now = DateTime.now();
    final expirationDate = DateTime.parse(expirationTime);
    return now.isAfter(expirationDate);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('name');
    await prefs.remove('roleId');
    await prefs.remove('token_expiration');
    await prefs.remove('email');
    await prefs.remove('contact_number');
    await prefs.remove('userId');
  }
}
