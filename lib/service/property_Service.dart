import 'package:dhartti/constants.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dhartti/Model/property_model.dart';
import 'package:dhartti/Model/superproperty_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PropertyService {
  final String baseUrl = AppConstants.baseUrl;
  final FlutterSecureStorage storage = FlutterSecureStorage();

  Future<List<PropertySuperAdmin>> fetchUserPanelPropertys() async {
    final token = await getToken();
    final prefs = await SharedPreferences.getInstance();
    final rawUserId = prefs.get('userId') ?? prefs.get('user_id');
    final userId = rawUserId?.toString();

    final url = '$baseUrl/user-panel-propertys${userId != null ? '?user_id=$userId' : ''}';
    final headers = <String, String>{
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (userId != null) 'X-User-Id': userId,
    };

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);

      if (responseBody.containsKey('propertys')) {
        final List<dynamic> data = responseBody['propertys'];
        _updateImageUrls(data);
        return data.map((project) => PropertySuperAdmin.fromJson(project)).toList();
      } else {
        throw Exception("Key 'propertys' not found in response");
      }
    } else {
      throw Exception("Failed to load properties: ${response.body}");
    }
  }
  Future<int> fetchUserPropertiesCount(String userId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId/properties/count'),
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


  Future<List<dynamic>> fetchProperties({
    String? city,
    String? purpose,
    String? propertyType,
    String? beds,
    String? baths,
    double? minPrice,
    double? maxPrice,
    double? minArea,
    double? maxArea,
    String? keyword,
  }) async {
    String? token = await getToken();

    final Map<String, String> headers = {
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    Map<String, String> queryParams = {};
    if (city != null && city.trim().isNotEmpty && city.trim().toLowerCase() != 'all cities') {
      queryParams['city'] = city.trim();
    }
    if (purpose != null && purpose.trim().isNotEmpty && purpose.trim().toLowerCase() != 'all') {
      queryParams['purpose'] = purpose.trim();
    }
    if (propertyType != null && propertyType.trim().isNotEmpty && propertyType.trim().toLowerCase() != 'all types') {
      queryParams['property_type'] = propertyType.trim();
    }
    if (beds != null && beds.trim().isNotEmpty && beds.trim().toLowerCase() != 'any') {
      queryParams['beds'] = beds.trim();
    }
    if (baths != null && baths.trim().isNotEmpty && baths.trim().toLowerCase() != 'any') {
      queryParams['baths'] = baths.trim();
    }
    if (minPrice != null && minPrice > 0) {
      queryParams['min_price'] = minPrice.toString();
    }
    if (maxPrice != null && maxPrice > 0) {
      queryParams['max_price'] = maxPrice.toString();
    }
    if (minArea != null && minArea > 0) {
      queryParams['min_area'] = minArea.toString();
    }
    if (maxArea != null && maxArea > 0) {
      queryParams['max_area'] = maxArea.toString();
    }
    if (keyword != null && keyword.trim().isNotEmpty) {
      queryParams['keyword'] = keyword.trim();
    }

    Uri uri = Uri.parse('$baseUrl/properties');
    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await http.get(
      uri,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'];
      _updateImageUrls(data);
      return data;
    } else {
      throw Exception('Failed to load properties');
    }
  }

  Future<List<PropertySuperAdmin>> fetchPropertyBySuperAdmin() async {
    final response = await http.get(
      Uri.parse('$baseUrl/propertie'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> data = responseData['property'];
      _updateImageUrls(data);
      return data.map((property) => PropertySuperAdmin.fromJson(property)).toList();
    } else {
      throw Exception("Failed to load properties. Status code: ${response.statusCode}");
    }
  }

  Future<PropertySuperAdmin> fetchProperty(int id) async {
    final token = await getToken();

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(
      Uri.parse('$baseUrl/propertys/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body)['property'];
      _updateImageUrls([responseData]);
      return PropertySuperAdmin.fromJson(responseData);
    } else {
      throw Exception('Failed to load property');
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<bool> saveProperty(
      Property property, {
        File? image1,
        File? image2,
        File? image3,
        File? image4,
        File? image5,
      }) async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/add-property'),
    )..headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Add all fields
    request.fields.addAll(property.toJson().map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
    ));

    // Add image files
    if (image1 != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image_path',
        image1.path,
        filename: 'image1_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
    }
    if (image2 != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image_path2',
        image2.path,
        filename: 'image2_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
    }
    if (image3 != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image_path3',
        image3.path,
        filename: 'image3_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
    }
    if (image4 != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image_path4',
        image4.path,
        filename: 'image4_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
    }
    if (image5 != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image_path5',
        image5.path,
        filename: 'image5_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
    }

    try {
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to save property: $responseData');
      }
    } catch (e) {
      throw Exception('Failed to save property: $e');
    }
  }
  Future<bool> updateProperty(
      Property property, {
        File? image1,
        File? image2,
        File? image3,
        File? image4,
        File? image5,
      }) async {
    final token = await getToken();
    final prefs = await SharedPreferences.getInstance();
    final rawUserId = prefs.get('userId');
    final userId = rawUserId?.toString();

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/update-property/${property.id}'),
    );

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (userId != null && userId.isNotEmpty) {
      request.headers['X-User-Id'] = userId;
    }
    request.headers['Accept'] = 'application/json';

    // Add all fields
    request.fields.addAll(property.toJson().map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
    ));

    // Add image files
    if (image1 != null && await image1.exists()) {
      request.files.add(await http.MultipartFile.fromPath(
        'image_path',
        image1.path,
        filename: 'image1_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
    }
    if (image2 != null && await image2.exists()) {
      request.files.add(await http.MultipartFile.fromPath(
        'image_pat2',
        image2.path,
        filename: 'image2_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
    }
    if (image3 != null && await image3.exists()) {
      request.files.add(await http.MultipartFile.fromPath(
        'image_path3',
        image3.path,
        filename: 'image3_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
    }
    if (image4 != null && await image4.exists()) {
      request.files.add(await http.MultipartFile.fromPath(
        'image_path4',
        image4.path,
        filename: 'image4_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
    }
    if (image5 != null && await image5.exists()) {
      request.files.add(await http.MultipartFile.fromPath(
        'image_path5',
        image5.path,
        filename: 'image5_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
    }

    try {
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to update property: ${response.statusCode} - $responseData');
        return false;
      }
    } catch (e) {
      print('Exception in updateProperty: $e');
      return false;
    }
  }
  void _updateImageUrls(List<dynamic> properties) {
    for (var property in properties) {
      if (property is Map<String, dynamic>) {
        property['image_path'] = _getFullImageUrl(property['image_path']);
        property['image_pat2'] = _getFullImageUrl(property['image_pat2'] ?? property['image_path2']);
        property['image_path2'] = property['image_pat2'];
        property['image_path3'] = _getFullImageUrl(property['image_path3']);
        property['image_path4'] = _getFullImageUrl(property['image_path4']);
        property['image_path5'] = _getFullImageUrl(property['image_path5']);
      }
    }
  }

  static String formatPropertyImageUrl(String? imagePath) {
    if (imagePath == null ||
        imagePath.trim().isEmpty ||
        imagePath == 'null' ||
        imagePath == '[]' ||
        imagePath == '{}') {
      return '';
    }

    var clean = imagePath.trim().replaceAll(r'\', '/');
    if (clean.endsWith('/') || clean.endsWith('/uploads/property') || clean.endsWith('/uploads')) {
      return '';
    }
    final String baseServerUrl = AppConstants.baseUrl.replaceAll('/api', '');

    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      final uri = Uri.tryParse(clean);
      if (uri != null && uri.path.contains('uploads/')) {
        final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
        return '$baseServerUrl/$path';
      }
      return clean;
    }

    if (clean.startsWith('/')) clean = clean.substring(1);
    if (!clean.startsWith('uploads/')) {
      clean = 'uploads/property/$clean';
    }

    return '$baseServerUrl/$clean';
  }

  String _getFullImageUrl(String? imagePath) => formatPropertyImageUrl(imagePath);
}
