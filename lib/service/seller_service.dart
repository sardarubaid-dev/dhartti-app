import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SellerService {
  final String baseUrl = 'http://192.168.100.10:8001/api';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final rawUserId = prefs.get('userId');
    final userId = rawUserId?.toString();

    final headers = {
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (userId != null && userId.isNotEmpty) {
      headers['X-User-Id'] = userId;
    }
    return headers;
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUserId = prefs.get('userId');
    return rawUserId?.toString();
  }

  // 1. Dashboard Stats
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    try {
      final headers = await _getHeaders();
      final userId = await _getUserId();
      final response = await http.get(
        Uri.parse('$baseUrl/seller/dashboard-stats?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      return {};
    } catch (e) {
      print('Error fetching seller stats: $e');
      return {};
    }
  }

  // 2. Inquiries / Leads
  Future<List<dynamic>> fetchInquiries() async {
    try {
      final headers = await _getHeaders();
      final userId = await _getUserId();
      final response = await http.get(
        Uri.parse('$baseUrl/seller/inquiries?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching inquiries: $e');
      return [];
    }
  }

  // 3. Property Reviews
  Future<List<dynamic>> fetchReviews() async {
    try {
      final headers = await _getHeaders();
      final userId = await _getUserId();
      final response = await http.get(
        Uri.parse('$baseUrl/seller/reviews?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching seller reviews: $e');
      return [];
    }
  }

  // 4. Store Products (Seller)
  Future<List<dynamic>> fetchStoreProducts() async {
    try {
      final headers = await _getHeaders();
      final userId = await _getUserId();
      final response = await http.get(
        Uri.parse('$baseUrl/seller/store/products?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching seller store products: $e');
      return [];
    }
  }

  // 5. Create Store Product
  Future<Map<String, dynamic>> createStoreProduct({
    required String name,
    required int categoryId,
    required double price,
    required int stockQuantity,
    String? description,
    File? imageFile,
  }) async {
    try {
      final userId = await _getUserId();
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/seller/store/products'));

      final headers = await _getHeaders();
      request.headers.addAll(headers);

      request.fields['name'] = name;
      request.fields['category_id'] = categoryId.toString();
      request.fields['price'] = price.toString();
      request.fields['stock_quantity'] = stockQuantity.toString();
      if (description != null) request.fields['description'] = description;
      if (userId != null) request.fields['user_id'] = userId;

      if (imageFile != null && await imageFile.exists()) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Product created successfully'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to create product'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 6. Update Store Product
  Future<Map<String, dynamic>> updateStoreProduct({
    required int id,
    required String name,
    required int categoryId,
    required double price,
    required int stockQuantity,
    String? description,
    File? imageFile,
  }) async {
    try {
      final userId = await _getUserId();
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/seller/store/products/$id'));

      final headers = await _getHeaders();
      request.headers.addAll(headers);

      request.fields['name'] = name;
      request.fields['category_id'] = categoryId.toString();
      request.fields['price'] = price.toString();
      request.fields['stock_quantity'] = stockQuantity.toString();
      if (description != null) request.fields['description'] = description;
      if (userId != null) request.fields['user_id'] = userId;

      if (imageFile != null && await imageFile.exists()) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Product updated successfully'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update product'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 7. Delete Store Product
  Future<bool> deleteStoreProduct(int id) async {
    try {
      final headers = await _getHeaders();
      final userId = await _getUserId();
      final response = await http.delete(
        Uri.parse('$baseUrl/seller/store/products/$id?user_id=$userId'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting store product: $e');
      return false;
    }
  }

  // 8. Store Orders (Customer orders received on seller's products)
  Future<List<dynamic>> fetchStoreOrders() async {
    try {
      final headers = await _getHeaders();
      final userId = await _getUserId();
      final response = await http.get(
        Uri.parse('$baseUrl/seller/store/orders?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching store orders: $e');
      return [];
    }
  }

  // 9. Update Store Order Status
  Future<Map<String, dynamic>> updateStoreOrderStatus(int orderId, String status) async {
    try {
      final headers = await _getHeaders();
      headers['Content-Type'] = 'application/json';
      final userId = await _getUserId();

      final response = await http.post(
        Uri.parse('$baseUrl/seller/store/orders/$orderId/status'),
        headers: headers,
        body: jsonEncode({
          'status': status,
          'user_id': userId,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Order status updated'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update status'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 10. Update Project Bid Status (Accept / Reject Bid)
  Future<Map<String, dynamic>> updateProjectBidStatus(int bidId, String status, {String? ownerReply}) async {
    try {
      final headers = await _getHeaders();
      headers['Content-Type'] = 'application/json';
      final userId = await _getUserId();

      final response = await http.post(
        Uri.parse('$baseUrl/seller/project-bid/$bidId/status'),
        headers: headers,
        body: jsonEncode({
          'status': status,
          'owner_reply': ownerReply,
          'user_id': userId,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Bid updated successfully'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update bid'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 11. Update Venture Bid Status (Accept / Reject Bid)
  Future<Map<String, dynamic>> updateVentureBidStatus(int bidId, String status, {String? ownerReply}) async {
    try {
      final headers = await _getHeaders();
      headers['Content-Type'] = 'application/json';
      final userId = await _getUserId();

      final response = await http.post(
        Uri.parse('$baseUrl/seller/venture-bid/$bidId/status'),
        headers: headers,
        body: jsonEncode({
          'status': status,
          'owner_reply': ownerReply,
          'user_id': userId,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Venture bid updated successfully'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update bid'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 12. Delete Property
  Future<bool> deleteProperty(int propertyId) async {
    try {
      final headers = await _getHeaders();
      final userId = await _getUserId();
      var response = await http.delete(
        Uri.parse('$baseUrl/seller/properties/$propertyId?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }

      // Fallback endpoint
      response = await http.delete(
        Uri.parse('$baseUrl/properties/$propertyId?user_id=$userId'),
        headers: headers,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting property: $e');
      return false;
    }
  }

  // 13. Delete Project
  Future<bool> deleteProject(int projectId) async {
    try {
      final headers = await _getHeaders();
      final userId = await _getUserId();
      final response = await http.delete(
        Uri.parse('$baseUrl/seller/projects/$projectId?user_id=$userId'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting project: $e');
      return false;
    }
  }

  // 14. Fetch My Bids (Tracking for user)
  Future<Map<String, dynamic>> fetchMyBids() async {
    try {
      final headers = await _getHeaders();
      final userId = await _getUserId();
      final response = await http.get(
        Uri.parse('$baseUrl/seller/my-bids?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as Map<String, dynamic>?) ?? {'venture_bids': [], 'project_bids': []};
      }
      return {'venture_bids': [], 'project_bids': []};
    } catch (e) {
      print('Error fetching my bids: $e');
      return {'venture_bids': [], 'project_bids': []};
    }
  }
}
