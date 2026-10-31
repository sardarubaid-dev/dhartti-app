
import 'dart:convert';
import 'package:dhartti/Model/project_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dhartti/constants.dart';

class ProjectService {
  final String baseUrl = AppConstants.baseUrl; // Replace with your API URL
  static String get imageBaseUrl => "${AppConstants.baseUrl.replaceAll('/api', '')}/uploads/project/";
  final FlutterSecureStorage storage = FlutterSecureStorage();

  // Method to get token from SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  Future<int> fetchUserProjectsCount(String userId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId/projects/count'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['count'];
    }
    return 0;
  }

  // Fetch projects for the user panel
  Future<List<Project>> fetchUserPanelProjects() async {
    final token = await getToken();
    final prefs = await SharedPreferences.getInstance();
    final rawUserId = prefs.get('userId');
    final userId = rawUserId != null ? rawUserId.toString() : '';

    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final url = '$baseUrl/user-panel-projects${userId.isNotEmpty ? "?user_id=$userId" : ""}';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody.containsKey('projects')) {
          final List<dynamic> data = responseBody['projects'];
          _updateImageUrls(data);
          return data.map((project) => Project.fromJson(project)).toList();
        }
      }

      // Fallback to /projects
      final fallbackUrl = '$baseUrl/projects${userId.isNotEmpty ? "?user_id=$userId" : ""}';
      final fallbackRes = await http.get(Uri.parse(fallbackUrl), headers: headers);
      if (fallbackRes.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(fallbackRes.body);
        if (responseBody.containsKey('projects')) {
          final List<dynamic> data = responseBody['projects'];
          _updateImageUrls(data);
          return data.map((project) => Project.fromJson(project)).toList();
        }
      }
    } catch (e) {
      print("Error fetching user panel projects: $e");
    }

    return [];
  }

  // Fetch all projects
  Future<List<Project>> fetchProjects() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token'); // Fetch stored user token

    if (token == null) {
      throw Exception("User not authenticated");
    }

    final response = await http.get(
      Uri.parse('$baseUrl/projects'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['projects'];
      _updateImageUrls(data); // Update image URLs for all projects
      return data.map((project) => Project.fromJson(project)).toList();
    } else {
      throw Exception("Failed to load projects");
    }
  }

  // Fetch projects for super admin
  Future<List<Project>> fetchProjectsBySuperAdmin() async {
    final response = await http.get(
      Uri.parse('$baseUrl/project'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['projects'];
      _updateImageUrls(data); // Update image URLs for all projects
      return data.map((project) => Project.fromJson(project)).toList();
    } else {
      throw Exception("Failed to load projects");
    }
  }

  // Create a new project
  Future<Project> createProject(Project project) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/projects'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(project.toJson()),
    );

    print('API Response Status Code: ${response.statusCode}'); // Debugging
    print('API Response Body: ${response.body}'); // Debugging

    if (response.statusCode == 201) {
      return Project.fromJson(jsonDecode(response.body)['project']);
    } else {
      throw Exception('Failed to create project: ${response.body}');
    }
  }

  // Fetch a single project by ID
  Future<Project> fetchProject(int id) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/projects/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      _updateImageUrls([responseData['project']]); // Update image URLs for the project
      return Project.fromJson(responseData['project']);
    } else {
      throw Exception('Failed to load project: ${response.statusCode}');
    }
  }
  Future<Map<String, dynamic>> fetchProjectss(int id) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/projects/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['project'];
    } else {
      throw Exception('Failed to load project');
    }
  }
  Future<Project> editProject(int id) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/projects/$id/edit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      _updateImageUrls([responseData]); // If needed
      return Project.fromJson(responseData);
    } else {
      throw Exception('Failed to load project for edit: ${response.statusCode}');
    }
  }

  // Update a project
  Future<bool> updateProject(int id, Map<String, dynamic> projectData) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/projects/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(projectData),
    );

    if (response.statusCode == 200) {
      print('Project updated successfully!');
      return true;
    } else {
      print('Failed to update project: ${response.body}');
      throw Exception('Failed to update project: ${response.body}');
    }
  }

  // Delete a project
  Future<bool> deleteProject(int id) async {
    try {
      final token = await getToken();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      final response = await http.delete(
        Uri.parse('$baseUrl/seller/projects/$id?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting project: $e');
      return false;
    }
  }
  // Helper method to update image URLs for all projects
  void _updateImageUrls(List<dynamic> projects) {
    for (var project in projects) {
      if (project == null || project is! Map) continue;
      // Update image paths for all 3 image keys
      project['image'] = formatProjectImageUrl(project['image']?.toString());
      project['image_2'] = formatProjectImageUrl(project['image_2']?.toString());
      project['image_3'] = formatProjectImageUrl(project['image_3']?.toString());
    }
  }

  static String formatProjectImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty || imagePath == 'null') {
      return '';
    }
    var trimmed = imagePath.trim();
    final serverBase = AppConstants.baseUrl.replaceAll('/api', '');

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.path.contains('uploads/')) {
        final cleanPath = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
        return '$serverBase/$cleanPath';
      }
      return trimmed;
    }

    if (trimmed.startsWith('/')) {
      trimmed = trimmed.substring(1);
    }
    if (!trimmed.startsWith('uploads/')) {
      trimmed = 'uploads/project/$trimmed';
    }
    return '$serverBase/$trimmed';
  }
}
