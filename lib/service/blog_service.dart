import 'package:dhartti/constants.dart';
import 'dart:convert';
import 'package:dhartti/Model/Blog.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BlogService {
  static const String baseUrl = AppConstants.baseUrl;
  static String get imageUrl => AppConstants.baseUrl.replaceAll('/api', '');

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final dynamic val = prefs.get('userId');
    if (val is int) return val;
    if (val is String) return int.tryParse(val);
    return null;
  }

  // Fetch all blogs
  Future<List<Blog>> fetchBlogs() async {
    final response = await http.get(Uri.parse('$baseUrl/blogs'));

    if (response.statusCode == 200) {
      // Parse the JSON response
      List<dynamic> data = json.decode(response.body);
      _updateImageUrls(data); // Update image URLs for all blogs
      return data.map((blogJson) => Blog.fromJson(blogJson)).toList();
    } else {
      throw Exception('Failed to load blogs');
    }
  }

  // Create a new blog
  Future<void> createBlog(Map<String, dynamic> blogData) async {
    final token = await getToken();
    if (token == null) {
      throw Exception("User not authenticated");
    }

    final response = await http.post(
      Uri.parse('$baseUrl/blogs'), // Replace with your contact endpoint
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(blogData),
    );

    print('API Response Status Code: ${response.statusCode}'); // Debugging
    print('API Response Body: ${response.body}'); // Debugging

    if (response.statusCode == 201) {
      print('Blog created successfully');
    } else {
      throw Exception('Failed to create blog: ${response.body}');
    }
  }

  // Update a blog
  Future<dynamic> updateBlog(int id, Map<String, dynamic> blogData) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/blogs/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(blogData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update blog: ${response.body}');
    }
  }

  // Delete a blog
  Future<void> deleteBlog(int id) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/blogs/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete blog: ${response.body}');
    }
  }

  // Helper method to update image URLs for all blogs
  void _updateImageUrls(List<dynamic> blogs) {
    for (var blog in blogs) {
      // Update image paths for all 4 image keys
      blog['Blog_image_1'] = formatImageUrl(blog['Blog_image_1']);
      blog['Blog_image_2'] = formatImageUrl(blog['Blog_image_2']);
      blog['Blog_image_3'] = formatImageUrl(blog['Blog_image_3']);
      blog['Blog_image_4'] = formatImageUrl(blog['Blog_image_4']);
    }
  }

  // Public helper method to construct the full image URL
  static String formatImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty || imagePath == 'null') {
      return '';
    }
    var trimmed = imagePath.trim();
    final serverBase = AppConstants.baseUrl.replaceAll('/api', '');

    // If it's a full URL
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
    if (!trimmed.startsWith('uploads/blog_images/')) {
      trimmed = 'uploads/blog_images/$trimmed';
    }
    return '$serverBase/$trimmed';
  }

  // Method to get token from SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
