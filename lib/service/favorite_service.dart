import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static const String _favPropertiesKey = 'saved_favorite_properties';
  static const String _savedSearchesKey = 'saved_user_searches';

  // Singleton instance
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  /// Check if a property is favorited
  Future<bool> isPropertyFavorite(dynamic propertyId) async {
    final list = await getFavoriteProperties();
    return list.any((p) => p['id']?.toString() == propertyId?.toString());
  }

  /// Toggle property favorite status
  Future<bool> togglePropertyFavorite(Map<String, dynamic> property) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getFavoriteProperties();
    final id = property['id']?.toString();

    final existingIndex = list.indexWhere((p) => p['id']?.toString() == id);
    bool isNowFavorited = false;

    if (existingIndex >= 0) {
      list.removeAt(existingIndex);
      isNowFavorited = false;
    } else {
      // Store clean serializable map
      list.insert(0, {
        'id': property['id'],
        'title': property['title'] ?? 'Property',
        'city': property['city'] ?? '',
        'location': property['plot_number'] ?? property['sub_property_type'] ?? property['city'] ?? '',
        'price': property['price']?.toString() ?? '0',
        'area_size': property['area_size']?.toString() ?? '',
        'area_unit': property['area_unit']?.toString() ?? '',
        'bedrooms': property['bedrooms'],
        'bathrooms': property['bathrooms'],
        'property_type': property['property_type'] ?? 'plots',
        'purpose': property['purpose'] ?? 'sell',
        'image_path': property['image_path'] ?? property['image'] ?? '',
        'saved_at': DateTime.now().toIso8601String(),
      });
      isNowFavorited = true;
    }

    await prefs.setString(_favPropertiesKey, jsonEncode(list));
    return isNowFavorited;
  }

  /// Retrieve all favorite properties
  Future<List<Map<String, dynamic>>> getFavoriteProperties() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favPropertiesKey);
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(
          decoded.map((item) => Map<String, dynamic>.from(item)),
        );
      }
    } catch (_) {}
    return [];
  }

  /// Remove single property from favorites
  Future<void> removeFavoriteProperty(dynamic propertyId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getFavoriteProperties();
    list.removeWhere((p) => p['id']?.toString() == propertyId?.toString());
    await prefs.setString(_favPropertiesKey, jsonEncode(list));
  }

  /// Clear all favorites
  Future<void> clearAllFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favPropertiesKey);
  }

  // ==========================================
  // SAVED SEARCHES
  // ==========================================

  /// Save a search query / filters
  Future<Map<String, dynamic>> saveSearch({
    required String title,
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
    final prefs = await SharedPreferences.getInstance();
    final searches = await getSavedSearches();

    // Prevent duplicate searches with exact same title
    final cleanTitle = title.trim().isEmpty ? 'Custom Search' : title.trim();
    searches.removeWhere((s) => (s['title'] ?? '').toString().toLowerCase().trim() == cleanTitle.toLowerCase());

    final newSearch = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': cleanTitle,
      'city': city ?? 'All Cities',
      'purpose': purpose ?? 'All',
      'property_type': propertyType ?? 'All Types',
      'beds': beds,
      'baths': baths,
      'min_price': minPrice,
      'max_price': maxPrice,
      'min_area': minArea,
      'max_area': maxArea,
      'keyword': keyword,
      'created_at': DateTime.now().toIso8601String(),
    };

    searches.insert(0, newSearch);
    await prefs.setString(_savedSearchesKey, jsonEncode(searches));
    return newSearch;
  }

  /// Retrieve all saved searches
  Future<List<Map<String, dynamic>>> getSavedSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedSearchesKey);
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(
          decoded.map((item) => Map<String, dynamic>.from(item)),
        );
      }
    } catch (_) {}
    return [];
  }

  /// Check if a similar search is already saved
  Future<bool> isSearchSaved({
    String? city,
    String? purpose,
    String? propertyType,
    String? keyword,
  }) async {
    final searches = await getSavedSearches();
    return searches.any((s) {
      final matchCity = (s['city'] ?? 'All Cities') == (city ?? 'All Cities');
      final matchPurpose = (s['purpose'] ?? 'All') == (purpose ?? 'All');
      final matchType = (s['property_type'] ?? 'All Types') == (propertyType ?? 'All Types');
      final matchKeyword = (s['keyword'] ?? '') == (keyword ?? '');
      return matchCity && matchPurpose && matchType && matchKeyword;
    });
  }

  /// Delete saved search
  Future<void> removeSavedSearch(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = await getSavedSearches();
    searches.removeWhere((s) => s['id']?.toString() == id.toString());
    await prefs.setString(_savedSearchesKey, jsonEncode(searches));
  }

  /// Clear all saved searches
  Future<void> clearAllSavedSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedSearchesKey);
  }
}
