import 'dart:convert';
import 'package:dhartti/Model/area_guide_propertyModel.dart';
import 'package:http/http.dart' as http;

class PropertyIndexService {
  final String baseUrl;
  final String imageUrl; // You need to pass this URL for image base path

  // Constructor accepts the base URL and the image URL
  PropertyIndexService({required this.baseUrl, required this.imageUrl});

  Future<Map<String, dynamic>> getPropertyIndexData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/property-index'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Debug print to check API response
        print('API Response: $data');

        // Handle null values and ensure proper typing
        final properties = (data['properties'] as List? ?? [])
            .map((item) => PropertyAreaGuide.fromJson(item))
            .toList();

        final featuredProperties = (data['featuredProperties'] as List? ?? [])
            .map((item) => PropertyAreaGuide.fromJson(item))
            .toList();

        final cities = (data['cities'] as List? ?? []).cast<String>();
        final purposes = (data['purposes'] as List? ?? []).cast<String>();
        final propertyType = (data['property_type'] as List? ?? []).cast<String>();
        final areaSize = (data['area_size'] as List? ?? []).cast<String>();

        // Update image URLs for all properties
        _updateImageUrls(properties);
        _updateImageUrls(featuredProperties);

        return {
          'properties': properties,
          'featuredProperties': featuredProperties,
          'cities': cities,
          'purposes': purposes,
          'area_size': areaSize,
          'property_type': propertyType,
          'trending_cities': data['trending_cities'] ?? [],
          'top_locations': data['top_locations'] ?? [],
        };
      } else {
        throw Exception('Failed to load area guide data. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getPropertyIndexData: $e');
      throw Exception('Failed to load area guide data: $e');
    }
  }

  Future<List<PropertyAreaGuide>> searchProperties({
    String? city,
    String? purpose,
    String? propertyType,
    String? areaSize,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (city != null && city != 'all') queryParams['city'] = city;
      if (purpose != null && purpose != 'all') queryParams['purpose'] = purpose;
      if (propertyType != null && propertyType != 'all') queryParams['property_type'] = propertyType;
      if (areaSize != null && areaSize != 'all') queryParams['area_size'] = areaSize;

      final uri = Uri.parse('$baseUrl/area-guide/search').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<PropertyAreaGuide> properties = (data['properties'] as List)
            .map((item) => PropertyAreaGuide.fromJson(item))
            .toList();

        // Update image URLs for the search results
        _updateImageUrls(properties);

        return properties;
      } else {
        throw Exception('Failed to search properties. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in searchProperties: $e');
      throw Exception('Failed to search properties: $e');
    }
  }

  // Method to update image URLs for all properties in the list
  void _updateImageUrls(List<PropertyAreaGuide> properties) {
    for (var property in properties) {
      // Update image paths for all image keys (you can adjust keys as needed)
      property.imagePath = _getFullImageUrl(property.imagePath);
    }
  }

  // Helper method to construct the full image URL
  String _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return ''; // Return empty string if no image path is provided
    }
    return '$imageUrl/uploads/property/$imagePath';
  }
}